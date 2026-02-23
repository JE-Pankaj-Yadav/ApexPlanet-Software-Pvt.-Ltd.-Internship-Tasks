/* =====================================================
   STEP 1 — Create Table Structure (Sab columns pehle text me)
   Purpose:
   - Pehle table create karte hain
   - Sab columns ko VARCHAR rakhte hain taaki CSV easily import ho jaye
   ===================================================== */

CREATE TABLE IF NOT EXISTS superstore (
    row_id VARCHAR(25),
    order_id VARCHAR(25),
    order_date VARCHAR(25),
    ship_date VARCHAR(25),
    ship_mode VARCHAR(25),
    customer_id VARCHAR(25),
    customer_name VARCHAR(25),
    segment VARCHAR(25),
    country VARCHAR(25),
    city VARCHAR(25),
    state VARCHAR(25),
    postal_code VARCHAR(25),
    region VARCHAR(25),
    product_id VARCHAR(25),
    category VARCHAR(25),
    sub_category VARCHAR(25),
    product_name VARCHAR(200),
    sales VARCHAR(25),
    quantity VARCHAR(25),
    discount VARCHAR(25),
    profit VARCHAR(25)
);



/* =====================================================
   STEP 2 — Import CSV Data
   Purpose:
   - CSV file ka data PostgreSQL table me load karna
   ===================================================== */

COPY superstore
FROM 'D:\INTERNSHIP (DATA ANALYSTIC)\ApexPlanet Software Pvt. Ltd\Task 2\Superstore.csv'
WITH (
    FORMAT csv,
    HEADER true,
    QUOTE '"',
    ESCAPE '"',
    ENCODING 'UTF8'
);



/* =====================================================
   STEP 3 — Convert Numeric Columns to Correct Data Types
   Purpose:
   - Text ko proper numeric format me convert karna
   - Taaki calculation easily ho sake
   ===================================================== */

ALTER TABLE superstore
ALTER COLUMN row_id TYPE INT USING row_id::INT,
ALTER COLUMN sales TYPE NUMERIC(10,2) USING sales::NUMERIC,
ALTER COLUMN quantity TYPE INT USING quantity::INT,
ALTER COLUMN discount TYPE NUMERIC(10,2) USING discount::NUMERIC,
ALTER COLUMN profit TYPE NUMERIC(10,2) USING profit::NUMERIC;



/* =====================================================
   STEP 4 — Convert Date Columns
   Purpose:
   - Excel serial date aur normal text date dono handle karna
   - Dono ko DATE format me convert karna
   ===================================================== */

ALTER TABLE superstore
ALTER COLUMN order_date TYPE DATE USING
CASE
    WHEN order_date ~ '^[0-9]+$'
        THEN DATE '1899-12-30' + order_date::INT
    ELSE TO_DATE(order_date,'MM/DD/YYYY')
END;

ALTER TABLE superstore
ALTER COLUMN ship_date TYPE DATE USING
CASE
    WHEN ship_date ~ '^[0-9]+$'
        THEN DATE '1899-12-30' + ship_date::INT
    ELSE TO_DATE(ship_date,'MM/DD/YYYY')
END;



/* =====================================================
   STEP 5 — Check Missing Values
   Purpose:
   - Important columns me NULL values check karna
   ===================================================== */

SELECT *
FROM superstore
WHERE order_id IS NULL
   OR order_date IS NULL
   OR ship_date IS NULL
   OR customer_id IS NULL
   OR postal_code IS NULL
   OR product_id IS NULL;



/* =====================================================
   STEP 6 — Detect Duplicate Records
   Purpose:
   - Duplicate row_id aur order_id check karna
   ===================================================== */

SELECT row_id, COUNT(*)
FROM superstore
GROUP BY row_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*)
FROM superstore
GROUP BY order_id
HAVING COUNT(*) > 1;



/* =====================================================
   STEP 7 — Validate Logical Data Errors
   Purpose:
   - Future dates check
   - Negative values check
   - Extreme outliers check
   ===================================================== */

