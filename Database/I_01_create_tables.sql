-- =============================================================================
-- Phase 3: Database Design and Table Creation (SQL DDL)
-- Project: UPI Transaction Analysis
-- Description:
--     Designs and structures the relational database schema. Defines primary keys,
--     foreign keys, constraints, and data types to ensure referential integrity.
-- =============================================================================

DROP DATABASE IF EXISTS upi_transactions;
CREATE DATABASE upi_transactions;
USE upi_transactions;

-- =============================================================================
-- 1. customer_master
-- Role: Core dimension table storing customer demographics and risk profiles.
-- =============================================================================
CREATE TABLE IF NOT EXISTS customer_master (
    customer_id VARCHAR(50) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    age INT,
    gender VARCHAR(20),
    region VARCHAR(50),
    date_joined DATE,
    is_business_user BOOLEAN,
    risk_score FLOAT CHECK (risk_score >= 0.0 AND risk_score <= 1.0),
    mobile_number VARCHAR(15) UNIQUE NOT NULL
);

-- =============================================================================
-- 2. merchant_info
-- Role: Dimension table for merchant details and their risk profiles.
-- =============================================================================
CREATE TABLE IF NOT EXISTS merchant_info (
    merchant_id VARCHAR(50) PRIMARY KEY,
    merchant_name VARCHAR(100) NOT NULL,
    merchant_type VARCHAR(50),
    region VARCHAR(50),
    onboard_date DATE,
    risk_score FLOAT CHECK (risk_score >= 0.0 AND risk_score <= 1.0)
);

-- =============================================================================
-- 3. device_info
-- Role: Dimension table tracking device hardware, OS, and security (root) status.
-- =============================================================================
CREATE TABLE IF NOT EXISTS device_info (
    device_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    device_type VARCHAR(50),
    app_version VARCHAR(20),
    is_rooted BOOLEAN,
    last_active DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customer_master(customer_id)
);

-- =============================================================================
-- 4. upi_account_details
-- Role: Dimension table linking banking instruments (UPI IDs) to customers.
-- =============================================================================
CREATE TABLE IF NOT EXISTS upi_account_details (
    upi_id VARCHAR(100) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    bank_name VARCHAR(100),
    account_type VARCHAR(50),
    date_added DATE,
    status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customer_master(customer_id)
);

-- =============================================================================
-- 5. customer_feedback_surveys
-- Role: Fact table for customer satisfaction and service issue tracking.
-- =============================================================================
CREATE TABLE IF NOT EXISTS customer_feedback_surveys (
    feedback_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    date_submitted DATE,
    feedback_text TEXT,
    satisfaction_score INT CHECK (satisfaction_score BETWEEN 1 AND 5),
    issue_type VARCHAR(50),
    resolved BOOLEAN,
    FOREIGN KEY (customer_id) REFERENCES customer_master(customer_id)
);

-- =============================================================================
-- 6. upi_transaction_history
-- Role: Core Fact table recording all transaction events, amounts, and statuses.
-- =============================================================================
CREATE TABLE IF NOT EXISTS upi_transaction_history (
    transaction_id VARCHAR(50) PRIMARY KEY,
    upi_id VARCHAR(100) NOT NULL,
    customer_id VARCHAR(50) NOT NULL,
    timestamp DATETIME NOT NULL,
    -- NOTE: FLOAT is used here matching the source CSV precision. For production
    -- systems handling real financial data, DECIMAL(12,2) is recommended to avoid
    -- floating-point rounding. Acceptable for this analytical dataset.
    amount FLOAT NOT NULL,
    transaction_type VARCHAR(50),
    merchant_id VARCHAR(50), -- Nullable for P2P transactions
    counterparty_upi VARCHAR(100),
    status VARCHAR(20),
    device_id VARCHAR(50) NOT NULL,
    device_type VARCHAR(50),
    channel VARCHAR(50),
    fraud_flag BOOLEAN,
    reversal_flag BOOLEAN,
    failure_reason VARCHAR(255),
    validation_status VARCHAR(50),
    FOREIGN KEY (upi_id) REFERENCES upi_account_details(upi_id),
    FOREIGN KEY (customer_id) REFERENCES customer_master(customer_id),
    FOREIGN KEY (merchant_id) REFERENCES merchant_info(merchant_id),
    FOREIGN KEY (device_id) REFERENCES device_info(device_id)
);

-- =============================================================================
-- 7. fraud_alert_history
-- Role: Fact table tracking triggered alerts and their resolution times.
-- =============================================================================
CREATE TABLE IF NOT EXISTS fraud_alert_history (
    alert_id VARCHAR(50) PRIMARY KEY,
    transaction_id VARCHAR(50) NOT NULL,
    alert_type VARCHAR(100),
    alert_date DATETIME NOT NULL,
    resolved BOOLEAN,
    resolution_date DATETIME,
    remarks VARCHAR(255),
    FOREIGN KEY (transaction_id) REFERENCES upi_transaction_history(transaction_id)
);
