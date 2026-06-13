# 🏦 Operational Risk SQL Data Pipeline

This project simulates a small operational risk incident reporting workflow in a banking environment.

The goal is to load raw incident data into SQL Server, profile the source data, clean and standardize it, apply data quality checks, create a valid reporting layer, and prepare Gold views for business reporting.

---

## 🎯 Project Goal

The project is designed to demonstrate a practical SQL Server workflow for operational risk data:
- load raw CSV data before transformation
- profile raw data before transformation
- clean and standardize values into a Silver layer
- convert raw text values into correct data types
- identify data quality issues
- create a valid reporting view
- build Gold views for reporting
- answer business questions with final reporting queries

This project is inspired by real-world data analyst / risk data analyst tasks, where data quality, SQL, reporting logic, and business-rule validation are important.

--- 

## 🧱 Architecture

The project follows a Medallion-style architecture:

### Bronze Layer

The Bronze layer stores raw data from the CSV export.

All columns are loaded as `NVARCHAR` to preserve the original source values without applying business logic.

### Silver Layer

The Silver layer stores cleaned and typed data.

This layer applies:

- text trimming
- value standardization
- date conversion
- amount conversion
- `BIT` conversion
- normalization of status, severity, country, and risk category values

#### Data Quality Layer

Data quality checks identify records that may not be safe for reporting.

Business-rule issues are not automatically fixed, because the correct value cannot
always be safely derived without confirmation from a data owner.

### Gold Layer

The Gold layer contains reporting views built on top of valid cleaned data.

These views are intended for business reporting and analytical queries.

---

## ⚙️ Requirements

- SQL Server
- SQL Server Management Studio
- Local CSV file path configured in `02_proc_load_bronze.sql`

Note: This project uses `DATETRUNC`, which requires SQL Server 2022 or newer. 

---

## 📁 Repository Structure

```text
operational-risk-sql-data-pipeline/
│
├── dataset/
│   └── operational_risk_incidents_raw.csv
│
├── docs/
│   └── Medallion_Architecture_Overview.png
│
├── scripts/
│   ├── 00_init_database.sql
│   ├── 01_ddl_bronze.sql
│   ├── 02_proc_load_bronze.sql
│   ├── 03_data_profiling.sql
│   ├── 04_ddl_silver.sql
│   ├── 05_proc_load_silver.sql
│   ├── 06_silver_validation_checks.sql
│   ├── 07_data_quality_checks.sql
│   ├── 08_create_valid_reporting_view.sql
│   ├── 09_gold_reporting_views.sql
│   └── 10_reporting_queries.sql
└── README.md
```

---

## 🗂️ Dataset

The dataset contains simulated operational risk incidents.

Main columns include:

- `incident_id`
- `reported_date`
- `incident_date`
- `business_unit`
- `risk_category`
- `event_type`
- `loss_amount`
- `recovery_amount`
- `net_loss_amount`
- `currency`
- `status`
- `severity`
- `root_cause`
- `reported_by`
- `country`
- `is_regulatory_reportable`
- `description`

The raw dataset intentionally includes common data quality issues such as:

- duplicate rows
- duplicated `incident_id` values
- inconsistent casing
- trailing and leading spaces
- invalid dates
- mixed number formats
- missing values
- inconsistent category names
- business-rule violations

---

## ⚙️ How to Run the Project

Run these scripts in this order:

```text
00_init_database.sql
01_ddl_bronze.sql
02_proc_load_bronze.sql
03_data_profiling.sql
04_ddl_silver.sql
05_proc_load_silver.sql
06_silver_validation_checks.sql
07_data_quality_checks.sql
08_create_valid_reporting_view.sql
09_gold_reporting_views.sql
10_reporting_queries.sql
```

After creating the Bronze objects, update the CSV file path inside `02_proc_load_bronze.sql` before running the load procedure locally.

Example:

```sql
EXEC bronze.load_bronze;
EXEC silver.load_silver;
```

---

## 🧹 Silver Cleaning Logic

The Silver load procedure performs cleaning and standardization from the Bronze layer.

Examples of transformations:

```
"Closed " / "closed" / "CLOSED" -> "Closed"
"under review" / "In Review" -> "Under Review"
"CZ" / "Czech republic" -> "Czech Republic"
"Yes" / "Y" -> 1
"2 537,30" -> 2537.30
```
Raw values that cannot be safely converted are loaded as `NULL` and are later identified by validation or data quality checks.

---

## 🔍 Data Profiling

The profiling script checks the raw Bronze data before transformation.

It includes checks such as:

- total row count
- unique `incident_id` count
- duplicated `incident_id`
- missing `risk_category`
- missing `status`
- distinct status values
- distinct risk category values
- invalid date values
- invalid numeric values

This step helps understand source data issues before loading the Silver layer.

---

## ✅ Data Quality Checks

The data quality script checks business-rule issues after Silver cleaning.

Checks include:

- `incident_date > reported_date`
- `recovery_amount > loss_amount`
- invalid `net_loss_amount`
- missing `risk_category`
- missing `status`
- exact duplicate rows
- duplicate `incident_id`
- severity mismatch compared to `net_loss_amount`

Business-rule issues are not automatically fixed. They are identified and would require confirmation from a data owner in a real-world environment.

---

## 🛡️ Valid Reporting View

The project creates a valid reporting view:

`silver.vw_valid_operational_risk_incidents`

This view filters out records with critical data quality issues and serves as the trusted input for the Gold layer.

The purpose of this view is to separate:

```
cleaned data
from
reporting-safe data
```

---

## 🥇 Gold Reporting Views

The Gold layer contains reporting views for business users:

- `gold.vw_monthly_incident_summary`
- `gold.vw_risk_category_summary`
- `gold.vw_open_incidents`
- `gold.vw_regulatory_reportable_incidents`


These views support common operational risk reporting needs, such as:

- monthly incident summary
- loss amount by risk category
- open incidents
- regulatory reportable incidents

---

## 📊 Business Reporting Questions

The final reporting queries answer questions such as:

- What are the top 5 months by total net loss?
- What are the top 5 risk categories by total net loss?
- Which business units have the most incidents?
- Which open incidents are older than 30 days?
- How many regulatory reportable incidents are there by month?

---

## 🧠 Key SQL Concepts Used

This project demonstrates:

- SQL Server schemas
- stored procedures
- `BULK INSERT`
- CTEs
- `CASE`
- `TRY_CONVERT`
- `NULLIF`
- `TRIM`
- `REPLACE`
- `COALESCE`
- `DATETRUNC`
- `DATEDIFF`
- aggregate functions
- window functions
- data quality checks
- reporting views
- Bronze / Silver / Gold architecture

---

## 🧾 Project Summary

This project shows how raw operational risk data can be transformed into a trusted reporting layer using SQL.

It focuses not only on writing SQL queries, but also on data quality thinking:

- preserving raw source data
- cleaning only safe formatting issues
- identifying business-rule problems
- avoiding unsafe automatic corrections
- building reporting outputs on validated data

This approach reflects a realistic workflow for SQL, data quality, and reporting tasks in a risk data environment.

---

## 👤 Author

**Václav Benda**
