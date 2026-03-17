-- ============================================================
-- STEP 1: CREATE RAW TABLE FOR CUSTOMER SHOPPING DATA
-- This table stores raw data before cleaning and transformation
-- ============================================================

CREATE TABLE IF NOT EXISTS customer_shopping_data (
    invoice_no VARCHAR(50),        -- Unique invoice number for each transaction
    customer_id VARCHAR(50),       -- Unique identifier for each customer
    gender VARCHAR(50),            -- Gender of the customer (may contain inconsistencies)
    age VARCHAR(50),               -- Age of the customer (stored as text initially)
    category VARCHAR(50),          -- Product category
    quantity VARCHAR(50),          -- Quantity purchased (stored as text initially)
    price VARCHAR(50),             -- Price per unit (stored as text initially)
    payment_method VARCHAR(50),    -- Mode of payment (Cash, Card, etc.)
    invoice_date VARCHAR(50),      -- Date of purchase (stored as text)
    shopping_mall VARCHAR(50)      -- Shopping mall where purchase was made
);

-- ============================================================
-- STEP 2: DATA TYPE CONVERSION
-- Converting columns from VARCHAR to appropriate data types
-- ============================================================

ALTER TABLE
    customer_shopping_data
ALTER COLUMN
    quantity TYPE INT USING quantity :: INT,                     -- Convert quantity to integer
ALTER COLUMN
    PRICE TYPE numeric(10, 2) USING PRICE :: numeric,            -- Convert price to numeric with 2 decimals
ALTER COLUMN
    invoice_date TYPE DATE USING TO_DATE(invoice_date, 'DD/MM/YYYY'), -- Convert text date to DATE format
ALTER COLUMN
    AGE TYPE INT USING AGE :: INT;                               -- Convert age to integer

-- ============================================================
-- STEP 3: IDENTIFY MISSING (NULL) VALUES IN CRITICAL COLUMNS
-- ============================================================

SELECT *
FROM customer_shopping_data
WHERE
    invoice_no IS NULL
    OR customer_id IS NULL
    OR quantity IS NULL
    OR price IS NULL
    OR invoice_date IS NULL;

-- ============================================================
-- STEP 4: IDENTIFY DUPLICATE RECORDS BASED ON INVOICE NUMBER
-- ============================================================

SELECT
    invoice_no,
    COUNT(*)
FROM customer_shopping_data
GROUP BY invoice_no
HAVING COUNT(*) > 1;

-- ============================================================
-- STEP 5: IDENTIFY INVALID AGE VALUES
-- Age should be between 0 and 100
-- ============================================================

SELECT * FROM customer_shopping_data
WHERE age < 0 OR age > 100;

-- ============================================================
-- STEP 6: IDENTIFY INVALID PRICE OR QUANTITY VALUES
-- ============================================================

SELECT * FROM customer_shopping_data
WHERE price < 0 OR quantity < 0; 

-- ============================================================
-- STEP 7: CHECK DISTINCT VALUES OF GENDER COLUMN
-- Used to find inconsistent entries
-- ============================================================

SELECT DISTINCT gender FROM customer_shopping_data;

-- ============================================================
-- STEP 8: IDENTIFY GENDER VALUES WITH LEADING OR TRAILING SPACES
-- ============================================================

SELECT * FROM customer_shopping_data
WHERE gender LIKE ' %' OR gender LIKE '% ';

-- ============================================================
-- STEP 9: IDENTIFY FUTURE DATES (DATA ENTRY ERRORS)
-- ============================================================

SELECT * FROM customer_shopping_data
WHERE invoice_date > CURRENT_DATE;

-- ============================================================
-- STEP 10: IDENTIFY PRICE OUTLIERS USING 3-SIGMA RULE
-- ============================================================

SELECT * FROM customer_shopping_data 
WHERE price > (
    SELECT AVG(price) + 3 * STDDEV(price)
    FROM customer_shopping_data
);

-- ============================================================
-- STEP 11: REMOVE RECORDS WITH MISSING (NULL) VALUES
-- ============================================================

DELETE FROM customer_shopping_data
WHERE
    invoice_no IS NULL
    OR customer_id IS NULL
    OR quantity IS NULL
    OR price IS NULL
    OR invoice_date IS NULL;

-- ============================================================
-- STEP 12: REMOVE DUPLICATE INVOICE RECORDS
-- ============================================================

DELETE FROM customer_shopping_data
WHERE invoice_no IN (
    SELECT invoice_no FROM customer_shopping_data
    GROUP BY invoice_no
    HAVING COUNT(*) > 1
);

-- ============================================================
-- STEP 13: REMOVE INVALID AGE VALUES
-- ============================================================

DELETE FROM customer_shopping_data
WHERE age < 0 OR age > 100;

-- ============================================================
-- STEP 14: REMOVE INVALID PRICE AND QUANTITY VALUES
-- ============================================================

DELETE FROM customer_shopping_data
WHERE PRICE < 0 OR QUANTITY < 0;

-- ============================================================
-- STEP 15: STANDARDIZE GENDER COLUMN
-- Trim spaces and convert values to uppercase
-- ============================================================

UPDATE customer_shopping_data
SET gender = UPPER(TRIM(gender));

-- ============================================================
-- STEP 16: STANDARDIZE MALE VALUES
-- ============================================================

UPDATE customer_shopping_data
SET gender = 'MALE'
WHERE LOWER(gender) IN ('m', 'male');

-- ============================================================
-- STEP 17: STANDARDIZE FEMALE VALUES
-- ============================================================

UPDATE customer_shopping_data
SET gender = 'FEMALE'
WHERE LOWER(gender) IN ('f', 'female');

-- ============================================================
-- STEP 18: REMOVE RECORDS WITH FUTURE INVOICE DATES
-- ============================================================

DELETE FROM customer_shopping_data
WHERE invoice_date > CURRENT_DATE;

-- ============================================================
-- STEP 19: REMOVE PRICE OUTLIERS USING 3-SIGMA RULE
-- ============================================================

DELETE FROM customer_shopping_data
WHERE PRICE > (
    SELECT AVG(PRICE) + 3 * STDDEV(PRICE)
    FROM customer_shopping_data
);

-- ============================================================
-- STEP 20: ADD DERIVED COLUMN FOR TOTAL TRANSACTION AMOUNT
-- ============================================================

ALTER TABLE customer_shopping_data
ADD COLUMN TOTAL_AMOUNT NUMERIC(10,2);

-- ============================================================
-- STEP 21: CALCULATE TOTAL AMOUNT (PRICE × QUANTITY)
-- ============================================================

UPDATE customer_shopping_data
SET TOTAL_AMOUNT = PRICE * QUANTITY;

-- ============================================================
-- STEP 22: EXPORT CLEANED DATASET TO CSV FILE
-- This step saves the final, analysis-ready data
-- The exported file can be used for further analysis,
-- reporting, dashboards, or sharing with stakeholders
-- ============================================================

COPY customer_shopping_data
TO 'D:\INTERNSHIP (DATA ANALYSTIC)\ApexPlanet Software Pvt. Ltd\customer_shopping_data.csv'
DELIMITER ','          -- Use comma as field separator
CSV HEADER;            -- Include column names as header in CSV file
