-- ============================================================
-- Amazon Sales & Inventory Analysis
-- analysis_queries.sql
--
-- Core analytical questions:
--   1. Which products sell the most?
--   2. Which categories generate the most revenue?
--   3. Which products have high demand relative to current stock?
--   4. How does revenue/order volume change by month?
--   5. Which categories have the highest cancellation rates?
--   6. Which states generate the most revenue?
--   7. How concentrated is revenue across SKUs? (Pareto analysis)
--
-- Completed/shipped revenue-based analyses use the same business rule:
--   Valid shipped status + courier_status = 'Shipped'
-- ============================================================

-- 1. top 10 best selling products

SELECT 
    a.sku,
    a.category,
    SUM(a.qty) AS total_unit_sold,
    SUM(a.amount) AS total_sales,
    MAX(i.stock) AS current_stock
FROM
    amazon_sales a
        JOIN
    inventory i ON a.sku = i.sku_code
WHERE
    a.Status IN ('Shipped - Delivered to Buyer' , 'Shipped',
        'Shipped - Out for Delivery',
        'Shipped - Picked Up',
        'Shipping')
        AND a.courier_status = 'Shipped'
GROUP BY a.sku , a.category
ORDER BY total_unit_sold DESC
LIMIT 10;

-- 2. total revenue by category

SELECT 
    category, SUM(amount) total_revenue,sum(qty) unit_sold,
    count(*) AS num_orders,
    ROUND(avg(amount), 2) AS avg_order_value
FROM
    amazon_sales
WHERE
    Status IN ('Shipped - Delivered to Buyer' , 'Shipped',
        'Shipped - Out for Delivery',
        'Shipped - Picked Up',
        'Shipping')
        AND courier_status = 'Shipped'
GROUP BY category;

-- 3. low stock / high demand (Stock Priority)

SELECT 
    a.category,
    a.sku,
    SUM(qty) unit_sold,
    MAX(i.stock) current_stock,
    ROUND(MAX(i.stock) / SUM(qty), 2) stock_to_qty_ratio
FROM
    amazon_sales a
        JOIN
    inventory i ON a.sku = i.sku_code
WHERE
    a.Status IN ('Shipped - Delivered to Buyer' , 'Shipped',
        'Shipped - Out for Delivery',
        'Shipped - Picked Up',
        'Shipping')
        AND a.courier_status = 'Shipped'
GROUP BY a.category , a.sku
ORDER BY stock_to_qty_ratio ASC , unit_sold DESC;

-- 4. monthly sales trend 

SELECT 
    YEAR(order_date) as year,
    MONTHNAME(order_date) as month,
    SUM(amount) revenue,
    COUNT(*) num_of_orders
FROM
    amazon_sales
WHERE
    Status IN ('Shipped - Delivered to Buyer' , 'Shipped',
        'Shipped - Out for Delivery',
        'Shipped - Picked Up',
        'Shipping')
        AND courier_status = 'Shipped'
GROUP BY YEAR(order_date) , MONTH(order_date),MONTHNAME(order_date)
ORDER BY MONTH(order_date) ASC;

-- 5. Cancellation Rate by Category

SELECT 
    category,
    COUNT(*) total_orders,
    SUM(CASE
        WHEN status = 'cancelled' THEN 1
        ELSE 0
    END) AS orders_amazon_cancelled,
    SUM(CASE
        WHEN
            courier_status = 'Cancelled'
                AND Status != 'Cancelled'
        THEN
            1
        ELSE 0
    END) AS courier_only_cancelled,
    ROUND(SUM(CASE
                WHEN status = 'cancelled' THEN 1
                ELSE 0
            END) * 100 / COUNT(*),
            2) amazon_cancellation_rate,
            ROUND(SUM(CASE
                WHEN
                    courier_status = 'Cancelled'
                        AND Status != 'Cancelled'
                THEN
                    1
                ELSE 0
            END) * 100 / COUNT(*),
            2) courier_cancellation_rate,
    ROUND(SUM(CASE
                WHEN
                    Status = 'Cancelled'
                        OR courier_status = 'Cancelled'
                THEN
                    1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS total_cancellation_rate
FROM
    amazon_sales
GROUP BY category
ORDER BY total_cancellation_rate DESC;

-- 6. revenue by states 

SELECT 
    ship_state,
    COUNT(*) AS num_orders,
    SUM(amount) AS total_revenue,
    ROUND(AVG(amount), 2) AS avg_order_value
FROM
    amazon_sales
WHERE
    Status IN ('Shipped - Delivered to Buyer' , 'Shipped',
        'Shipped - Out for Delivery',
        'Shipped - Picked Up',
        'Shipping')
        AND courier_status = 'Shipped'
        AND ship_state <> 'unknown'
GROUP BY ship_state
ORDER BY total_revenue DESC;


-- 7. ZERO-STOCK SKU VALIDATION

-- This separates all zero-stock SKUs 

-- 212 = all distinct sales SKUs matched to inventory with stock = 0.

SELECT
    COUNT(DISTINCT a.sku) AS zero_stock_skus
FROM amazon_sales a
JOIN inventory i
    ON a.sku = i.sku_code
WHERE i.stock = 0;

-- 208 = zero-stock SKUs that also have qualifying shipped sales.

SELECT
    COUNT(DISTINCT a.sku) AS zero_stock_skus_with_shipped_sales
FROM amazon_sales a
JOIN inventory i
    ON a.sku = i.sku_code
WHERE i.stock = 0
  AND a.Status IN (
      'Shipped - Delivered to Buyer',
      'Shipped',
      'Shipped - Out for Delivery',
      'Shipped - Picked Up',
      'Shipping'
  )
  AND a.courier_status = 'shipped';


-- Revenue at Risk validation using the same business logic
SELECT
    SUM(a.amount) AS revenue_at_risk
FROM amazon_sales a
JOIN inventory i
    ON a.sku = i.sku_code
WHERE i.stock = 0
  AND a.Status IN (
      'Shipped - Delivered to Buyer',
      'Shipped',
      'Shipped - Out for Delivery',
      'Shipped - Picked Up',
      'Shipping'
  )
  AND a.courier_status = 'shipped';


-- 8. SKUs CONTRIBUTING UP TO 80% OF REVENUE


select * from (select 
	sku, 
    revenue,pct_of_total_revenue,
    sum(pct_of_total_revenue) 
    over (order by revenue desc) as cumilative_percentage
from(SELECT 
    a.sku,
    SUM(a.amount) AS revenue,
    ROUND(SUM(a.amount) * 100.0 / (
        SELECT SUM(amount) FROM amazon_sales 
        WHERE Status IN ('Shipped - Delivered to Buyer', 'Shipped', 'Shipped - Out for Delivery', 'Shipped - Picked Up', 'Shipping')
        AND courier_status = 'shipped'
    ), 2) AS pct_of_total_revenue
FROM amazon_sales a
WHERE a.Status IN ('Shipped - Delivered to Buyer', 'Shipped', 'Shipped - Out for Delivery', 'Shipped - Picked Up', 'Shipping')
    AND a.courier_status = 'shipped'
GROUP BY a.sku
) as product_revenue ORDER BY revenue DESC) as ct where cumilative_percentage <=80;

-- ============================================================
-- END OF ANALYSIS
-- ============================================================
