/*
=============================================================================
							01_ddl_bronze.sql
=============================================================================
Script Purpose:
	Creates the Bronze layer table used for raw operational risk incident data.

	The Bronze layer stores the raw CSV export with minimal transformation.
	All columns are defined as NVARCHAR because the source data contains mixed
	formats, inconsistent values, invalid dates and text-based numeric amounts.

Usage Notes:
	Run this script after 00_init_database.sql and before loading Bronze data.
=============================================================================
*/

-- Recreate the raw landing table.
IF OBJECT_ID('bronze.operational_risk_incidents', 'U') IS NOT NULL
	DROP TABLE bronze.operational_risk_incidents;
GO

CREATE TABLE bronze.operational_risk_incidents (
	incident_id NVARCHAR(200),
	reported_date NVARCHAR(200),
	incident_date NVARCHAR(200),
	business_unit NVARCHAR(200),
	risk_category NVARCHAR(200),
	event_type NVARCHAR(200),
	loss_amount NVARCHAR(200),
	recovery_amount NVARCHAR(200),
	net_loss_amount NVARCHAR(200),
	currency NVARCHAR(200),
	[status] NVARCHAR(200),
	severity NVARCHAR(200),
	root_cause NVARCHAR(200),
	reported_by NVARCHAR(200),
	country NVARCHAR(200),
	is_regulatory_reportable NVARCHAR(200), 
	[description] NVARCHAR(200)
);
GO

