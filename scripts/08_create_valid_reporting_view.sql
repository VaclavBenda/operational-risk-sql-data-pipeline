/*
================================================================================
                        08_create_valid_reporting_view.sql
================================================================================
Script Purpose:
	Creates a valid reporting view based on cleaned Silver data.

	The view excludes records with critical data quality issues:
	- missing dates
	- incident_date later than reported_date
	- missing risk_category or status
	- missing amount values
	- recovery_amount greater than loss_amount
	- invalid net_loss_amount calculation
	- duplicate incident_id values
	- invalid severity compared to net_loss_amount

Usage Notes:
    Gold reporting views should be built from this view rather than directly from
    silver.operational_risk_incidents.
================================================================================
*/

CREATE OR ALTER VIEW silver.vw_valid_operational_risk_incidents AS
WITH validity_check AS (
    SELECT
        *,
        CASE 
            WHEN net_loss_amount < 1000 THEN 'Low'
            WHEN net_loss_amount >= 1000 AND net_loss_amount < 10000 THEN 'Medium'
            WHEN net_loss_amount >= 10000 AND net_loss_amount < 50000 THEN 'High'
            WHEN net_loss_amount >= 50000 THEN 'Critical'
            ELSE NULL
        END AS calculated_severity
    FROM silver.operational_risk_incidents

), duplicated_incident_id AS (
    SELECT
        incident_id
    FROM silver.operational_risk_incidents
    WHERE incident_id IS NOT NULL
    GROUP BY incident_id
    HAVING COUNT(*) > 1
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
FROM validity_check
WHERE incident_id IS NOT NULL 
 AND incident_id NOT IN (SELECT incident_id FROM duplicated_incident_id)
 AND reported_date IS NOT NULL
 AND incident_date IS NOT NULL
 AND incident_date <= reported_date
 AND risk_category IS NOT NULL
 AND [status] IS NOT NULL
 AND loss_amount IS NOT NULL
 AND recovery_amount IS NOT NULL
 AND net_loss_amount IS NOT NULL
 AND recovery_amount <= loss_amount
 AND ABS(net_loss_amount - (loss_amount - recovery_amount)) <= 0.01
 AND severity IS NOT NULL
 AND severity = calculated_severity;

