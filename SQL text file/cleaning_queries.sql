-- ============================================================
-- 1. DATABASE & TABLE SETUP
-- ============================================================


create database inventory_analysis;
use inventory_analysis;


CREATE TABLE amazon_sales (
    row_index INT,
    order_ID VARCHAR(225),
    order_date DATE,
    Status VARCHAR(225),
    Fulfilment VARCHAR(225),
    sales_channel VARCHAR(225),
    ship_service_level VARCHAR(225),
    style VARCHAR(225),
    sku VARCHAR(225),
    category VARCHAR(225),
    size VARCHAR(225),
    asin VARCHAR(225),
    courier_status VARCHAR(225),
    qty INT,
    currency VARCHAR(225),
    amount DECIMAL(10 , 2 ),
    ship_city VARCHAR(225),
    ship_state VARCHAR(225),
    ship_postal_code VARCHAR(225),
    ship_country VARCHAR(225),
    b2b BOOLEAN,
    fulfilled_by VARCHAR(225)
);
 
 
 CREATE TABLE inventory (
    row_index INT,
    sku_code VARCHAR(225),
    design_no VARCHAR(225),
    stock INT,
    category VARCHAR(225),
    size VARCHAR(225),
    color VARCHAR(225)
);

-- ============================================================================
-- 2. DATA LOADING
-- ============================================================================

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Amazon Sale Report 4.1.csv' 
into table amazon_sales 
fields terminated by ','
enclosed by '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(row_index, order_ID, order_date, Status, Fulfilment, sales_channel,
 ship_service_level, style, sku, category, size, asin, courier_status,
 qty, currency, @amount_raw, ship_city, ship_state, ship_postal_code, ship_country,
 @b2b_raw, fulfilled_by)
SET 
    amount = NULLIF(@amount_raw, ''),
    b2b = IF(@b2b_raw = 'TRUE', 1, 0);

-- ============================================================
-- 3. BACKUP & INITIAL VALIDATION
-- ============================================================

create table amazon_backup 
like amazon_sales;



INSERT INTO amazon_backup
SELECT *
FROM amazon_sales;

select * from amazon_sales limit 6;
select * from inventory limit 6;

set SQL_SAFE_UPDATES = 0;

-- ============================================================
-- 4. BASIC WHITESPACE CLEANING
-- ============================================================

UPDATE amazon_sales 
SET 
    order_id = TRIM(order_id),
    Status = TRIM(Status),
    Fulfilment = TRIM(Fulfilment),
    sales_channel = TRIM(sales_channel),
    ship_service_level = TRIM(ship_service_level),
    style = TRIM(style),
    sku = TRIM(sku),
    category = TRIM(category),
    size = TRIM(size),
    asin = TRIM(asin),
    courier_status = TRIM(courier_status),
    currency = TRIM(currency),
    ship_city = TRIM(ship_city),
    ship_state = TRIM(ship_state),
    ship_country = TRIM(ship_country),
    fulfilled_by = TRIM(fulfilled_by);

-- Basic checks after import/trim
select * from amazon_sales where order_date is null;
select * from inventory where stock is null;

