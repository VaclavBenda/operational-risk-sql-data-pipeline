/*
==========================================================================
						02_proc_load_bronze.sql
==========================================================================
Script Purpose:
	Loads raw operational risk incident data from a CSV file into the Bronze layer.

	The procedure performs:
	- truncation of the Bronze target table
	- CSV import using BULK INSERT
	- simple runtime logging with PRINT messages
	- basic TRY/CATCH error handling

Important:
	Update the file path in BULK INSERT before running this procedure locally.

Usage Example:
	EXEC bronze.load_bronze;
==========================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME
	BEGIN TRY
		SET @start_time = GETDATE();
		PRINT '==============================================';
		PRINT '			  Loading Bronze Layer';
		PRINT '==============================================';

		-- Keep the Bronze table as the latest raw CSV load.
		PRINT '>> Truncating Table: bronze.operational_risk_incidents';
		TRUNCATE TABLE bronze.operational_risk_incidents;
		
		-- Update this local path before running the project on another machine.
		PRINT '>> Inserting Data Into: bronze.operational_risk_incidents';
		BULK INSERT bronze.operational_risk_incidents
		FROM 'D:\Operacni_rizika_project\operational_risk_project_datasets\operational_risk_incidents_raw.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds.';
		PRINT '-----------------------------------------------';
	END TRY
	BEGIN CATCH
		PRINT '==============================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR MESSAGE' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '==============================================';
	END CATCH
END