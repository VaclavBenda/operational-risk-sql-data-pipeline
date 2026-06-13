/*
================================================================================
                            04_ddl_silver.sql
================================================================================
Script Purpose:
	Creates the Silver layer table for cleaned and typed operational risk data.

	Compared to Bronze, the Silver layer uses proper data types:
	- DATE for incident and reporting dates
	- DECIMAL for financial amounts
	- BIT for regulatory reportable flag
	- standardized text values for categories, status and severity

Usage Notes:
	Run this script before executing silver.load_silver.
================================================================================
*/

IF OBJECT_ID('silver.operational_risk_incidents', 'U') IS NOT NULL
	DROP TABLE silver.operational_risk_incidents;
GO

CREATE TABLE silver.operational_risk_incidents (
	incident_id NVARCHAR(50),
	reported_date DATE,
	incident_date DATE,
	business_unit NVARCHAR(100),
	risk_category NVARCHAR(100),
	event_type NVARCHAR(150),
	loss_amount DECIMAL(18,2),
	recovery_amount DECIMAL(18,2),
	net_loss_amount DECIMAL(18,2),
	currency NVARCHAR(10),
	[status] NVARCHAR(50),
	severity NVARCHAR(50),
	root_cause NVARCHAR(150),
	reported_by NVARCHAR(100),
	country NVARCHAR(100),
	is_regulatory_reportable BIT,
	[description] NVARCHAR(500)
);
