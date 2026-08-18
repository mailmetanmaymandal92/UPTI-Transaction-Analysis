-- =============================================================================
-- Phase 3: Data Ingestion (SQL Alternative)
-- Project: UPI Transaction Analysis
-- Description:
--     This script provides a native SQL method for importing the raw CSV files
--     into the MySQL database. It uses LOAD DATA LOCAL INFILE, which is often
--     faster than Python for bulk inserts.
--
-- Instructions:
--     1. Ensure your MySQL server allows local infile (SET GLOBAL local_infile=1;)
--     2. IMPORTANT: Do a FIND AND REPLACE (Ctrl+H) in your SQL editor.
--        Find: [YOUR_PATH_HERE]
--        Replace with your actual folder path (e.g. C:/Data/). MUST use forward slashes /
--     3. Execute this script AFTER running 01_create_tables.sql
-- =============================================================================

USE upi_transactions;

-- Enable local infile for this session
SET GLOBAL local_infile = 1;

-- 1. customer_master
LOAD DATA LOCAL INFILE '[YOUR_PATH_HERE]/customer_master.csv'
INTO TABLE customer_master
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, full_name, age, gender, region, @date_joined, is_business_user, risk_score, mobile_number)
SET date_joined = STR_TO_DATE(@date_joined, '%Y-%m-%d'); -- Adjust format string if DD-MM-YYYY

-- 2. merchant_info
LOAD DATA LOCAL INFILE '[YOUR_PATH_HERE]/merchant_info.csv'
INTO TABLE merchant_info
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(merchant_id, merchant_name, merchant_type, region, @onboard_date, risk_score)
SET onboard_date = STR_TO_DATE(@onboard_date, '%Y-%m-%d');

-- 3. device_info
LOAD DATA LOCAL INFILE '[YOUR_PATH_HERE]/device_info.csv'
INTO TABLE device_info
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(device_id, customer_id, device_type, app_version, is_rooted, @last_active)
SET last_active = STR_TO_DATE(@last_active, '%Y-%m-%d %H:%i:%s');

-- 4. upi_account_details
LOAD DATA LOCAL INFILE '[YOUR_PATH_HERE]/upi_account_details.csv'
INTO TABLE upi_account_details
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(upi_id, customer_id, bank_name, account_type, @date_added, status)
SET date_added = STR_TO_DATE(@date_added, '%Y-%m-%d');

-- 5. customer_feedback_surveys
LOAD DATA LOCAL INFILE '[YOUR_PATH_HERE]/customer_feedback_surveys.csv'
INTO TABLE customer_feedback_surveys
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(feedback_id, customer_id, @date_submitted, feedback_text, satisfaction_score, issue_type, resolved)
SET date_submitted = STR_TO_DATE(@date_submitted, '%Y-%m-%d');

-- 6. upi_transaction_history
LOAD DATA LOCAL INFILE '[YOUR_PATH_HERE]/upi_transaction_history.csv'
INTO TABLE upi_transaction_history
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(transaction_id, upi_id, customer_id, @timestamp, amount, transaction_type, merchant_id, counterparty_upi, status, device_id, device_type, channel, fraud_flag, reversal_flag, failure_reason)
SET timestamp = STR_TO_DATE(@timestamp, '%Y-%m-%d %H:%i:%s');

-- 7. fraud_alert_history
LOAD DATA LOCAL INFILE '[YOUR_PATH_HERE]/fraud_alert_history.csv'
INTO TABLE fraud_alert_history
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(alert_id, transaction_id, alert_type, @alert_date, resolved, @resolution_date, remarks)
SET alert_date = STR_TO_DATE(@alert_date, '%Y-%m-%d %H:%i:%s'),
    resolution_date = STR_TO_DATE(@resolution_date, '%Y-%m-%d %H:%i:%s');

-- Validation Output
SELECT 'Ingestion Complete' AS Status;
