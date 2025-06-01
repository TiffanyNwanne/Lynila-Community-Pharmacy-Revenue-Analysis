-- SALES
-- DATA IMPORT & EXPLORATION--

-- View all the rows in the table
SELECT * FROM pharmacy_sales;

-- Create a new table to accomodate the clean data 
CREATE TABLE clean_pharmacy_sales
LIKE pharmacy_sales;

-- Download pharmacy_dirty_data table as csv and import to clean_pharmacy_data table and view
SELECT * FROM clean_pharmacy_sales;


-- DATA CLEANING --

-- Rename the incosistent columns and standardise by defining data types
ALTER TABLE clean_pharmacy_sales
CHANGE `Date` record_date DATE,
CHANGE `presc_sales` prescription_sales VARCHAR(255),
CHANGE `otc_sales` otc_sales VARCHAR(255);

-- View changes
SELECT * FROM clean_pharmacy_sales;

-- Temporarily Disable Safe Update Mode
SET SQL_SAFE_UPDATES = 0;

-- Normalize prescription sales by NULLing out invalid values
UPDATE clean_pharmacy_sales
SET prescription_sales = NULL
WHERE prescription_sales IN ('error', 'N/A', 'NaN', '', 'null', 'unknown', '0');

-- Remove commas
UPDATE clean_pharmacy_sales
SET prescription_sales = REPLACE(prescription_sales, ',', '');

-- View changes
 SELECT * FROM clean_pharmacy_sales;
 
 -- Normalize OTC sales by NULLing out invalid values
UPDATE clean_pharmacy_sales
SET otc_sales = NULL
WHERE otc_sales IN ('error', 'N/A', 'NaN', '', 'null', 'unknown', '0'); 

-- Remove commas
UPDATE clean_pharmacy_sales
SET otc_sales = REPLACE(otc_sales, ',', '');

-- View changes
 SELECT * FROM clean_pharmacy_sales;
 
 -- DATA IMPORT & EXPLORATION--

-- View all the rows in the table
SELECT * FROM pharmacy_expenses;

-- Create a new table to accomodate the clean data 
CREATE TABLE clean_pharmacy_expenses
LIKE pharmacy_expenses;

-- Download pharmacy_dirty_data table as csv and import to clean_pharmacy_data table and view
SELECT * FROM clean_pharmacy_expenses;


-- EXPENSES
-- DATA CLEANING --

-- Rename the incosistent columns and standardise by defining data types
ALTER TABLE clean_pharmacy_expenses
CHANGE `month_year` record_date DATE,
CHANGE `salaries#` salaries VARCHAR(255),
CHANGE `RENT COST` rent_cost VARCHAR(255),
CHANGE `Util!ties` utilities VARCHAR(255),
CHANGE `inventory cost` inventory_cost VARCHAR(255),
CHANGE `miscellaneous` misc_expenses VARCHAR(255);

-- Temporarily Disable Safe Update Mode
SET SQL_SAFE_UPDATES = 0;


 --   Normalize salaries
UPDATE clean_pharmacy_expenses
SET salaries = NULL
WHERE TRIM(LOWER(salaries)) IN ('error', 'n/a', 'nan', '', 'null', 'unknown', '0');

-- Replace 'k' suffix (e.g., '51600k') with its numeric equivalent
UPDATE clean_pharmacy_expenses
SET salaries = CAST(REPLACE(LOWER(salaries), 'k', '') AS UNSIGNED) * 1000
WHERE LOWER(salaries) LIKE '%k';

-- Remove commas
UPDATE clean_pharmacy_expenses
SET salaries = REPLACE(salaries, ',', '');

 -- View changes
 SELECT * FROM clean_pharmacy_expenses;
 
 -- Normalize rent cost values
UPDATE clean_pharmacy_expenses
SET rent_cost = '50000'
WHERE TRIM(LOWER(rent_cost)) IN ('50k', 'fifty thousand');

UPDATE clean_pharmacy_expenses
SET rent_cost = NULL
WHERE rent_cost IN ('error', 'N/A', 'NaN', '', 'null', 'unknown', '0') ;


-- Remove commas
UPDATE clean_pharmacy_expenses
SET rent_cost = REPLACE (rent_cost, ',', '');

 -- View changes
SELECT * FROM clean_pharmacy_expenses;

 
 -- Normalise inventory cost
UPDATE clean_pharmacy_expenses
SET inventory_cost = NULL
WHERE TRIM(LOWER(inventory_cost)) IN ('error', 'n/a', 'nan', '', 'null', 'unknown', '0');

-- Convert values like '2446k' → 2446000
UPDATE clean_pharmacy_expenses
SET inventory_cost = CAST(REPLACE(LOWER(inventory_cost), 'k', '') AS UNSIGNED) * 1000
WHERE LOWER(inventory_cost) LIKE '%k';