-- Future date check
SELECT * FROM superstore
WHERE order_date > CURRENT_DATE
   OR ship_date > CURRENT_DATE;

-- Negative values check
SELECT * FROM superstore
WHERE sales < 0
   OR quantity < 0
   OR discount < 0;

-- Sales outlier check (3 Standard Deviation rule)
SELECT * FROM superstore 
WHERE sales > (
    SELECT AVG(sales) + 3 * STDDEV(sales)
    FROM superstore
);

-- Profit outlier check
SELECT * FROM superstore 
WHERE profit > (
    SELECT AVG(profit) + 3 * STDDEV(profit)
    FROM superstore
);


-- Delete extreme sales outliers
DELETE FROM superstore
WHERE sales > (
    SELECT AVG(sales) + 3 * STDDEV(sales)
    FROM superstore
);

-- Records with ship date before order date
DELETE FROM superstore
WHERE order_date > ship_date;


/* =====================================================
   STEP 8 — Safe Duplicate Removal
   Purpose:
   - Same order_id me multiple records ho to first record rakhenge
   ===================================================== */

DELETE FROM superstore
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM superstore
    GROUP BY order_id
);



/* =====================================================
   STEP 9 — Text Standardization & Cleaning
   Purpose:
   - Extra spaces remove karna
   - First letter capital karna
   - Special characters remove karna
   ===================================================== */

UPDATE superstore
SET
ship_mode = INITCAP(TRIM(REGEXP_REPLACE(ship_mode,'\s+',' ','g'))),
customer_name = INITCAP(TRIM(REGEXP_REPLACE(customer_name,'\s+',' ','g'))),
segment = INITCAP(TRIM(REGEXP_REPLACE(segment,'\s+',' ','g'))),
country = INITCAP(TRIM(REGEXP_REPLACE(country,'\s+',' ','g'))),
city = INITCAP(TRIM(REGEXP_REPLACE(city,'\s+',' ','g'))),
state = INITCAP(TRIM(REGEXP_REPLACE(state,'\s+',' ','g'))),
region = INITCAP(TRIM(REGEXP_REPLACE(region,'\s+',' ','g'))),
category = INITCAP(TRIM(REGEXP_REPLACE(category,'\s+',' ','g'))),
sub_category = INITCAP(TRIM(REGEXP_REPLACE(sub_category,'\s+',' ','g'))),
product_name = INITCAP(
    TRIM(REGEXP_REPLACE(product_name,'[^A-Za-z0-9 ]',' ','g'))
);



/* =====================================================
   ================= DATA CLEANING COMPLETE =================
   ===================================================== */



/* ============================================================
   BUSINESS ANALYSIS & EDA QUERIES
   ============================================================ */



/* ============================================================
   Overall Business Performance
   Purpose:
   - Total Sales
   - Total Profit
   - Total Orders
   - Total Customers
   ============================================================ */

SELECT 
    ROUND(SUM(sales),2) AS total_sales,
    ROUND(SUM(profit),2) AS total_profit,
    COUNT(order_id) AS total_order,
    COUNT(DISTINCT customer_name) AS total_customers
FROM superstore;

SELECT 
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit 
FROM superstore;



/* ============================================================
   Mean (Average) by Region
   ============================================================ */

SELECT 
    region,
    ROUND(AVG(sales), 2) AS average_sales,
    ROUND(AVG(profit), 2) AS average_profit,
    ROUND(AVG(quantity), 2) AS average_quantity,
    ROUND(AVG(discount), 2) AS average_discount
FROM superstore
GROUP BY region;



/* ============================================================
   Median Calculation
   ============================================================ */

SELECT 
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sales)::numeric, 2) AS median_sales,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY profit)::numeric, 2) AS median_profit,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY quantity)::numeric, 2) AS median_quantity,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY discount)::numeric, 2) AS median_discount
FROM superstore;



/* ============================================================
   Standard Deviation
   ============================================================ */

