-- =============================================================================
-- Phase 4: Business Analysis & KPI Reporting
-- Project: UPI Transaction Analysis
-- Description:
--     SQL queries designed to extract executive insights, monitor KPIs, and 
--     uncover business patterns across customers, merchants, devices, and fraud.
-- =============================================================================

USE upi_transactions;

-- =============================================================================
-- A. Customer Analysis
-- Insight: Understand demographics, geographic distribution, and risk profiles.
-- =============================================================================

-- 1. Customers by Region
SELECT
    region,
    COUNT(*) AS customers
FROM customer_master
GROUP BY region
ORDER BY customers DESC;

-- 2. Customers by Gender
SELECT
    gender,
    COUNT(*) AS total
FROM customer_master
GROUP BY gender;

-- 3. Business vs Personal Users
SELECT
    is_business_user,
    COUNT(*) AS total_users
FROM customer_master
GROUP BY is_business_user;

-- 4. Average Risk Score
SELECT
    ROUND(AVG(risk_score), 2) AS avg_risk
FROM customer_master;

-- 5. Top 10 Highest Risk Customers
SELECT
    customer_id,
    full_name,
    risk_score
FROM customer_master
ORDER BY risk_score DESC
LIMIT 10;

-- 6. Customer Age Distribution
SELECT
    CASE
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 40 THEN '25-40'
        WHEN age BETWEEN 41 AND 60 THEN '41-60'
        ELSE '60+'
    END AS age_group,
    COUNT(*) AS customers
FROM customer_master
GROUP BY age_group;

-- =============================================================================
-- B. Transaction Analysis
-- Insight: Monitor platform volume, success rates, and temporal trends.
-- =============================================================================

-- 7. Total Processed Transaction Value (Success only — excludes Failed/Pending)
SELECT
    ROUND(SUM(amount), 2) AS total_processed_value
FROM upi_transaction_history
WHERE status = 'success';

-- 7b. Total Attempted Transaction Volume (all statuses — for operational context)
SELECT
    ROUND(SUM(amount), 2) AS total_attempted_value
FROM upi_transaction_history;

-- 8. Average Successful Transaction Amount
SELECT
    ROUND(AVG(amount), 2) AS average_amount
FROM upi_transaction_history
WHERE status = 'success';

-- 9. Daily Transactions (Trend)
SELECT
    DATE(timestamp) AS transaction_date,
    COUNT(*) AS total_transactions
FROM upi_transaction_history
GROUP BY DATE(timestamp)
ORDER BY transaction_date;

-- 10. Transaction Status Distribution
SELECT
    status,
    COUNT(*) AS total
FROM upi_transaction_history
GROUP BY status;

-- 11. Platform Success Rate
SELECT
    ROUND(
        SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    ) AS success_rate
FROM upi_transaction_history;

