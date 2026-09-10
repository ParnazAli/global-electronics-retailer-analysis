-- ============================================================================
-- Global Electronics Retailer — SQL Analysis Layer
-- ============================================================================
-- These queries reproduce the key metrics from the four Python/pandas
-- notebooks using pure SQL against a SQLite database (data/global_electronics.db)
-- built from the same 5 raw CSVs (see src/build_database.py).
--
-- Revenue methodology (see notebooks/01_sales_performance.ipynb for full
-- rationale): Products.[Unit Price USD] is already in USD, so:
--   Revenue_USD = Quantity * [Unit Price USD]   -- no FX conversion needed
--
-- Run with: sqlite3 data/global_electronics.db < sql/queries.sql
-- or open the .db file in any SQL client (DB Browser for SQLite, DBeaver, etc.)
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 0. A reusable view: one row per sale line item, joined & with revenue/profit
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS sales_fact;
CREATE VIEW sales_fact AS
SELECT
    s.[Order Number]        AS order_number,
    s.[Order Date]          AS order_date,
    s.[Delivery Date]       AS delivery_date,
    s.CustomerKey,
    s.StoreKey,
    s.ProductKey,
    s.Quantity,
    s.[Currency Code]       AS currency_code,
    p.[Product Name]        AS product_name,
    p.Brand,
    p.Color,
    p.Category,
    p.Subcategory,
    p.[Unit Cost USD]       AS unit_cost_usd,
    p.[Unit Price USD]      AS unit_price_usd,
    s.Quantity * p.[Unit Price USD]                        AS revenue_usd,
    s.Quantity * p.[Unit Cost USD]                         AS cost_usd,
    s.Quantity * (p.[Unit Price USD] - p.[Unit Cost USD])  AS profit_usd,
    st.Country              AS store_country,
    st.[Store Type]         AS store_type,
    c.Country               AS customer_country,
    c.Continent,
    c.Gender
FROM sales s
JOIN products  p  ON s.ProductKey  = p.ProductKey
JOIN stores    st ON s.StoreKey    = st.StoreKey
JOIN customers c  ON s.CustomerKey = c.CustomerKey;


-- ============================================================================
-- MODULE 1: SALES PERFORMANCE
-- ============================================================================

-- 1.1 Monthly revenue & profit (feeds the trend chart; the recurring
--     ~37-day zero-order gap every March-April is visible here as months
--     with unusually low totals)
SELECT
    strftime('%Y-%m', order_date) AS year_month,
    ROUND(SUM(revenue_usd), 2)    AS revenue,
    ROUND(SUM(profit_usd), 2)     AS profit
FROM sales_fact
GROUP BY year_month
ORDER BY year_month;

-- 1.2 Year-over-Year revenue growth (full years only, 2016-2020)
WITH annual AS (
    SELECT strftime('%Y', order_date) AS yr, SUM(revenue_usd) AS revenue
    FROM sales_fact
    WHERE strftime('%Y', order_date) BETWEEN '2016' AND '2020'
    GROUP BY yr
)
SELECT
    yr,
    revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY yr)) / LAG(revenue) OVER (ORDER BY yr), 1) AS yoy_growth_pct
FROM annual
ORDER BY yr;

-- 1.3 In-Store vs Online: revenue share and average order value
WITH order_totals AS (
    SELECT order_number, store_type, SUM(revenue_usd) AS order_value
    FROM sales_fact
    GROUP BY order_number, store_type
)
SELECT
    store_type,
    COUNT(*)                       AS n_orders,
    ROUND(SUM(order_value), 2)     AS total_revenue,
    ROUND(AVG(order_value), 2)     AS avg_order_value
FROM order_totals
GROUP BY store_type;

-- 1.4 Delivery lag distribution (Online orders only — see data-quality note:
--     Delivery Date is structurally null for 100% of In-Store orders)
SELECT
    CAST(julianday(delivery_date) - julianday(order_date) AS INT) AS delivery_lag_days,
    COUNT(*) AS n_orders
FROM sales_fact
WHERE delivery_date IS NOT NULL
GROUP BY delivery_lag_days
ORDER BY delivery_lag_days;

-- 1.5 Revenue by day of week
SELECT
    CASE CAST(strftime('%w', order_date) AS INT)
        WHEN 0 THEN 'Sunday' WHEN 1 THEN 'Monday' WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday' WHEN 4 THEN 'Thursday' WHEN 5 THEN 'Friday'
        ELSE 'Saturday' END AS weekday,
    ROUND(SUM(revenue_usd), 2) AS revenue
FROM sales_fact
GROUP BY weekday
ORDER BY revenue DESC;


-- ============================================================================
-- MODULE 2: GEOGRAPHIC PERFORMANCE
-- ============================================================================

-- 2.1 Revenue, profit & margin by customer market (country)
SELECT
    customer_country,
    ROUND(SUM(revenue_usd), 2)                          AS revenue,
    ROUND(SUM(profit_usd), 2)                           AS profit,
    ROUND(100.0 * SUM(profit_usd) / SUM(revenue_usd), 1) AS margin_pct
FROM sales_fact
GROUP BY customer_country
ORDER BY revenue DESC;

-- 2.2 In-store revenue per square meter by store country
--     (store productivity — a much better lens than raw revenue ranking)
SELECT
    st.Country,
    COUNT(DISTINCT st.StoreKey)                              AS n_stores,
    SUM(st.[Square Meters])                                  AS total_sqm,
    ROUND(SUM(f.revenue_usd), 2)                             AS revenue,
    ROUND(SUM(f.revenue_usd) / SUM(st.[Square Meters]), 2)   AS revenue_per_sqm