SELECT 
    ROUND(STDDEV(sales), 2) AS stddev_sales,
    ROUND(STDDEV(profit), 2) AS stddev_profit,
    ROUND(STDDEV(quantity), 2) AS stddev_quantity,
    ROUND(STDDEV(discount), 2) AS stddev_discount
FROM superstore;



/* ============================================================
   Difference Between Mean & Median
   Purpose:
   - Skewness check karna
   ============================================================ */

SELECT 
    ROUND(AVG(sales)-PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sales)::numeric,2) AS diff_sales_mean_median,
    ROUND(AVG(profit)-PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY profit)::numeric,2) AS diff_profit_mean_median,
    ROUND(AVG(quantity)-PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY quantity)::numeric,2) AS diff_quantity_mean_median,
    ROUND(AVG(discount)-PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY discount)::numeric,2) AS diff_discount_mean_median
FROM superstore;



/* ============================================================
   Yearly Analysis (Sales, Profit, Quantity, Discount)
   ============================================================ */

SELECT 
    EXTRACT(YEAR FROM order_date) AS year,
    ROUND(SUM(sales),2) AS total_sales,
    ROUND(SUM(profit),2) AS total_profit
FROM superstore
GROUP BY year
ORDER BY year;



/* ============================================================
   Monthly Profit Trend
   ============================================================ */

SELECT 
    EXTRACT(MONTH FROM order_date) AS month,
    ROUND(SUM(profit),2) AS total_profit
FROM superstore
GROUP BY month
ORDER BY month;



/* ============================================================
   Top 5 Most Profitable Products
   ============================================================ */

SELECT category, sub_category, product_name,
    ROUND(SUM(profit),2) AS total_profit
FROM superstore
GROUP BY product_name, category, sub_category
ORDER BY total_profit DESC
LIMIT 5;



/* ============================================================
   Top 5 Loss Making Products
   ============================================================ */

SELECT category, sub_category, product_name,
    ROUND(SUM(profit),2) AS total_profit
FROM superstore
GROUP BY product_name, category, sub_category
ORDER BY total_profit
LIMIT 5;



/* ============================================================
   Region Wise Profit Margin
   ============================================================ */

SELECT region,
    ROUND(SUM(sales),2) AS total_sales,
    ROUND(SUM(profit),2) AS total_profit,
    ROUND(SUM(profit)/SUM(sales)*100,2) AS profit_margin_percent
FROM superstore
GROUP BY region
ORDER BY profit_margin_percent DESC;



/* ============================================================
   Discount Impact on Profit
   ============================================================ */

SELECT 
    CASE
        WHEN discount > 0.2 THEN 'High Discount'
        ELSE 'Low Discount'
    END AS discount_category,
    ROUND(SUM(sales),2) AS total_sales,
    ROUND(SUM(profit),2) AS total_profit
FROM superstore
GROUP BY discount_category;



/* ============================================================
   Segment Wise Performance
   ============================================================ */

SELECT segment,
    ROUND(SUM(sales),2) AS total_sales,
    ROUND(SUM(profit),2) AS total_profit
FROM superstore
GROUP BY segment
ORDER BY total_profit DESC;



/* ============================================================
   Country Wise Performance
   ============================================================ */

SELECT 
    country,
    ROUND(SUM(sales),2) AS total_sales,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(profit),2) AS total_profit
FROM superstore
GROUP BY country;



/* ============================================================
   State Wise Performance
   ============================================================ */

SELECT 
    state,
    ROUND(SUM(sales),2) AS total_sales,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(profit),2) AS total_profit
FROM superstore
GROUP BY state
ORDER BY total_profit DESC;



/* ============================================================
   City Wise Performance
   ============================================================ */

SELECT 
    city,
    ROUND(SUM(sales),2) AS total_sales,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(profit),2) AS total_profit
FROM superstore
GROUP BY city
ORDER BY total_profit DESC;



/* ============================================================
   Category & Sub-Category Analysis
   ============================================================ */