SELECT
    COUNT(*) AS total_rows,
    SUM(order_id IS NULL OR order_id = '') AS order_id_missing,
    SUM(order_date IS NULL) AS order_date_missing,
    SUM(status IS NULL OR status = '') AS status_missing,
    SUM(fulfilment IS NULL OR fulfilment = '') AS fulfilment_missing,
    SUM(sales_channel IS NULL OR sales_channel = '') AS sales_channel_missing,
    SUM(ship_service_level IS NULL OR ship_service_level = '') AS ship_service_level_missing,
    SUM(style IS NULL OR style = '') AS style_missing,
    SUM(sku IS NULL OR sku = '') AS sku_missing,
    SUM(category IS NULL OR category = '') AS category_missing,
    SUM(size IS NULL OR size = '') AS size_missing,
    SUM(asin IS NULL OR asin = '') AS asin_missing,
    SUM(courier_status IS NULL OR courier_status = '') AS courier_status_missing,
    SUM(qty IS NULL) AS qty_missing,
    SUM(currency IS NULL OR currency = '') AS currency_missing,
    SUM(amount IS NULL) AS amount_missing,
    SUM(ship_city IS NULL OR ship_city = '') AS ship_city_missing,
    SUM(ship_state IS NULL OR ship_state = '') AS ship_state_missing,
    SUM(ship_postal_code IS NULL) AS ship_postal_code_missing,
    SUM(ship_country IS NULL OR ship_country = '') AS ship_country_missing,
    SUM(b2b IS NULL) AS b2b_missing,
    SUM(fulfilled_by IS NULL OR fulfilled_by = '') AS fulfilled_by_missing
FROM amazon_sales;

-- ============================================================
-- 5. STATE STANDARDIZATION
-- ============================================================

-- Explore state distribution
SELECT 
    ship_state, COUNT(*) AS total_orders
FROM
    amazon_sales
GROUP BY ship_state
ORDER BY total_orders DESC;

UPDATE amazon_sales 
SET 
    ship_state = CASE
        WHEN ship_state = 'New Delhi' THEN 'Delhi'
        WHEN ship_state IN ('Rajshthan' , 'Rj','Rajsthan') THEN 'Rajasthan'
        WHEN ship_state = 'Nl' THEN 'Nagaland'
        WHEN ship_state = 'Orissa' THEN 'Odisha'
        WHEN ship_state IN ('Punjab/Mohali/Zirakpur' , 'Pb') THEN 'Punjab'
        WHEN ship_state = 'Ar' THEN 'Arunachal Pradesh'
        WHEN ship_state = 'Pondicherry' THEN 'Puducherry'
        else ship_state
    END;

-- APO location could not be reliably mapped to a state
SELECT 
    *
FROM
    amazon_sales
WHERE
    ship_city = 'Apo';

update amazon_sales
set ship_state = "unknown"
where  ship_city = 'Apo';

-- ============================================================
-- 6. CITY STANDARDIZATION
-- ============================================================

SELECT 
    ship_city, COUNT(*) AS total_orders
FROM
    amazon_sales
GROUP BY ship_city
ORDER BY ship_city;

SELECT 
    *
FROM
    amazon_sales
WHERE
    ship_city IS NULL OR ship_city = '';
   
SELECT DISTINCT
    ship_city
FROM
    amazon_sales
WHERE
    ship_city REGEXP 'b.*n.*g.*l.*r'; 

SELECT DISTINCT
    ship_city, COUNT(*) AS count
FROM
    amazon_sales
WHERE
    ship_city REGEXP 'gur.*g'
GROUP BY ship_city
HAVING count > 1;
select * from amazon_sales where ship_city = "apo";
update amazon_sales 
set ship_city = case
	when ship_city in ('Delhi','N.Delhi','New Delhidelhi','Newdelhi','Delhiq') then 'New delhi'
    when ship_city in ('Bangalore','Banglore','Bengalur','Bengaluru.','Bengalure') then 'Bengaluru'
    when ship_city in ('Mumbaimumbai','Mumba','Mumbra','Mmbai','Mumbai.''Mumb') then 'Mumbai'
    when ship_city in ('Hyderabad,','Hyderbad','Hyderaba','Hyderabad.','Hyderaba') then 'Hyderabad'
    when ship_city = 'Calcutta' then 'Kolkata'
    when ship_city in ('Chennai.','Chennnai','Chennaichennai') then 'Chennai'
    when ship_city in ('Pondycherry','Pondicherry') then 'Puducherry'
    when ship_city in ('Allahabad','Allahabad Prayagraj') then 'Prayagraj'
    when ship_city in ('Gurugramgurgaon','Gurgaon','Gurugram.''Gurugaon') then 'Gurugram'
    when ship_city = 'Apo' then 'unknown'
    else ship_city
    end
    where ship_city in (
    'Delhi','N.Delhi','New Delhidelhi','Newdelhi','Delhiq',
    'Bangalore','Banglore','Bengalur','Bengaluru.','Bengalure',
    'Mumbaimumbai','Mumba','Mumbra','Mmbai','Mumbai.''Mumb',
    'Hyderabad,','Hyderbad','Hyderaba','Hyderabad.','Hyderaba',
    'Calcutta',
    'Chennai.','Chennnai','Chennaichennai'
    'Pondycherry','Pondicherry',
    'Allahabad','Allahabad Prayagraj','Apo'
    'Gurugramgurgaon','Gurgaon','Gurugram.''Gurugaon'
    );

