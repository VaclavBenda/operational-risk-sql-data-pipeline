/*
================================================================================
                        06_silver_validation_checks.sql
================================================================================
Script Purpose:
    Performs quick validation checks after loading data into the Silver layer.

    These checks are not business data quality rules. They are simple sanity checks
    used to confirm that Silver load worked and that standardized values look
    reasonable before running deeper data quality checks.

Usage Notes:
    Run this script after executing: EXEC silver.load_silver;
================================================================================
*/

-- 1. Check total number of rows loaded into Silver.
SELECT 
    COUNT(*)  AS silver_row_count
FROM silver.operational_risk_incidents;

-- 2. Verify standardized status values.
SELECT 
    DISTINCT([status]) 
FROM silver.operational_risk_incidents;

-- 3. Verify standardized risk_category values.
SELECT 
    DISTINCT(risk_category)
FROM silver.operational_risk_incidents;

-- 4. Verify standardized severity values.
SELECT DISTINCT(severity) FROM silver.operational_risk_incidents;

-- 5. Preview cleaned Silver records.
SELECT TOP 50 
    * 
FROM silver.operational_risk_incidents;
