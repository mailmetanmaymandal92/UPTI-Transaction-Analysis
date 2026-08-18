-- =============================================================================
-- Phase 2.5: Comprehensive Data Validation & Cleansing
-- Project: UPI Transaction Analysis
-- Description:
--     A thorough SQL-based validation suite replicating the Excel audit checks.
--     Verifies referential integrity, structural constraints, data types, 
--     and temporal logic. Concludes by updating the validation_status flag.
-- =============================================================================

USE upi_transactions;

-- =============================================================================
-- 1. Row Count Validations
-- =============================================================================
SELECT 'customer_master' AS Table_Name, COUNT(*) AS Row_Count FROM customer_master
UNION ALL SELECT 'device_info', COUNT(*) FROM device_info
UNION ALL SELECT 'merchant_info', COUNT(*) FROM merchant_info
UNION ALL SELECT 'upi_account_details', COUNT(*) FROM upi_account_details
UNION ALL SELECT 'upi_transaction_history', COUNT(*) FROM upi_transaction_history
UNION ALL SELECT 'customer_feedback_surveys', COUNT(*) FROM customer_feedback_surveys
UNION ALL SELECT 'fraud_alert_history', COUNT(*) FROM fraud_alert_history;


-- =============================================================================
-- 2. Primary Key Uniqueness Checks (Should return 0)
-- =============================================================================
SELECT 'Duplicate Customer IDs' AS Issue, COUNT(*) FROM (SELECT customer_id FROM customer_master GROUP BY customer_id HAVING COUNT(*) > 1) t
UNION ALL SELECT 'Duplicate Device IDs', COUNT(*) FROM (SELECT device_id FROM device_info GROUP BY device_id HAVING COUNT(*) > 1) t
UNION ALL SELECT 'Duplicate Merchant IDs', COUNT(*) FROM (SELECT merchant_id FROM merchant_info GROUP BY merchant_id HAVING COUNT(*) > 1) t
UNION ALL SELECT 'Duplicate UPI IDs', COUNT(*) FROM (SELECT upi_id FROM upi_account_details GROUP BY upi_id HAVING COUNT(*) > 1) t
UNION ALL SELECT 'Duplicate Transaction IDs', COUNT(*) FROM (SELECT transaction_id FROM upi_transaction_history GROUP BY transaction_id HAVING COUNT(*) > 1) t;


-- =============================================================================
-- 3. Foreign Key Orphan Checks (Should return 0)
-- =============================================================================
SELECT 'Orphan Devices (No Customer)' AS Relationship, COUNT(*) AS Orphan_Count
FROM device_info d LEFT JOIN customer_master c ON d.customer_id = c.customer_id WHERE c.customer_id IS NULL
UNION ALL
SELECT 'Orphan UPI Accounts (No Customer)', COUNT(*)
FROM upi_account_details u LEFT JOIN customer_master c ON u.customer_id = c.customer_id WHERE c.customer_id IS NULL
UNION ALL
SELECT 'Orphan Transactions (No UPI ID)', COUNT(*)
FROM upi_transaction_history t LEFT JOIN upi_account_details u ON t.upi_id = u.upi_id WHERE u.upi_id IS NULL
UNION ALL
SELECT 'Orphan Transactions (No Customer)', COUNT(*)
FROM upi_transaction_history t LEFT JOIN customer_master c ON t.customer_id = c.customer_id WHERE c.customer_id IS NULL
UNION ALL
SELECT 'Orphan Transactions (No Merchant)', COUNT(*)
FROM upi_transaction_history t LEFT JOIN merchant_info m ON t.merchant_id = m.merchant_id WHERE t.merchant_id IS NOT NULL AND m.merchant_id IS NULL
UNION ALL
SELECT 'Orphan Transactions (No Device)', COUNT(*)
FROM upi_transaction_history t LEFT JOIN device_info d ON t.device_id = d.device_id WHERE d.device_id IS NULL
UNION ALL
SELECT 'Orphan Feedback (No Customer)', COUNT(*)
FROM customer_feedback_surveys f LEFT JOIN customer_master c ON f.customer_id = c.customer_id WHERE c.customer_id IS NULL
UNION ALL
SELECT 'Orphan Fraud Alerts (No Transaction)', COUNT(*)
FROM fraud_alert_history f LEFT JOIN upi_transaction_history t ON f.transaction_id = t.transaction_id WHERE t.transaction_id IS NULL;


-- =============================================================================
-- 4. Categorical & Range Audits
-- =============================================================================
-- Status validity check (reference listing)
SELECT status, COUNT(*) AS Occurrences FROM upi_transaction_history GROUP BY status;

-- Status validity — automated pass/fail (returns 0 rows if clean)
SELECT status AS Invalid_Status, COUNT(*) AS Occurrences 
FROM upi_transaction_history 
WHERE status NOT IN ('success', 'failed', 'pending') 
GROUP BY status;

-- Device type validity check (reference listing)
SELECT device_type, COUNT(*) AS Occurrences FROM device_info GROUP BY device_type;

-- Device type validity — automated pass/fail (returns 0 rows if clean)
SELECT device_type AS Invalid_Device_Type, COUNT(*) AS Occurrences 
FROM device_info 
WHERE device_type NOT IN ('android', 'ios', 'feature_phone') 
GROUP BY device_type;

-- Risk score bounds check (Should be 0 if clean)
SELECT COUNT(*) AS Out_Of_Bounds_Risk FROM customer_master WHERE risk_score < 0.0 OR risk_score > 1.0;


-- =============================================================================
-- 5. Temporal Anomaly Check
-- Finds P2M transactions that occurred before the merchant was officially onboarded.
-- =============================================================================
SELECT 
    COUNT(*) AS Temporal_Anomalies 
FROM upi_transaction_history t
JOIN merchant_info m ON t.merchant_id = m.merchant_id
WHERE t.timestamp < m.onboard_date;


-- =============================================================================
-- 6. Final PDF Requirement: Set Validation Status Flag
--    Tags rows needing manual review based on ALL integrity checks:
--    - Temporal anomaly (transaction before merchant onboarding)
--    - Foreign key orphans (missing device, customer, or UPI account)
--    This matches the full scope described in the Excel workbook's validation
--    formula, ensuring both systems flag the same rows.
-- =============================================================================
-- Temporarily disable safe updates to allow full-table flag modification
SET SQL_SAFE_UPDATES = 0;

UPDATE upi_transaction_history t
LEFT JOIN merchant_info m ON t.merchant_id = m.merchant_id
LEFT JOIN device_info d ON t.device_id = d.device_id
LEFT JOIN customer_master c ON t.customer_id = c.customer_id
LEFT JOIN upi_account_details u ON t.upi_id = u.upi_id
SET t.validation_status = CASE
    WHEN (t.merchant_id IS NOT NULL AND t.timestamp < m.onboard_date) THEN 'Needs Review'  -- Temporal anomaly
    WHEN d.device_id IS NULL THEN 'Needs Review'   -- FK orphan: device
    WHEN c.customer_id IS NULL THEN 'Needs Review'  -- FK orphan: customer
    WHEN u.upi_id IS NULL THEN 'Needs Review'       -- FK orphan: UPI account
    ELSE 'Valid'
END;

-- Re-enable safe updates
SET SQL_SAFE_UPDATES = 1;

-- View the result distribution
SELECT 
    validation_status, 
    COUNT(*) AS total_rows 
FROM upi_transaction_history 
GROUP BY validation_status;