-- Validate city cleaning
SELECT 
    ship_city, COUNT(*) AS total_orders
FROM
    amazon_sales
GROUP BY ship_city
ORDER BY total_orders DESC;

-- ============================================================
-- 7. FULFILLED_BY CLEANING
-- ============================================================
 SELECT fulfilled_by, COUNT(*) AS total_orders
FROM amazon_sales
GROUP BY fulfilled_by;

-- Investigate suspicious short / hidden-character values

SELECT
    fulfilled_by,
    LENGTH(fulfilled_by) AS len,
    COUNT(*) AS total
FROM amazon_sales
GROUP BY fulfilled_by, LENGTH(fulfilled_by);

SELECT
    fulfilled_by,
    HEX(fulfilled_by) AS hex_value,
    LENGTH(fulfilled_by) AS len,
    COUNT(*) AS total
FROM amazon_sales
GROUP BY fulfilled_by, HEX(fulfilled_by), LENGTH(fulfilled_by);

SELECT fulfilment, COUNT(*)
FROM amazon_sales
WHERE HEX(fulfilled_by) = '0D'
GROUP BY fulfilment;


-- Clean carriage-return value

SELECT fulfilment,
       fulfilled_by,
       COUNT(*) AS total_orders
FROM amazon_sales
GROUP BY fulfilment, fulfilled_by
ORDER BY fulfilment, fulfilled_by;

UPDATE amazon_sales
SET fulfilled_by = 'Amazon Fulfilled'
WHERE HEX(fulfilled_by) = '0D';

-- ============================================================
-- 8. CURRENCY & COURIER STATUS CLEANING
-- ============================================================

SELECT 
    currency, COUNT(*)
FROM
    amazon_sales
GROUP BY currency;


UPDATE amazon_sales 
SET 
    currency = 'INR'
WHERE
    currency = '';


SELECT 
    courier_status, COUNT(*)
FROM
    amazon_sales
GROUP BY courier_status;


UPDATE amazon_sales 
SET 
    courier_status = 'unknown'
WHERE
    courier_status = '';

-- ============================================================
-- 9. POSTAL CODE INVESTIGATION
-- ============================================================
SELECT 
    *
FROM
    amazon_sales
WHERE
    ship_postal_code IS NULL
        OR ship_postal_code = '';
        
        
SELECT 
    *
FROM
    amazon_sales
WHERE
    LENGTH(ship_postal_code) <> 6;


SELECT 
    *
FROM
    amazon_sales
WHERE
    ship_postal_code < 100000
        OR ship_postal_code > 999999;


-- ============================================================
-- 10. DUPLICATE SALES RECORD INVESTIGATION
-- ============================================================
-- identify repeated order/SKU combinations
SELECT order_id, sku, COUNT(*) 
FROM amazon_sales
GROUP BY order_id, sku
HAVING COUNT(*) > 1;

