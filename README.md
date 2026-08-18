# UPI Transaction Analysis

### Data-Driven Risk & Performance Intelligence

A complete data analytics project analyzing **100,000 UPI transactions** across **7 relational tables** to understand transaction performance, fraud risk, failure patterns, device vulnerabilities, and operational efficiency.

## Project Overview

The analysis follows an end-to-end analytics workflow:

**Excel → MySQL → Python → Statistical Analysis → Power BI**

The project focuses on answering a practical question:

> **Where does risk actually live in a 100K-transaction UPI platform?**

## Key Findings

* **2.00% fraud rate** across 100,000 transactions.
* Rooted/jailbroken devices show a **20.69% fraud rate**, compared with **1.39%** for secure devices.
* Transaction failure rate is **5.87%**, with Incorrect PIN, Network Error, Account Blocked, and Bank Down as the main failure reasons.
* Fraud alert resolution averages **35.42 hours**, with **12.40% of alerts unresolved**.
* The current customer risk score shows **almost no correlation with actual fraud** (`r = -0.0016`).
* Statistical testing found **device root status to be the strongest significant fraud-related factor** among the variables tested.

## Data

The project uses 7 related tables:

| Table                       | Records |
| --------------------------- | ------: |
| `customer_master`           |  10,000 |
| `device_info`               |  12,000 |
| `upi_account_details`       |  12,000 |
| `merchant_info`             |     500 |
| `upi_transaction_history`   | 100,000 |
| `customer_feedback_surveys` |   4,000 |
| `fraud_alert_history`       |   2,000 |

The transaction dataset contains information covering customers, devices, merchants, payment channels, transaction status, fraud flags, reversals, and failure reasons.

## Analysis Performed

* Business understanding and KPI definition
* Excel-based data validation
* MySQL database design and ingestion
* Foreign-key and data-quality validation
* Python data extraction and transformation
* Exploratory data analysis
* Fraud and device-risk analysis
* Transaction failure analysis
* Outlier analysis
* Statistical hypothesis testing
* Customer and merchant segmentation
* Fraud alert SLA analysis
* Power BI executive dashboard
* Business recommendations

## Tools Used

**Excel · MySQL · Python · Pandas · NumPy · Matplotlib · Seaborn · SciPy · Statsmodels · Power BI**

## Business Recommendations

The analysis prioritizes:

1. Strengthening controls for rooted/jailbroken devices.
2. Rebuilding the risk-scoring approach using stronger fraud signals.
3. Improving fraud-alert resolution SLAs.
4. Addressing the major transaction failure reasons individually.
5. Planning infrastructure capacity around identified peak transaction windows.

## Outcome

The project combines **data validation, SQL analysis, Python analytics, statistical testing, and BI reporting** to turn UPI transaction data into actionable insights for fraud prevention, operational improvement, and platform performance.

---

**UPI Transaction Analysis | Data Analytics with GenAI Capstone Project**

