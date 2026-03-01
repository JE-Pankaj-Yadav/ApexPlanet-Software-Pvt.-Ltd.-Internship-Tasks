/* =====================================================
   SECTION 1 : DATA CLEANING
   Purpose: Import data and clean it properly
   ===================================================== */

-- Create table if not exists
CREATE TABLE IF NOT EXISTS ecommerce_sales_data(
    Order_id VARCHAR(50),
    Order_Date VARCHAR(50),
    Product_Name VARCHAR(50),
    Category VARCHAR(50),
    Region VARCHAR(50),
    Quantity VARCHAR(50),
    Sales VARCHAR(50),
    Profit VARCHAR(50),
    Country VARCHAR(50),
    Customer_Name VARCHAR(50),
    State VARCHAR(50),
    sub_category VARCHAR(50),
    discount VARCHAR(50),
    segment VARCHAR(50)
);

-- Import CSV file into table
COPY ecommerce_sales_data
FROM 'D:\INTERNSHIP (DATA ANALYSTIC)\ApexPlanet Software Pvt. Ltd\Task 3\ecommerce_sales_data.csv'
WITH (
    FORMAT csv,
    HEADER true,
    QUOTE '"',
    ESCAPE '"',
    ENCODING 'UTF8'
);

-- Convert columns into correct data types
ALTER TABLE ecommerce_sales_data
ALTER COLUMN Order_id TYPE INT USING Order_id::INT,
ALTER COLUMN Order_Date TYPE DATE USING TO_DATE(order_date,'DD/MM/YYYY'),
ALTER COLUMN Quantity TYPE INT USING Quantity::INT,
ALTER COLUMN Sales TYPE NUMERIC(10,2) USING Sales::NUMERIC,
ALTER COLUMN Profit TYPE NUMERIC(10,2) USING Profit::NUMERIC,
ALTER COLUMN Discount TYPE NUMERIC(10,2) USING Discount::NUMERIC;

-- Check NULL values
SELECT *
FROM ecommerce_sales_data
WHERE order_id IS NULL
   OR order_date IS NULL
   OR category IS NULL
   OR region IS NULL
   OR sales IS NULL
   OR profit IS NULL
   OR product_name IS NULL;

-- Check duplicate Order IDs
SELECT Order_id, COUNT(*)
FROM ecommerce_sales_data
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Remove duplicate records (keep only one)
DELETE FROM ecommerce_sales_data
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM ecommerce_sales_data
    GROUP BY order_id
);

-- Clean text columns (remove extra spaces & fix capitalization)
UPDATE ecommerce_sales_data
SET 
    Product_Name = INITCAP(TRIM(REGEXP_REPLACE(Product_Name,'\s+',' ','g'))),
    Category = INITCAP(TRIM(REGEXP_REPLACE(Category,'\s+',' ','g'))),
    Region = INITCAP(TRIM(REGEXP_REPLACE(Region,'\s+',' ','g'))),
    Country = INITCAP(TRIM(REGEXP_REPLACE(Country,'\s+',' ','g'))),
    Customer_Name = INITCAP(TRIM(REGEXP_REPLACE(Customer_Name,'\s+',' ','g'))),
    State = INITCAP(TRIM(REGEXP_REPLACE(State,'\s+',' ','g'))),
    Segment = INITCAP(TRIM(REGEXP_REPLACE(Segment,'\s+',' ','g'))),
    Sub_Category = INITCAP(TRIM(REGEXP_REPLACE(Sub_Category,'\s+',' ','g')));

-- Export clean data
COPY ecommerce_sales_data
TO 'D:\INTERNSHIP (DATA ANALYSTIC)\ApexPlanet Software Pvt. Ltd\Task 3\clean_ecommerce_sales_data.csv'
WITH (
    FORMAT csv,
    HEADER true,
    QUOTE '"',
    ESCAPE '"',
    ENCODING 'UTF8'
);