-- Identify fully duplicated records using all business columns
with cte as (

select *,
	row_number() over(
	partition by  
		order_ID,
		order_date,
		Status,
		Fulfilment,
		sales_channel,
		ship_service_level,
		style,
		sku,
		category,
		size,
		asin,
		courier_status,
		qty,
		currency,
		amount,
		ship_city,
		ship_state,
		ship_postal_code,
		ship_country,
		b2b,
		fulfilled_by
	) as dupicates
from amazon_sales)
    
select * 
from cte 
where dupicates > 1;
    
-- Confirmed duplicate rows removed after investigation

DELETE FROM amazon_sales 
WHERE
    row_index IN ('85790' , '79845',
    '86419',
    '30661',
    '98954',
    '41292');

-- ============================================================
-- 11. ZERO-AMOUNT / PRICE INVESTIGATION
-- ============================================================
-- Check zero-amount rows by Status

SELECT 
    status, COUNT(*)
FROM
    amazon_sales
WHERE
    currency IS NULL OR currency = ''
GROUP BY status;
-- Check zero-amount rows among completed/shipped status

SELECT 
    *
FROM
    amazon_sales
WHERE
    amount IS NOT NULL
        AND Status IN ('Shipped - Delivered to Buyer' , 'Shipped',
        'Shipped - Out for Delivery',
        'Shipped - Picked Up',
        'Shipping')
        AND courier_status = 'shipped'
        AND amount = 0;

-- Count zero-amount orders by SKU

	SELECT
    sku,
    COUNT(*) AS zero_amount_orders
FROM amazon_sales
WHERE
    amount IS NOT NULL
        AND Status IN ('Shipped - Delivered to Buyer' , 'Shipped',
        'Shipped - Out for Delivery',
        'Shipped - Picked Up',
        'Shipping')
        AND courier_status = 'shipped'
        AND amount = 0
GROUP BY sku
ORDER BY zero_amount_orders DESC;

-- ============================================================
-- 12. SKU-LEVEL PRICE IMPUTATION
-- ============================================================
-- Calculate average valid price for each SKU
SELECT
    sku,
    ROUND(AVG(amount), 2) AS avg_amount
FROM amazon_sales
WHERE Status IN (
    'Shipped - Delivered to Buyer',
    'Shipped',
    'Shipped - Out for Delivery',
    'Shipped - Picked Up',
    'Shipping'
)
AND courier_status = 'shipped'
AND amount > 0
GROUP BY sku;

-- Apply SKU-level average to eligible zero-amount orders

update amazon_sales a
join (SELECT
    sku,
    ROUND(AVG(amount), 2) AS avg_amount
FROM amazon_sales
WHERE Status IN (
    'Shipped - Delivered to Buyer',
    'Shipped',
    'Shipped - Out for Delivery',
    'Shipped - Picked Up',
    'Shipping'
)
AND courier_status = 'shipped'
AND amount > 0
GROUP BY sku
) avg_a
on a.sku = avg_a.sku
set amount = avg_amount
where a.amount = 0 and Status IN (
	'Shipped - Delivered to Buyer',
	'Shipped',
	'Shipped - Out for Delivery',
	'Shipped - Picked Up',
	'Shipping'
)
AND courier_status = 'shipped';

-- ============================================================
-- 13. STYLE-LEVEL FALLBACK PRICE IMPUTATION
-- ============================================================
-- Calculate average valid price for each STYLE
SELECT 
    style, ROUND(AVG(amount), 2) avg_amount
FROM
    amazon_sales
WHERE
    Status IN ('Shipped - Delivered to Buyer' , 'Shipped',
        'Shipped - Out for Delivery',
        'Shipped - Picked Up',
        'Shipping')
        AND courier_status = 'shipped'
GROUP BY style;

-- Use style-level average where a zero amount remains