SELECT 
    category,
    ROUND(SUM(sales),2) AS total_sales,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(profit),2) AS total_profit
FROM superstore
GROUP BY category
ORDER BY total_profit DESC;

SELECT 
    category,
    COUNT(*) AS count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM superstore
GROUP BY category
ORDER BY count DESC;

SELECT 
    segment,
    COUNT(*) AS count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM superstore
GROUP BY segment
ORDER BY count DESC;

SELECT 
    region,
    COUNT(*) AS count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM superstore
GROUP BY region
ORDER BY count DESC;

SELECT 
    ship_mode,
    COUNT(*) AS count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM superstore
GROUP BY ship_mode
ORDER BY count DESC;

SELECT 
    sub_category,
    ROUND(SUM(sales),2) AS total_sales,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(profit),2) AS total_profit
FROM superstore
GROUP BY sub_category
ORDER BY total_profit DESC;

SELECT Category, ROUND(AVG(Sales),2) AS Average_Sales, ROUND(AVG(Profit),2) AS Average_Profit 
FROM Superstore
GROUP BY category;  

SELECT ship_mode, ROUND(AVG(Sales),2) AS Average_Sales, ROUND(AVG(Profit),2) AS Average_Profit 
FROM Superstore
GROUP BY ship_mode;  


-- sales Frequency

SELECT 
    sales,
    COUNT(*) AS frequency
FROM superstore
GROUP BY sales
ORDER BY frequency DESC;



/* =====================================================
   STEP 10 — Export Cleaned Data
   Purpose:
   - Cleaned dataset ko CSV file me export karna
   ===================================================== */

COPY superstore
TO 'D:\INTERNSHIP (DATA ANALYSTIC)\ApexPlanet Software Pvt. Ltd\Task 2\Superstore_clean.csv'
WITH (
    FORMAT csv,
    HEADER true,
    QUOTE '"',
    ESCAPE '"',
    ENCODING 'UTF8'
);

COMMIT;



-- ============================================================
-- BUSINESS QUESTION:
-- What are the descriptive statistics for Sales, Profit,
-- Quantity, and Discount?
-- ============================================================

WITH stats AS (
    SELECT sales, profit, quantity, discount
    FROM superstore
)

SELECT 
    'Mean' AS statistic,
    ROUND(AVG(sales)::numeric,2)      AS sales,
    ROUND(AVG(profit)::numeric,2)     AS profit,
    ROUND(AVG(quantity)::numeric,2)   AS quantity,
    ROUND(AVG(discount)::numeric,2)   AS discount
FROM stats

UNION ALL

SELECT 
    'Median',
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sales)::numeric,2),
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY profit)::numeric,2),
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY quantity)::numeric,2),
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY discount)::numeric,2)
FROM stats

UNION ALL

SELECT 
    'Standard Deviation',
    ROUND(STDDEV(sales)::numeric,2),
    ROUND(STDDEV(profit)::numeric,2),
    ROUND(STDDEV(quantity)::numeric,2),
    ROUND(STDDEV(discount)::numeric,2)
FROM stats

UNION ALL

SELECT 
    'Minimum',
    ROUND(MIN(sales),2),
    ROUND(MIN(profit),2),
    ROUND(MIN(quantity),2),
    ROUND(MIN(discount),2)
FROM stats

UNION ALL

SELECT 
    '25th Percentile (Q1)',
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY sales)::numeric,2),
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY profit)::numeric,2),
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY quantity)::numeric,2),
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY discount)::numeric,2)
FROM stats

UNION ALL

SELECT 
    '75th Percentile (Q3)',
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sales)::numeric,2),
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY profit)::numeric,2),
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY quantity)::numeric,2),
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY discount)::numeric,2)
FROM stats

UNION ALL

SELECT 
    'Maximum',
    ROUND(MAX(sales),2),
    ROUND(MAX(profit),2),
    ROUND(MAX(quantity),2),
    ROUND(MAX(discount),2)
FROM stats;