FROM stores st
LEFT JOIN sales_fact f
    ON f.StoreKey = st.StoreKey AND f.store_type = 'In-Store'
WHERE st.StoreKey != 0
GROUP BY st.Country
ORDER BY revenue_per_sqm DESC;

-- 2.3 Physical stores with zero recorded sales (data-quality flag)
SELECT st.StoreKey, st.Country, st.[Square Meters], st.[Open Date]
FROM stores st
LEFT JOIN sales_fact f ON f.StoreKey = st.StoreKey
WHERE st.StoreKey != 0
GROUP BY st.StoreKey
HAVING COALESCE(SUM(f.revenue_usd), 0) = 0;

-- 2.4 Online penetration by market
SELECT
    customer_country,
    ROUND(100.0 * SUM(CASE WHEN store_type = 'Online' THEN 1 ELSE 0 END) / COUNT(*), 1) AS online_share_pct
FROM sales_fact
GROUP BY customer_country
ORDER BY online_share_pct DESC;


-- ============================================================================
-- MODULE 3: PRODUCT PERFORMANCE
-- ============================================================================

-- 3.1 Revenue & margin by category
SELECT
    Category,
    ROUND(SUM(revenue_usd), 2)                            AS revenue,
    ROUND(100.0 * SUM(profit_usd) / SUM(revenue_usd), 1)  AS margin_pct
FROM sales_fact
GROUP BY Category
ORDER BY revenue DESC;

-- 3.2 Top 10 products by revenue
SELECT product_name, ROUND(SUM(revenue_usd), 2) AS revenue
FROM sales_fact
GROUP BY product_name
ORDER BY revenue DESC
LIMIT 10;

-- 3.3 Brand performance (revenue & margin)
SELECT
    Brand,
    ROUND(SUM(revenue_usd), 2)                            AS revenue,
    ROUND(100.0 * SUM(profit_usd) / SUM(revenue_usd), 1)  AS margin_pct
FROM sales_fact
GROUP BY Brand
ORDER BY revenue DESC;

-- 3.4 Category revenue trend by year (Home Appliances vs the rest)
SELECT
    strftime('%Y', order_date) AS yr,
    Category,
    ROUND(SUM(revenue_usd), 2) AS revenue
FROM sales_fact
WHERE strftime('%Y', order_date) BETWEEN '2016' AND '2020'
GROUP BY yr, Category
ORDER BY Category, yr;


-- ============================================================================
-- MODULE 4: CUSTOMER SEGMENTATION
-- ============================================================================

-- 4.1 Revenue per customer by age group (demographics don't predict value)
SELECT
    CASE
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        WHEN age BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END AS age_group,
    COUNT(DISTINCT CustomerKey)                              AS n_customers,
    ROUND(SUM(revenue_usd), 2)                               AS revenue,
    ROUND(SUM(revenue_usd) / COUNT(DISTINCT CustomerKey), 2) AS revenue_per_customer
FROM (
    SELECT f.*, CAST((julianday('2021-02-20') - julianday(c.Birthday)) / 365.25 AS INT) AS age
    FROM sales_fact f
    JOIN customers c ON f.CustomerKey = c.CustomerKey
)
GROUP BY age_group
ORDER BY age_group;

-- 4.2 RFM (Recency, Frequency, Monetary) per customer
WITH last_order AS (SELECT MAX(order_date) AS max_date FROM sales_fact)
SELECT
    CustomerKey,
    CAST(julianday((SELECT max_date FROM last_order)) - julianday(MAX(order_date)) AS INT) AS recency_days,
    COUNT(DISTINCT order_number)   AS frequency,
    ROUND(SUM(revenue_usd), 2)     AS monetary
FROM sales_fact
GROUP BY CustomerKey
ORDER BY monetary DESC;

-- 4.3 Behavioral segments: customers vs. revenue share
--     (the "Loyal" 16% of customers generate 34% of revenue)
WITH rfm AS (
    SELECT CustomerKey, COUNT(DISTINCT order_number) AS frequency, SUM(revenue_usd) AS monetary
    FROM sales_fact
    GROUP BY CustomerKey
),
segmented AS (
    SELECT *,
        CASE WHEN frequency = 1 THEN 'One-time'
             WHEN frequency <= 3 THEN 'Occasional'
             ELSE 'Loyal' END AS segment
    FROM rfm
)
SELECT
    segment,
    COUNT(*)                                                          AS n_customers,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM segmented), 1)     AS customer_share_pct,
    ROUND(SUM(monetary), 2)                                           AS revenue,
    ROUND(100.0 * SUM(monetary) / (SELECT SUM(monetary) FROM segmented), 1) AS revenue_share_pct
FROM segmented
GROUP BY segment;

-- 4.4 Top-10% customer revenue concentration
WITH rfm AS (
    SELECT CustomerKey, SUM(revenue_usd) AS monetary
    FROM sales_fact GROUP BY CustomerKey
),
ranked AS (
    SELECT *, PERCENT_RANK() OVER (ORDER BY monetary DESC) AS pct_rank
    FROM rfm
)
SELECT
    ROUND(100.0 * SUM(CASE WHEN pct_rank <= 0.10 THEN monetary ELSE 0 END) / SUM(monetary), 1) AS top10pct_revenue_share
FROM ranked;
