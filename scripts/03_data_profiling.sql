/*
================================================================================
                            03_data_profiling.sql
================================================================================
Script Purpose:
	Performs initial profiling checks on raw Bronze data before any cleaning or
	type conversion is applied.

	The goal is to understand the raw source quality and identify common issues:
	- row counts and uniqueness
	- missing values
	- inconsistent status and risk_category values
	- invalid or non-standart date formats
	- amount values that cannot be directly converted to DECIMAL

Usage Notes:
	Run this script after loading data into bronze.operational_risk_incidents.

*/
-- 1. Number of all raw rows.
SELECT 
	COUNT(*) AS nr_of_rows 
FROM bronze.operational_risk_incidents;

-- 2. Number of unique incident_id values.
SELECT 
	COUNT(DISTINCT(incident_id)) AS unique_incident_id 
FROM bronze.operational_risk_incidents;

-- 3. Duplicated incident_id values.
SELECT 
	incident_id, 
	COUNT(incident_id) AS nr_of_dups 
FROM bronze.operational_risk_incidents
WHERE incident_id IS NOT NULL
GROUP BY incident_id
HAVING COUNT(incident_id) > 1
ORDER BY nr_of_dups DESC, incident_id;

-- 4. Rows where risk_category is missing.
SELECT * 
FROM bronze.operational_risk_incidents
WHERE NULLIF(TRIM(risk_category), '') IS NULL;

-- 5. Rows where status is missing.
SELECT * 
FROM bronze.operational_risk_incidents
WHERE NULLIF(TRIM([status]), '') IS NULL;

-- 6. Different raw values ​​in status.
SELECT 
	DISTINCT([status]), 
	COUNT(*) AS nr_status 
FROM bronze.operational_risk_incidents
GROUP BY [status]
ORDER BY nr_status DESC, [status];

-- 7. Different raw values ​​in risk_category.
SELECT 
	DISTINCT(risk_category), 
	COUNT(*) AS nr_risk_category 
FROM bronze.operational_risk_incidents
GROUP BY risk_category
ORDER BY nr_risk_category DESC, risk_category;

-- 8. Rows where incident_date cannot be converted to DATE in accepted formats.
SELECT * 
FROM bronze.operational_risk_incidents
WHERE NULLIF(TRIM(incident_date), '') IS NOT NULL
 AND TRY_CONVERT(DATE, TRIM(incident_date), 23) IS NULL -- yyyy-mm-dd
 AND TRY_CONVERT(DATE, TRIM(incident_date), 103) IS NULL; -- dd/mm/yyyy

-- 8.1 Rows where incident_date is valid but not in expected yyyy-mm-dd format.
SELECT * 
FROM bronze.operational_risk_incidents
WHERE NULLIF(TRIM(incident_date), '') IS NOT NULL
 AND TRY_CONVERT(DATE, TRIM(incident_date), 23) IS NULL
 AND TRY_CONVERT(DATE, TRIM(incident_date), 103) IS NOT NULL;

-- 9. Rows where reported_date cannot be converted to DATE in accepted formats.
SELECT * 
FROM bronze.operational_risk_incidents
WHERE NULLIF(TRIM(reported_date), '') IS NOT NULL
 AND TRY_CONVERT(DATE, TRIM(reported_date), 23) IS NULL -- yyyy-mm-dd
 AND TRY_CONVERT(DATE, TRIM(reported_date), 103) IS NULL -- mm/dd/yyyy
 AND TRY_CONVERT(DATE, TRIM(reported_date), 101) IS NULL; -- mm-dd-yyyy

-- 9.1 Rows where reported_date is valid but not in expected yyyy-mm-dd format.
SELECT *
FROM bronze.operational_risk_incidents
WHERE NULLIF(TRIM(reported_date), '') IS NOT NULL
 AND TRY_CONVERT(DATE, TRIM(reported_date), 23) IS NULL
 AND (
	 TRY_CONVERT(DATE, TRIM(reported_date), 103) IS NOT NULL
	 OR  TRY_CONVERT(DATE, TRIM(reported_date), 101) IS NOT NULL
	 );


-- 10. Rows where loss_amount cannot be directly converted to DECIMAL.
-- Some of these values may still be fixable during Silver cleaning.
SELECT * 
FROM bronze.operational_risk_incidents
WHERE NULLIF(TRIM(loss_amount), '') IS NOT NULL
 AND TRY_CONVERT(DECIMAL(18,2), NULLIF(TRIM(loss_amount), '')) IS NULL;