update amazon_sales a
join (SELECT 
    style, ROUND(AVG(amount), 2) avg_amount
FROM
    amazon_sales
WHERE
    Status IN ('Shipped - Delivered to Buyer' , 'Shipped',
        'Shipped - Out for Delivery',
        'Shipped - Picked Up',
        'Shipping')
        AND courier_status = 'shipped'
GROUP BY style) avg_a
on a.style = avg_a.style
set amount = avg_amount
where a.amount = 0 and Status IN ('Shipped - Delivered to Buyer' , 'Shipped',
        'Shipped - Out for Delivery',
        'Shipped - Picked Up',
        'Shipping')
        AND courier_status = 'shipped';

-- Final validation: eligible shipped zero-amount rows should be 0

SELECT COUNT(*) AS remaining_zero_amount
FROM amazon_sales
WHERE amount = 0
  AND Status IN (
      'Shipped - Delivered to Buyer',
      'Shipped',
      'Shipped - Out for Delivery',
      'Shipped - Picked Up',
      'Shipping'
  )
  AND courier_status = 'shipped';

-- ============================================================
-- 14. INVENTORY DATA QUALITY CHECKS
-- ============================================================

SELECT 
    SUM(sku_code IS NULL OR sku_code = '') AS sku_missing,
    SUM(design_no IS NULL OR design_no = '') AS design_missing,
    SUM(category IS NULL OR category = '') AS category_missing,
    SUM(size IS NULL OR size = '') AS size_missing,
    SUM(color IS NULL OR color = '') AS color_missing
FROM
    inventory;

SELECT 
    sku_code, COUNT(*) AS cnt
FROM
    inventory
GROUP BY sku_code
HAVING COUNT(*) > 1;

-- Investigate blank category/SKU records
SELECT 
    *
FROM
    inventory
WHERE
    category = '';

SELECT
    category,
    size,
    COUNT(*)
FROM inventory
WHERE sku_code = ''
GROUP BY category, size;

-- ============================================================
-- 15. INVENTORY COLOR CLEANING
-- ============================================================
-- Identifying null vales 

SELECT COUNT(*)
FROM inventory
WHERE color is null;

SELECT
    color,
    LENGTH(color) AS len,
    HEX(color) AS hex_value
FROM inventory
WHERE row_index = '901';

SELECT *
FROM inventory
WHERE HEX(color) = '0D';

UPDATE inventory
SET color = NULL
WHERE HEX(color) = '0D';

-- ============================================================
-- 16. REMOVE FULLY-JUNK INVENTORY ROWS
-- ============================================================
SELECT 
    category, size, COUNT(*)
FROM
    inventory
WHERE
    sku_code = ''
GROUP BY category , size;


DELETE FROM inventory 
WHERE
    (sku_code = '') AND (category = '')
    AND (color IS NULL);

-- ============================================================
-- 17. REPAIR INVALID INVENTORY SKU CODES
-- ============================================================

-- Investigate #REF! rows and nearby surviving records

SELECT
    i1.row_index AS ref_row_index,
    i1.sku_code AS ref_sku_code,
    i1.design_no AS ref_design_no,
    i1.stock AS ref_stock,
    i1.category AS ref_category,
    i1.size AS ref_size,
    i1.color AS ref_color,
    i2.sku_code AS above_sku_code,
    i2.design_no AS above_design_no,
    i2.stock AS above_stock,
    i2.category AS above_category,
    i2.size AS above_size,
    i2.color AS above_color
FROM inventory i1
JOIN inventory i2
    ON i1.row_index = i2.row_index + 1
WHERE i1.sku_code = '#REF!'
ORDER BY i1.row_index;

-- Investigate blank SKU rows and nearby records

SELECT
    i1.row_index AS ref_row_index,
    i1.sku_code AS ref_sku_code,
    i2.sku_code AS below_sku_code,
    i2.design_no AS below_design_no,
    i1.design_no AS ref_design_no,
    i1.stock AS ref_stock,
    i1.category AS ref_category,
    i1.size AS ref_size,
    i1.color AS ref_color
FROM inventory i1
JOIN inventory i2
    ON i1.row_index = i2.row_index - 1
WHERE i1.sku_code = '';

