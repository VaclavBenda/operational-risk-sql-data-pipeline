/*
==============================================================================
						  09_gold_reporting_views.sql
==============================================================================
Script Purpose:
	Creates reporting views in the Gold layer based on valid cleaned data
	from silver.vw_valid_operational_risk_incidents.

	These views provide business-ready aggregations and filtered reporting datasets:
	- monthly incident summary
	- risk category summary
	- open incidents
	- regulatory reportable incidents

Usage Notes:
	Run this script after 08_create_valid_reporting_view.sql
==============================================================================
*/

CREATE OR ALTER VIEW gold.vw_monthly_incident_summary AS 
SELECT
	DATETRUNC(MONTH, incident_date) AS incident_month,
	COUNT(*) AS incident_count,
	SUM(loss_amount) AS total_loss_amount,
	SUM(recovery_amount) AS total_recovery_amount,
	SUM(net_loss_amount) AS total_net_loss_amount,
	-- Open reporting includes both Open and Under Review records.
	SUM(CASE
			WHEN [status] IN ('Open', 'Under Review') THEN 1
			ELSE 0
		END) AS open_incident_count,
	SUM(CASE
			WHEN is_regulatory_reportable = 1 THEN 1
			ELSE 0 
		END) AS regulatory_reportable_count 
FROM silver.vw_valid_operational_risk_incidents
GROUP BY DATETRUNC(MONTH, incident_date);
GO

CREATE OR ALTER VIEW gold.vw_risk_category_summary AS
SELECT 
	risk_category,
	COUNT(incident_id) AS incident_count,
	SUM(net_loss_amount) AS total_net_loss_amount,
	AVG(net_loss_amount) AS avg_net_loss_amount,
	SUM(CASE
			WHEN severity IN ('High', 'Critical') THEN 1
			ELSE 0 
		END) AS high_or_critical_count,
	SUM(CASE
			WHEN is_regulatory_reportable = 1 THEN 1
			ELSE 0 
		END) AS regulatory_reportable_count
FROM silver.vw_valid_operational_risk_incidents
GROUP BY risk_category;
GO

CREATE OR ALTER VIEW gold.vw_open_incidents AS
SELECT 
	incident_id,
	reported_date,
	incident_date,
	DATEDIFF(DAY, incident_date, GETDATE()) AS days_open,
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
FROM silver.vw_valid_operational_risk_incidents
WHERE [status] IN ('Open', 'Under Review');
GO

CREATE OR ALTER VIEW gold.vw_regulatory_reportable_incidents AS
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
FROM silver.vw_valid_operational_risk_incidents
WHERE net_loss_amount >= 10000 OR severity IN ('High', 'Critical');
GO