-- Remove commas
UPDATE clean_pharmacy_expenses
SET inventory_cost = REPLACE(inventory_cost, ',', '');

 -- View changes
 SELECT * FROM clean_pharmacy_expenses;
 
  --   Normalize utilities
UPDATE clean_pharmacy_expenses
SET utilities = '2000'
WHERE utilities = 'two thousand';

UPDATE clean_pharmacy_expenses
SET utilities = NULL
WHERE TRIM(LOWER(utilities)) IN ('error', 'N/A', 'NaN', '', 'null', 'unknown', '0');

-- Remove commas
UPDATE clean_pharmacy_expenses
SET utilities = REPLACE(utilities, ',', '');

 -- View changes
 SELECT * FROM clean_pharmacy_expenses;
 
 -- Normalise miscellaneous expenses
UPDATE clean_pharmacy_expenses
SET misc_expenses = NULL
WHERE TRIM(LOWER(misc_expenses))IN ('error', 'N/A', 'NaN', '', 'null', 'unknown', '0');

-- Remove commas
UPDATE clean_pharmacy_expenses
SET misc_expenses = REPLACE(misc_expenses, ',', '');

 -- View changes
 SELECT * FROM clean_pharmacy_expenses;
 
 -- ANALYSIS
 -- Monthly Revenue vs Expenses
SELECT 
    DATE_FORMAT(s.record_date, '%Y-%m') AS month,
    SUM(COALESCE(s.prescription_sales, 0) + COALESCE(s.otc_sales, 0)) AS total_revenue,
    SUM(
        COALESCE(e.rent_cost, 0) +
        COALESCE(e.salaries, 0) +
        COALESCE(e.utilities, 0) +
        COALESCE(e.inventory_cost, 0) +
        COALESCE(e.misc_expenses, 0)
    ) AS total_expenses
FROM clean_pharmacy_sales s
JOIN clean_pharmacy_expenses e ON s.record_date = e.record_date
GROUP BY month
ORDER BY month;

-- Quarterly Revenue vs Expenses
SELECT 
    CONCAT(YEAR(s.record_date), '-Q', QUARTER(s.record_date)) AS quarter,
    SUM(COALESCE(s.prescription_sales, 0) + COALESCE(s.otc_sales, 0)) AS total_revenue,
    SUM(
        COALESCE(e.rent_cost, 0) +
        COALESCE(e.salaries, 0) +
        COALESCE(e.utilities, 0) +
        COALESCE(e.inventory_cost, 0) +
        COALESCE(e.misc_expenses, 0)
    ) AS total_expenses
FROM clean_pharmacy_sales s
JOIN clean_pharmacy_expenses e ON s.record_date = e.record_date
GROUP BY quarter
ORDER BY quarter;


-- Monthly Net Income
SELECT 
    DATE_FORMAT(s.record_date, '%Y-%m') AS month,
    SUM(COALESCE(s.prescription_sales, 0) + COALESCE(s.otc_sales, 0)) AS total_revenue,
    SUM(
        COALESCE(e.rent_cost, 0) +
        COALESCE(e.salaries, 0) +
        COALESCE(e.utilities, 0) +
        COALESCE(e.inventory_cost, 0) +
        COALESCE(e.misc_expenses, 0)
    ) AS total_expenses,
    SUM(
        (COALESCE(s.prescription_sales, 0) + COALESCE(s.otc_sales, 0)) -
        (COALESCE(e.rent_cost, 0) + COALESCE(e.salaries, 0) + COALESCE(e.utilities, 0) + COALESCE(e.inventory_cost, 0) + COALESCE(e.misc_expenses, 0))
    ) AS net_income
FROM clean_pharmacy_sales s
JOIN clean_pharmacy_expenses e ON s.record_date = e.record_date
GROUP BY month
ORDER BY month;


-- Revenue Breakdown
SELECT 'Prescription' AS category, SUM(COALESCE(prescription_sales, 0)) AS amount
FROM clean_pharmacy_sales
UNION
SELECT 'OTC', SUM(COALESCE(otc_sales, 0))
FROM clean_pharmacy_sales;

-- Expense Breakdown
SELECT 'Rent' AS category, SUM(COALESCE(rent_cost, 0)) AS amount
FROM clean_pharmacy_expenses
UNION
SELECT 'Salaries', SUM(COALESCE(salaries, 0))
FROM clean_pharmacy_expenses
UNION
SELECT 'Utilities', SUM(COALESCE(utilities, 0))
FROM clean_pharmacy_expenses
UNION
SELECT 'Inventory Cost', SUM(COALESCE(inventory_cost, 0))
FROM clean_pharmacy_expenses
UNION
SELECT 'Misc', SUM(COALESCE(misc_expenses, 0))
FROM clean_pharmacy_expenses;