-- 12. Transaction Type by Fraud (NEW: Identifies most exploited payment mode)
SELECT 
    transaction_type,
    SUM(CASE WHEN fraud_flag = TRUE THEN 1 ELSE 0 END) AS fraud_cases,
    COUNT(*) AS total_txns,
    ROUND(SUM(CASE WHEN fraud_flag = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_pct
FROM upi_transaction_history
GROUP BY transaction_type
ORDER BY fraud_pct DESC;

-- 13. Reversal Rate (NEW)
SELECT 
    ROUND(SUM(CASE WHEN reversal_flag = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS reversal_rate_pct
FROM upi_transaction_history;

-- 14. Channel Effectiveness (NEW)
SELECT 
    channel,
    COUNT(*) as volume,
    ROUND(SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS success_rate
FROM upi_transaction_history
GROUP BY channel
ORDER BY volume DESC;


-- =============================================================================
-- C. Merchant Analysis
-- Insight: Track merchant performance, risk concentrations, and top earners.
-- =============================================================================

-- 15. Number of Merchants by Type
SELECT
    merchant_type,
    COUNT(*) AS total_merchants
FROM merchant_info
GROUP BY merchant_type
ORDER BY total_merchants DESC;

-- 16. Top 10 Merchants by Revenue
SELECT
    m.merchant_name,
    ROUND(SUM(t.amount), 2) AS total_revenue
FROM merchant_info m
JOIN upi_transaction_history t ON m.merchant_id = t.merchant_id
WHERE t.status = 'success'
GROUP BY m.merchant_name
ORDER BY total_revenue DESC
LIMIT 10;

-- 17. High-Risk Merchants
SELECT
    merchant_name,
    risk_score
FROM merchant_info
ORDER BY risk_score DESC
LIMIT 10;

-- 18. Merchant Success Rate
SELECT
    m.merchant_name,
    ROUND(SUM(CASE WHEN t.status = 'success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS success_rate
FROM merchant_info m
JOIN upi_transaction_history t ON m.merchant_id = t.merchant_id
GROUP BY m.merchant_name
ORDER BY success_rate DESC
LIMIT 10;

-- =============================================================================
-- D. Device Analysis
-- Insight: Identify hardware vulnerabilities, OS adoption, and usage behaviors.
-- =============================================================================

-- 19. Rooted vs Non-Rooted Devices
SELECT
    is_rooted,
    COUNT(*) AS total
FROM device_info
GROUP BY is_rooted;

-- 20. Fraud by Device Type
SELECT
    device_type,
    COUNT(*) AS fraud_transactions
FROM upi_transaction_history
WHERE fraud_flag = TRUE
GROUP BY device_type;

-- 21. Device Success Rate
SELECT
    device_type,
    ROUND(SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS success_rate
FROM upi_transaction_history
GROUP BY device_type;

-- 22. App Version Distribution
SELECT
    app_version,
    COUNT(*) AS users
FROM device_info
GROUP BY app_version
ORDER BY users DESC;

-- =============================================================================
-- E. Fraud & Feedback Analysis
-- Insight: Deep dive into anomalous activities and customer sentiment.
-- =============================================================================

-- 23. Overall Fraud Rate
SELECT
    ROUND(SUM(CASE WHEN fraud_flag = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate
FROM upi_transaction_history;

-- 24. Fraud by Region
SELECT
    c.region,
    COUNT(*) AS fraud_cases
FROM upi_transaction_history t
JOIN customer_master c ON t.customer_id = c.customer_id
WHERE fraud_flag = TRUE
GROUP BY c.region
ORDER BY fraud_cases DESC;

-- 25. Average Resolution Time (Hours)
SELECT
    ROUND(AVG(TIMESTAMPDIFF(HOUR, alert_date, resolution_date)), 2) AS avg_resolution_hours
FROM fraud_alert_history
WHERE resolved = TRUE;

-- 26. Most Common Unresolved Issues
SELECT
    issue_type,
    COUNT(*) AS pending_issues
FROM customer_feedback_surveys
WHERE resolved = FALSE
GROUP BY issue_type
ORDER BY pending_issues DESC;

-- 27. Fraud Detection Rate (Guideline: "How effective are risk controls and fraud alerts?")
--     Measures what % of actual fraud-flagged transactions were detected by the alert system.
SELECT
    ROUND(COUNT(DISTINCT f.transaction_id) * 100.0
        / NULLIF(SUM(CASE WHEN t.fraud_flag = TRUE THEN 1 ELSE 0 END), 0), 2) AS fraud_detection_rate_pct
FROM upi_transaction_history t
LEFT JOIN fraud_alert_history f
    ON t.transaction_id = f.transaction_id AND t.fraud_flag = TRUE;


-- =============================================================================
-- F. Advanced Analytics (Window Functions)
-- Insight: Ranked and comparative analytics for portfolio depth.
-- =============================================================================

-- 28. Top 3 Merchants by Revenue per Region (RANK window function)
SELECT *
FROM (
    SELECT
        m.region,
        m.merchant_name,
        ROUND(SUM(t.amount), 2) AS total_revenue,
        RANK() OVER (PARTITION BY m.region ORDER BY SUM(t.amount) DESC) AS region_rank
    FROM merchant_info m
    JOIN upi_transaction_history t ON m.merchant_id = t.merchant_id
    WHERE t.status = 'success'
    GROUP BY m.region, m.merchant_name
) ranked
WHERE region_rank <= 3
ORDER BY region, region_rank;

-- 29. Month-over-Month Fraud Rate Change (LAG window function)
SELECT
    txn_month,
    fraud_rate_pct,
    LAG(fraud_rate_pct) OVER (ORDER BY txn_month) AS prev_month_fraud_rate,
    ROUND(fraud_rate_pct - LAG(fraud_rate_pct) OVER (ORDER BY txn_month), 2) AS mom_change
FROM (
    SELECT
        DATE_FORMAT(timestamp, '%Y-%m') AS txn_month,
        ROUND(SUM(CASE WHEN fraud_flag = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
    FROM upi_transaction_history
    GROUP BY DATE_FORMAT(timestamp, '%Y-%m')
) monthly
ORDER BY txn_month;