/* =====================================================
   SECTION 2 : KPI CALCULATIONS
   Purpose: Calculate important business performance numbers
   ===================================================== */

-- 1️⃣ Total Sales (Total revenue earned)
SELECT SUM(Sales) AS total_sales 
FROM ecommerce_sales_data;

-- 2️⃣ Total Profit (Actual money earned after cost)
SELECT SUM(Profit) AS total_profit 
FROM ecommerce_sales_data;

-- 3️⃣ Profit Margin % (How much profit from total sales)
SELECT ROUND(SUM(Profit)/SUM(Sales)*100,2) AS profit_margin_percent 
FROM ecommerce_sales_data;

-- 4️⃣ Average Sales per Order
SELECT ROUND(AVG(Sales),2) AS avg_order_value
FROM ecommerce_sales_data;

-- 5️⃣ Total Orders
SELECT COUNT(Order_id) AS total_orders
FROM ecommerce_sales_data;

-- 6️⃣ Repeat Customers (Customers who purchased more than once)
SELECT Customer_Name, COUNT(*) AS order_count
FROM ecommerce_sales_data
GROUP BY Customer_Name
HAVING COUNT(*) > 1;

-- 7️⃣ High Spending Customers (More than 2600 spend)
SELECT COUNT(*) AS customers_more_than_2600
FROM (
    SELECT Customer_Name, SUM(Sales) AS total_spend
    FROM ecommerce_sales_data
    GROUP BY Customer_Name
) t
WHERE total_spend > 2600;

/* =====================================================
   SECTION 3 : BUSINESS QUESTIONS
   Purpose: Answer important business problems
   ===================================================== */

-- 1️⃣ Which region generates highest sales?
SELECT Region, SUM(Sales) AS total_sales
FROM ecommerce_sales_data
GROUP BY Region
ORDER BY total_sales DESC
LIMIT 1;

-- 2️⃣ Which category sells the most (by quantity)?
SELECT Category, SUM(Quantity) AS total_quantity
FROM ecommerce_sales_data
GROUP BY Category
ORDER BY total_quantity DESC
LIMIT 1;

-- 3️⃣ Which category gives highest profit?
SELECT Category, SUM(Profit) AS total_profit
FROM ecommerce_sales_data
GROUP BY Category
ORDER BY total_profit DESC
LIMIT 1;

-- 4️⃣ Monthly Highest & Lowest Sales
WITH monthly_sales AS (
    SELECT 
        EXTRACT(MONTH FROM Order_Date) AS month,
        SUM(Sales) AS total_sales
    FROM ecommerce_sales_data
    GROUP BY EXTRACT(MONTH FROM Order_Date)
)
SELECT *
FROM monthly_sales
ORDER BY total_sales DESC;

-- 5️⃣ Customer Spending Category (Low / Medium / High)
ALTER TABLE ecommerce_sales_data
ADD COLUMN IF NOT EXISTS spending_category VARCHAR(20);

UPDATE ecommerce_sales_data e
SET spending_category =
    CASE
        WHEN t.total_spend <= 70000 THEN 'LOW'
        WHEN t.total_spend BETWEEN 70001 AND 100000 THEN 'MEDIUM'
        ELSE 'HIGH'
    END
FROM (
    SELECT Customer_Name, SUM(Sales) AS total_spend
    FROM ecommerce_sales_data
    GROUP BY Customer_Name
) t
WHERE e.Customer_Name = t.Customer_Name;

-- 6️⃣ Percentage of customers in each spending category
SELECT 
    spending_category,
    COUNT(DISTINCT Customer_Name) AS total_customers,
    ROUND(
        COUNT(DISTINCT Customer_Name) * 100.0 /
        (SELECT COUNT(DISTINCT Customer_Name) FROM ecommerce_sales_data),
    2) AS percentage
FROM ecommerce_sales_data
GROUP BY spending_category;