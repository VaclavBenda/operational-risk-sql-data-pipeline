/*
================================================================================
                            07_data_quality_checks.sql
================================================================================
Script Purpose:
    Identifies data quality issues in the Silver layer.

    Checks included:
    - incidents where incident_date is later than reported_date
    - incidents where recovery_amount exceeds loss_amount
    - incidents where net_loss_amount does not match loss_amount - recovery_amount
    - missing risk category or status
    - exact duplicate rows
    - duplicate incident_id values
    - severity mismatch compared to net_loss_amount

Business Logic Note:
    Formatting issues were fixed in the Silver layer. Business-rule issues are not
    automatically fixed because the correct value cannot be safely derived without
    confirmation from the data owner.

Usage Notes:
    - Run this script after loading data into the Silver layer.
================================================================================
*/

-- 1. Incidents where incident_date is later than reported_date.
SELECT * 
FROM silver.operational_risk_incidents
WHERE reported_date IS NOT NULL
 AND incident_date IS NOT NULL
 AND incident_date > reported_date;

-- 2. Incidents where recovery_amount is greater than loss_amount.
SELECT * 
FROM silver.operational_risk_incidents
WHERE recovery_amount IS NOT NULL
 AND loss_amount IS NOT NULL
 AND recovery_amount > loss_amount;

-- 3. Incidents where net_loss_amount does not equal loss_amount - recovery_amount.
SELECT * 
FROM silver.operational_risk_incidents
WHERE net_loss_amount IS NOT NULL
 AND recovery_amount IS NOT NULL
 AND loss_amount IS NOT NULL
 AND ABS(net_loss_amount - (loss_amount - recovery_amount)) > 0.01;

-- 4. Incidents with missing risk_category.
SELECT * 
FROM silver.operational_risk_incidents
WHERE risk_category IS NULL;

-- 5. Incidents with missing status.
SELECT * 
FROM silver.operational_risk_incidents
WHERE [status] IS NULL;

-- 6. Exact duplicate rows.
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
    [description], 
    COUNT(*) AS duplicate_count FROM silver.operational_risk_incidents
GROUP BY 
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
HAVING COUNT(*) > 1
ORDER BY incident_id;


-- 7. Duplicate incident_id values. These may represent conflicting records.
SELECT 
    incident_id, 
    COUNT(*) AS duplicate_count 
FROM silver.operational_risk_incidents
GROUP BY incident_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, incident_id;

-- 8. Severity mismatch compared to net_loss_amount.
WITH severity_check AS (
    SELECT
        incident_id,
        net_loss_amount,
        severity,
        CASE 
            WHEN net_loss_amount < 1000 THEN 'Low'
            WHEN net_loss_amount >= 1000 AND net_loss_amount < 10000 THEN 'Medium'
            WHEN net_loss_amount >= 10000 AND net_loss_amount < 50000 THEN 'High'
            WHEN net_loss_amount >= 50000 THEN 'Critical'
            ELSE NULL
        END AS calculated_severity
    FROM silver.operational_risk_incidents
)
SELECT * 
FROM severity_check
WHERE net_loss_amount IS NULL
 OR severity IS NULL
 OR severity != calculated_severity;
