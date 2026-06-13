/*
========================================================================
				    	10_reporting_queries.sql
========================================================================
Script Purpose:
	Contains final business reporting queries built on top of the Gold layer
	and the valid Silver reporting view.
	
	Reporting questions covered:
	- Top 5 months by total net loss amount
	- Top 5 risk categories by total net loss amount
	- Business units with the highest number of incidents
	- Open incidents older than 30 days
	- Regulatory reportable incidents by month

Usage Notes:
	Run this script after 09_gold_reporting_views.sql.
========================================================================
*/

-- 1. Top 5 months by total_net_loss_amount.
WITH rank_CTE AS (
SELECT 
	incident_month,
	incident_count,
	total_loss_amount,
	total_recovery_amount,
	total_net_loss_amount,
	open_incident_count,
	regulatory_reportable_count,
	ROW_NUMBER() OVER(ORDER BY total_net_loss_amount DESC) AS ranking
FROM gold.vw_monthly_incident_summary
)
SELECT 	
	incident_month,
	incident_count,
	total_loss_amount,
	total_recovery_amount,
	total_net_loss_amount,
	open_incident_count,
	regulatory_reportable_count
FROM rank_CTE
WHERE ranking <= 5
ORDER BY total_net_loss_amount DESC;

-- 2. Top 5 risk categories by total_net_loss_amount.
SELECT TOP 5
	risk_category,
	incident_count,
	total_net_loss_amount,
	avg_net_loss_amount,
	high_or_critical_count,
	regulatory_reportable_count
FROM gold.vw_risk_category_summary
ORDER BY total_net_loss_amount DESC;

-- 3. Business units with most incidents.
WITH rank_CTE AS (
SELECT 	
	business_unit,
	COUNT(*) AS total_incident_count,
	ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) AS ranking
FROM silver.vw_valid_operational_risk_incidents
WHERE business_unit IS NOT NULL
GROUP BY business_unit
)
SELECT 
	business_unit,
	total_incident_count
FROM rank_CTE
WHERE ranking <= 5
ORDER BY total_incident_count DESC;

-- 4. Open incidents older than 30 days.
SELECT 
	* 
FROM gold.vw_open_incidents
WHERE days_open > 30
ORDER BY days_open DESC;

-- 5. Count of regulatory reportable incidents by month.
SELECT
	incident_month,
	regulatory_reportable_count
FROM gold.vw_monthly_incident_summary
ORDER BY regulatory_reportable_count DESC;
