/*
================================================================================
                            05_proc_load_silver.sql
================================================================================
Script Purpose:
	Cleans and loads operational risk incident data from the Bronze layer into
	the Silver layer.

	The procedure performs:
	- truncation of the Silver target table
	- text trimming and empty-string to NULL conversion
	- normalization of business_unit, risk_category, status, severity and country
	- date conversion using multiple accepted date formats
	- amount cleaning and conversion to DECIMAL(18,2)
	- BIT conversion for the regulatory reportable flag

Important:
	Business-rule issues are not fixed here. They are checked later in
	07_data_quality_checks.sql

Usage Example:
	EXEC silver.load_silver;
==========================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME
	BEGIN TRY
		PRINT '==============================================';
		PRINT '			  Loading Silver Layer';
		PRINT '==============================================';

		-- Keep Silver reproducible when the procedure is executed multiple times.
		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.operational_risk_incidents';
		TRUNCATE TABLE silver.operational_risk_incidents;

		WITH basic_CTE AS (
		SELECT 	
			NULLIF(TRIM(incident_id),'') AS incident_id,
			NULLIF(TRIM(reported_date), '') AS reported_date,
			NULLIF(TRIM(incident_date), '') AS incident_date,
			-- Standardize business units with selected manual mappings.
			CASE 
				WHEN LOWER(TRIM(business_unit)) = 'branch network' THEN 'Branch Network'
				WHEN LOWER(TRIM(business_unit)) = 'risk management' THEN 'Risk Management'
				ELSE REPLACE(NULLIF(TRIM(business_unit),''), '  ', ' ')
			END AS business_unit,
			-- Map raw risk category variants to standardized reporting categories.
			CASE 
				WHEN LOWER(REPLACE(TRIM(risk_category), '  ', ' ')) IN ('it failure', 'system failure', 'technology failure') THEN 'IT Failure'
				WHEN LOWER(REPLACE(TRIM(risk_category), '  ', ' ')) IN ('dq issue', 'data quality', 'data quality issue') THEN 'Data Quality Issue'
				WHEN LOWER(REPLACE(TRIM(risk_category), '  ', ' ')) IN ('cybersecurity', 'cyber security') THEN 'Cyber Security'
				WHEN LOWER(REPLACE(TRIM(risk_category), '  ', ' ')) IN ('vendor issue', 'third party', 'external vendor') THEN 'External Vendor'
				WHEN LOWER(REPLACE(TRIM(risk_category), '  ', ' ')) IN ('regulatory breach', 'compliance breach') THEN 'Compliance Breach'
				WHEN LOWER(REPLACE(TRIM(risk_category), '  ', ' ')) = 'fraud' THEN 'Fraud'
				WHEN LOWER(REPLACE(TRIM(risk_category), '  ', ' ')) IN ('user error', 'human error') THEN 'Human Error'
				WHEN LOWER(REPLACE(TRIM(risk_category), '  ', ' ')) IN ('process error', 'processing error') THEN 'Process Error'
				ELSE NULL
			END AS risk_category,
			LOWER(REPLACE(NULLIF(TRIM(event_type), ''), '  ', ' ')) AS event_type,
			-- Clean mixed amount formats before final DECIMAL conversion.
			-- Examples handled: 6,884.62 -> 6884.62; 2 537,30 ->2537.30; text -> NULL.
			CASE 
				WHEN REPLACE(TRIM(loss_amount), ' ', '') LIKE '%,%' AND REPLACE(TRIM(loss_amount), ' ', '') LIKE '%.%' THEN REPLACE(REPLACE(TRIM(loss_amount), ' ',''), ',', '')
				WHEN REPLACE(TRIM(loss_amount), ' ', '') LIKE '%,%' AND REPLACE(TRIM(loss_amount), ' ', '') NOT LIKE '%.%' THEN REPLACE(REPLACE(TRIM(loss_amount), ' ',''), ',', '.')
				WHEN NULLIF(TRIM(loss_amount), '') IS NULL OR LOWER(TRIM(loss_amount)) IN ('unknown', 'n/a', '-') THEN NULL
				ELSE REPLACE(TRIM(loss_amount), ' ', '')
			END AS loss_amount,
			CASE
				WHEN REPLACE(TRIM(recovery_amount), ' ', '') LIKE '%.%' AND REPLACE(TRIM(recovery_amount), ' ', '') LIKE '%,%' THEN REPLACE(REPLACE(TRIM(recovery_amount), ' ', ''), ',', '')
				WHEN REPLACE(TRIM(recovery_amount), ' ', '') LIKE '%,%' AND REPLACE(TRIM(recovery_amount), ' ', '') NOT LIKE '%.%' THEN REPLACE(REPLACE(TRIM(recovery_amount), ' ', ''), ',', '.')
				WHEN NULLIF(TRIM(recovery_amount), '') IS NULL OR LOWER(TRIM(recovery_amount)) IN ('n/a', 'unknown', '-') THEN NULL
				ELSE REPLACE(TRIM(recovery_amount), ' ', '')
			END AS recovery_amount,
			CASE
				WHEN REPLACE(TRIM(net_loss_amount), ' ', '') LIKE '%,%' AND REPLACE(TRIM(net_loss_amount), ' ', '') LIKE '%.%' THEN REPLACE(REPLACE(TRIM(net_loss_amount), ' ', ''), ',', '')
				WHEN REPLACE(TRIM(net_loss_amount), ' ', '') LIKE '%,%' AND REPLACE(TRIM(net_loss_amount), ' ', '') NOT LIKE '%.%' THEN REPLACE(REPLACE(TRIM(net_loss_amount), ' ', ''), ',', '.')
				WHEN NULLIF(TRIM(net_loss_amount), '') IS NULL OR LOWER(TRIM(net_loss_amount)) IN ('-', 'n/a', 'unknown') THEN NULL
				ELSE REPLACE(TRIM(net_loss_amount), ' ', '')
			END AS net_loss_amount,
			UPPER(NULLIF(TRIM(currency), '')) AS currency,
			-- Standardize workflow status values.
			CASE LOWER(REPLACE(TRIM([status]), '  ', ' '))
				WHEN 'closed' THEN 'Closed'
				WHEN 'open' THEN 'Open'
				WHEN 'under review' THEN 'Under Review'
				WHEN 'in review' THEN 'Under Review'
				WHEN 'rejected' THEN 'Rejected'
				ELSE NULL
			END AS [status],
			-- Keep only approved severity labels.
			CASE LOWER(TRIM(severity))
				WHEN 'low' THEN 'Low'
				WHEN 'medium' THEN 'Medium'
				WHEN 'high' THEN 'High'
				WHEN 'critical' THEN 'Critical'
				ELSE NULL
			END AS severity,
			CASE 
				WHEN LOWER(TRIM(root_cause)) = 'weak password policy' THEN 'Weak password policy'
				ELSE LOWER(REPLACE(NULLIF(TRIM(root_cause),''), '  ', ' '))
			END AS root_cause,
			NULLIF(TRIM(reported_by), '') AS reported_by,
			CASE 
				WHEN LOWER(TRIM(country)) IN ('cz', 'czech', 'czech republic') THEN 'Czech Republic'
				ELSE NULLIF(TRIM(country), '')
			END AS country,
			CASE
				WHEN LOWER(NULLIF(TRIM(is_regulatory_reportable), '')) IN ('yes', 'y') THEN 1
				WHEN LOWER(NULLIF(TRIM(is_regulatory_reportable), '')) IN ('no', 'n') THEN 0
				ELSE NULL
			END AS is_regulatory_reportable,
			NULLIF(TRIM([description]), '') AS [description]
		FROM bronze.operational_risk_incidents
		),
		final_CTE AS (
		SELECT 
			incident_id,

			-- Convert date strings using multiple accepted source formats.
			COALESCE(TRY_CONVERT(DATE, reported_date, 23), TRY_CONVERT(DATE, reported_date, 103), TRY_CONVERT(DATE, reported_date, 101)) AS reported_date,
			COALESCE(TRY_CONVERT(DATE, incident_date, 23), TRY_CONVERT(DATE, incident_date, 103)) AS incident_date,
			business_unit,
			risk_category,
			event_type,
			TRY_CONVERT(DECIMAL(18,2), loss_amount) AS loss_amount,
			TRY_CONVERT(DECIMAL(18,2),recovery_amount) AS recovery_amount,
			TRY_CONVERT(DECIMAL(18,2), net_loss_amount) AS net_loss_amount,
			currency,
			[status],
			severity,
			root_cause,
			reported_by,
			country,
			TRY_CONVERT(BIT, is_regulatory_reportable) AS is_regulatory_reportable,
			[description]
		FROM basic_CTE
		)

		INSERT INTO silver.operational_risk_incidents(
			incident_id,
			reported_date,
			incident_date,
			business_unit,
			risk_category,
			event_type,
			loss_amount,
			recovery_amount,
			net_loss_amount,
			currency,
			[status],
			severity,
			root_cause,
			reported_by,
			country,
			is_regulatory_reportable,
			[description]
		)
		SELECT 
			incident_id,
			reported_date,
			incident_date,
			business_unit,
			risk_category,
			event_type,
			loss_amount,
			recovery_amount,
			net_loss_amount,
			currency,
			[status],
			severity,
			root_cause,
			reported_by,
			country,
			is_regulatory_reportable,
			[description]
		FROM final_CTE;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds.';
		PRINT '-----------------------------------------------';
	END TRY
	BEGIN CATCH
		PRINT '==============================================';
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
		PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR MESSAGE' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '==============================================';
	END CATCH
END