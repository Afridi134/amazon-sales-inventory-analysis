# Amazon Sales & Inventory Analysis

An end-to-end data analytics project analyzing Amazon India seller sales and inventory data using **Excel, MySQL, Python, and Power BI**.

The project focuses on data cleaning, validation, exploratory analysis, sales performance, and inventory risk.



---

## 📊 Power BI Dashboard

The final Power BI report contains three pages:

1. **Sales Dashboard**
2. **Sales & Product Performance**
3. **Inventory Dashboard**

The dashboard connects directly to the cleaned **MySQL database** and uses DAX measures for KPIs and cross-table inventory/sales analysis.

### Interactive Features

- **Revenue / Units Toggle** — Switch between revenue and units sold to compare performance across categories and products without changing the underlying dashboard layout.
- Interactive slicers for status, month, fulfilment, category, and size.
- Cross-filtering across dashboard visuals.
- Restock-priority view for identifying zero-stock products requiring attention.

### Dashboard Preview

#### Sales Dashboard
![Sales Dashboard](https://github.com/Afridi134/amazon-sales-inventory-analysis/blob/246aee51aef33ce47c960e39e23db3fff1c8dd6a/dashboard%20images/sales%20analysis%20(revenue).png) 

![Sales Dashboard](https://github.com/Afridi134/amazon-sales-inventory-analysis/blob/246aee51aef33ce47c960e39e23db3fff1c8dd6a/dashboard%20images/sales%20analysis%20(Units).png)

#### Sales & Product Performance
![Sales & Product Performance](https://github.com/Afridi134/amazon-sales-inventory-analysis/blob/246aee51aef33ce47c960e39e23db3fff1c8dd6a/dashboard%20images/sales%20%26%20product%20performance.png)

#### Inventory Dashboard
![Inventory Dashboard](https://github.com/Afridi134/amazon-sales-inventory-analysis/blob/246aee51aef33ce47c960e39e23db3fff1c8dd6a/dashboard%20images/inventory%20dashboard.png)

Key dashboard metrics include:

- Total Revenue
- Average Revenue
- Total Orders
- Total Units Sold
- Cancellation Rate
- Total Stock
- Average Stock-to-Sales Ratio
- SKUs at Zero Stock
- Revenue at Risk
- Restock Priority

---

## 🎯 Project Objective

The objective was to transform raw e-commerce sales and inventory data into a reliable analytical dataset and use it to answer practical business questions:

- Which products and categories generate the most revenue?
- How do sales and order volumes change over time?
- Which categories have higher cancellation rates?
- Which states contribute the most revenue?
- Which products have high demand relative to available stock?
- Which SKUs are currently out of stock despite having historical sales?
- Is inventory allocation aligned with actual demand?

---

## 🔄 Project Workflow

```text
Raw Kaggle Dataset
        ↓
Excel — Initial Data Preparation
        ↓
MySQL — Data Cleaning & Validation
        ↓
MySQL — Business Analysis & KPI Validation
        ↓
Python — Exploratory Data Analysis
        ↓
Power BI — Interactive Dashboard
```

### Excel — Initial Preparation

Excel was used for initial preparation of the source files before database import:

- Removing the unwanted `Unnamed: 22` column
- Removing the `promotion-ids` column
- Removing 33 rows with completely missing shipping-location information
- Standardizing the date format from `MM-DD-YY` to `YYYY-MM-DD`
- Standardizing city and state capitalization
- Preparing the inventory file for import

The inventory data was loaded into MySQL using the **MySQL Import Wizard**.

### MySQL — Cleaning & Validation

MySQL was the primary cleaning and transformation layer, following: **Identify → Investigate → Clean → Validate**

- Standardizing column names and text values, trimming whitespace
- Standardizing city and state values (typos, duplicated spellings, formatting variants)
- Standardizing missing currency values to `INR` and missing courier status values
- Consolidating overlapping order-status values into a consistent analysis whitelist
- Cross-validating order `Status` against `courier_status`
- Investigating and removing duplicate sales records
- Investigating and repairing corrupted inventory SKU values (Excel `#REF!` errors)
- Separating unusable blank inventory records from salvageable ones
- Resolving the confirmed `PJNE3404` / `PJNE3405` duplicate SKU collision
- Handling missing/zero sales amounts for qualifying shipped orders using SKU-level average price, with Style-level fallback


### MySQL — Analysis

The cleaned tables were then used for business analysis, using `JOIN`, `CASE WHEN`, aggregations, subqueries, window functions, and ratio calculations to answer:

- Top-selling products
- Revenue by category
- Low-stock / high-demand products (stock-to-sales ratio)
- Monthly sales trends
- Cancellation rates (Amazon-reported vs. courier-reported)
- Revenue by state
- Zero-stock SKU and Revenue-at-Risk validation
- SKUs contributing up to 80% of revenue (Pareto revenue concentration)

### Python — Exploratory Data Analysis

Python (pandas, NumPy, matplotlib, seaborn) was used for exploratory analysis after the main cleaning work was completed in SQL:

- Dataset and data-type checks
- Order amount distributions
- Category-level and size-level demand/stock analysis
- Monthly revenue and order trends, weekday order patterns
- Sales/inventory merging and stock-to-order ratio analysis
- Stock vs. units-sold correlation
- Restock-priority analysis and outlier analysis

### Power BI — Dashboard

Power BI uses the MySQL database directly as its data source, across three pages:

#### 1. Sales Dashboard

Provides an overall view of:

- Revenue
- Orders
- Units sold
- Average revenue
- Cancellation rate
- Sales trends
- Order-status information

#### 2. Sales & Product Performance

Focuses on:

- Product performance
- Category performance
- Revenue contribution
- Geographic performance
- Sales and order patterns

#### 3. Inventory Dashboard

Focuses on:

- Current stock
- Stock-to-sales relationships
- Zero-stock SKUs
- Revenue at Risk
- Restock priorities
- Product-level inventory status
---

## 🧹 Data Cleaning Highlights

This project involved substantial real-world cleaning rather than analyzing an already-clean dataset.

**Sales data** — The original file contained 128,975 rows and 24 columns. After cleaning: 33 completely blank shipping-location records were removed, `promotion-ids` and `Unnamed: 22` were dropped, dates and city/state names were standardized, and order-status/courier-status combinations were investigated to establish a consistent whitelist for revenue analysis.

**Inventory data** — Cleaning included investigating corrupted `#REF!` SKU values, blank/unusable records, and duplicate SKU/design collisions. Where SKU information could be reconstructed from surviving fields (category, design number, size, color), the record was repaired and retained instead of discarding valid stock data. The `PJNE3404`/`PJNE3405` collision was specifically investigated and removed, since the affected rows matched the same underlying design/product information as non-prefixed duplicates.

**Price/amount handling** — Orders with missing or zero amounts were investigated rather than blindly replaced. For qualifying shipped orders needing price information, values were imputed using

1. **SKU-level average price**
2. **Style-level fallback** only where no SKU-level reference existed.

---

## 📈 Key Findings

### 1. Revenue decline was primarily volume-driven
Revenue declined by approximately **20% from April to June 2022**, while order volume declined by approximately **24.5%** (40,927 → 30,906 orders). Average order value remained comparatively stable/increased over the same period, indicating the decline traces to fewer orders rather than lower per-order value.

### 2. Revenue at Risk from zero-stock products
Zero-stock SKUs form a funnel, narrowing at each stage of the completed-sales definition:

| Stage | Count | Definition |
|---|---|---|
| Zero-stock SKUs (inventory-wide) | **557** | All SKUs in the inventory table currently at `stock = 0` |
| ...with any matching sales record | **212** | Of those, the subset that also appears in `amazon_sales` at all |
| ...with *completed* (shipped) sales | **208** | Of those, the subset meeting the project's completed-order definition |

Using the 208 SKUs with proven, completed sales history, the associated historical revenue is:

> **₹12,98,275.84 Revenue at Risk**

### 3. Free-size inventory shows a strong overstock signal
Python EDA found that

- Free-size orders: **320**
- Free-size stock: **7,840**
- Stock-to-order ratio: **24.5**

This is substantially higher than the ratio observed for the core sizes and represents the clearest overstock signal in the size-level analysis.

### 4. Stock levels are only weakly aligned with demand
Correlation between stock levels and units sold came out to **r = 0.30** — a weak positive relationship, indicating inventory allocation is not strongly aligned with actual sales demand.

### 5. Revenue is distributed across a broad SKU base

The final Pareto analysis found that **1,962 of 7,083 revenue-generating SKUs**, or approximately **27.7%**, are required to reach **80% of revenue**.
The 1,962nd SKU brings cumulative revenue to approximately **80.0038%**.
This is less concentrated than a classic 80/20 distribution and indicates that revenue is spread across a relatively broad product catalog.


### 6. Order status required cross-validation to trust

Amazon's own order `Status` and the courier's independently reported `courier_status` disagreed on a meaningful number of orders (e.g. marked "Shipped" but the courier's record showed return or non-dispatch). For completed-order analysis, both `Status` and `courier_status` are cross-validated to avoid counting orders where the two sources indicate conflicting fulfilment outcomes.
---

## 🔎 Revenue at Risk — Definition

The Power BI measure defines Revenue at Risk by:

1. Filtering inventory to products with `stock = 0`
2. Joining to sales records with qualifying shipped statuses:
   - `Shipped - Delivered to Buyer`
   - `Shipped`
   - `Shipped - Out for Delivery`
   - `Shipped - Picked Up`
   - `Shipping`
3. Requiring `courier_status = "shipped"`
4. Summing the corresponding sales `amount`

This produces the final **₹12,98,275.84 Revenue at Risk**, from the 208 SKUs described above.

---

## 🛠️ Tools & Techniques

| Stage | Tools | Techniques |
|---|---|---|
| Initial preparation | Excel | Blank-row removal, unwanted-column removal, date formatting, city/state standardization |
| Cleaning & validation | MySQL | `JOIN`, `CASE WHEN`, subqueries, window functions, duplicate checks, SKU reconstruction, missing-value handling |
| Business analysis | MySQL | Aggregations, ratios, cancellation analysis, time trends, stockout analysis |
| Exploratory analysis | Python | pandas, NumPy, matplotlib, seaborn — distributions, time analysis, correlation, ratios, outlier analysis |
| Dashboarding | Power BI | DAX, `CALCULATE`, `FILTER`, cross-table filtering, conditional formatting, interactive slicers |

---

## 📁 Repository Structure

```text
amazon-sales-inventory-analysis/
│
├── README.md
│
├── sql/
│   ├── cleaning_data.sql
│   └── analysis_sql.sql
│
├── python/
│   └── eda_analysis.ipynb
│
├── powerbi/
│   └── inventory_analysis_sales.pbix
│
├── images/
│   ├── page1_overview.png
│   ├── page2_sales_performance.png
│   └── page3_inventory_restocking.png
│
└── data/
    ├── README.md
    └── processed/
        ├── cleaned_amazon_sales.csv
        └── cleaned_inventory.csv
```

---

## 📦 Dataset

**Source:** [E-Commerce Sales Data (Kaggle — thedevastator)](https://www.kaggle.com/datasets/thedevastator/unlock-profits-with-e-commerce-sales-data)

The dataset contains Amazon India seller sales data of approximately 129K transaction records, together with approximately 9.2K inventory records. The raw dataset is not stored in this repository — download from Kaggle and place in `data/` to reproduce the cleaning and analysis workflow (see `data/README.md`).

---

## 🚀 Reproduction Workflow

1. **Obtain the dataset** — download from Kaggle (link above)
2. **Prepare the source files** — apply the Excel preparation steps described above
3. **Load into MySQL** — create the tables and import the sales and inventory data
4. **Run SQL cleaning** — `sql/cleaning_data.sql`
5. **Run SQL analysis** — `sql/analysis_sql.sql`
6. **Run Python EDA** — `python/eda_analysis.ipynb` (connects to the same MySQL database via SQLAlchemy)
7. **Open Power BI** — `powerbi/inventory_analysis_sales.pbix`, connected to the same MySQL database

---

## ⚠️ Limitations

- The dataset represents a historical period (Apr–Jun 2022) rather than live Amazon data.
- Revenue-at-risk represents **historical revenue associated with currently zero-stock products**, not guaranteed future revenue loss.
- Inventory and sales are linked primarily through SKU matching, so unmatched SKUs are excluded from direct SKU-level inventory analysis.
- The dataset also includes a `b2b` order flag not explored in this project — see Future Analysis.

---

## Disclaimer

This is an independent data analytics portfolio project based on a publicly available Kaggle dataset. It is not official Amazon data and is not affiliated with, sponsored by, or endorsed by Amazon.

---

**Built as an end-to-end data analytics portfolio project using Excel, MySQL, Python, and Power BI.**