-- Remove rows that contained unrecoverable #REF! SKU values

delete from	inventory 
where sku_code = '#REF!';

-- Reconstruct missing SKU codes from surviving inventory fields

update inventory
set sku_code = case 
when category = 'BLOUSE' and size = 'FREE' then concat(design_no,"-",upper(color))
when category = 'BLOUSE' and size = 'XXXL' then concat(design_no,"-",upper(size))
when category ='AN : LEGGINGS' and size = 'FREE' then concat(design_no,"-",upper(color))
when category ='CARDIGAN' and size = 'XXXL' then concat(design_no,"-",upper(size))
when category ='KURTA' and size <>'FREE' then concat(design_no,"-","KR","-",upper(size))
when category ='KURTA' and size = 'FREE' then concat(design_no,"-","KR","-",upper(color))
when category ='KURTA SET' and size <>'FREE' and design_no like 'SET2%' then concat(design_no,"-","KR","-","PP","-",upper(size))
when category ='KURTA SET' and size <>'FREE' and design_no like 'SET0%' then concat(design_no,"-","KR","-","NP","-",upper(size))
when category ='SET' and size <>'FREE' and design_no like 'PSET%' then concat(design_no,"-","KR","-","NP","-",upper(size))
when category ='TOP' and size ='FREE' then concat(design_no,"-","TP","-",upper(color))
when category ='TOP' and size <>'FREE' then concat(design_no,"-","TP","-",upper(size))
else sku_code end where sku_code = '';

-- ============================================================
-- 18. INVENTORY DUPLICATE SKU INVESTIGATION
-- ============================================================

SELECT 
    sku_code, COUNT(*) AS cnt
FROM
    inventory
GROUP BY sku_code
HAVING COUNT(*) > 1;

SELECT 
    *
FROM
    inventory
WHERE
    design_no = 'JNE3404';
    
-- These four inventory records were identified as duplicate records.
-- Their design_no values corresponded to JNE3404/JNE3405, while the
-- corresponding non-P-prefixed records had the same remaining inventory
-- attributes. The only SKU difference was the leading 'P' in the SKU code.
-- No other inventory records with the PJNE340x SKU pattern were identified,
-- so these records were treated as duplicate entries rather than separate
-- products and removed to maintain a unique sku_code for the
-- sales-inventory relationship.

SELECT * FROM inventory 
WHERE sku_code IN (
	'PJNE3404-KR-4XL',
    'PJNE3404-KR-5XL',
    'PJNE3405-KR-5XL',
    'PJNE3405-KR-6XL'
);

delete from inventory 
WHERE sku_code IN (
	'PJNE3404-KR-4XL',
    'PJNE3404-KR-5XL',
    'PJNE3405-KR-5XL',
    'PJNE3405-KR-6XL'
);

-- ============================================================
-- 19. FINAL INVENTORY VALIDATION
-- ============================================================

SELECT 
    sku_code, COUNT(*) AS cnt
FROM
    inventory
GROUP BY sku_code
HAVING COUNT(*) > 1;


SELECT 
    COUNT(*) AS inventory_rows
FROM
    inventory;


-- ============================================================
-- 20. FINAL SALES ↔ INVENTORY SKU VALIDATION
-- ============================================================

-- SKUs present in sales but missing from inventory
SELECT 
    COUNT(DISTINCT a.sku) AS sales_skus_not_in_inventory
FROM
    amazon_sales a
        LEFT JOIN
    inventory i ON a.sku = i.sku_code
WHERE
    i.sku_code IS NULL;


-- SKUs present in inventory but missing from sales
SELECT 
    COUNT(DISTINCT i.sku_code) AS inventory_skus_not_in_sales
FROM
    inventory i
        LEFT JOIN
    amazon_sales a ON i.sku_code = a.sku
WHERE
    a.sku IS NULL;

-- ============================================================
-- END OF DATA CLEANING
-- ============================================================
