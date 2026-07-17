# MetroMart Retail Analytics Engine

> Advanced PostgreSQL portfolio capstone: 200K logical omnichannel orders, deliberately messy source data, and a complete SQL analytics layer.

## Headline result

**3,895× faster:** a measured order-value query improved from **13,560.194 ms to 3.481 ms** using a covering B-tree index and a dedup-access index on 200,800 raw headers / 340,366 line items.

## Why this project exists

MetroMart is a fictional online + store retailer. Python creates deterministic source data; PostgreSQL performs cleaning, modeling, analysis, optimization, and reporting. Each analytical SQL file begins with a business question and ends with a decision-focused interpretation.

## Jump directly to a SQL concept

| Interview topic | Folder | What is demonstrated |
|---|---|---|
| Data model + messy generation | [01-data-generation](01-data-generation) | SCD2, duplicate identities/orders, gaps, mismatched systems |
| Window functions | [02-window-functions](02-window-functions) | framed SUM, ranks, LAG/LEAD, moving average, NTILE |
| Recursive CTEs | [03-cte-and-recursion](03-cte-and-recursion) | hierarchy traversal and date spine |
| Advanced joins | [04-advanced-joins](04-advanced-joins) | self, FULL OUTER, anti, LATERAL |
| Subqueries + set operations | [05-subqueries-and-set-ops](05-subqueries-and-set-ops) | correlated, EXISTS/IN/JOIN, UNION/INTERSECT/EXCEPT |
| Pivot/unpivot | [06-pivoting-and-reshaping](06-pivoting-and-reshaping) | FILTER, tablefunc crosstab, LATERAL VALUES |
| Cohort + LTV | [07-cohort-and-retention](07-cohort-and-retention) | pure-SQL retention and realized LTV |
| Query optimization | [08-query-optimization](08-query-optimization) | actual plans, covering/composite/partial indexes |
| Views + procedures | [09-views-and-procedures](09-views-and-procedures) | views, MV refresh, function, audit trigger |
| Advanced aggregation | [10-advanced-aggregation](10-advanced-aggregation) | GROUPING SETS, ROLLUP, CUBE, FILTER |
| Data quality | [11-data-quality](11-data-quality) | dedup, SCD2 as-of, null semantics |
| Executive capstone | [12-capstone-executive-report](12-capstone-executive-report) | board pipeline + design judgment |
| Live SQL dashboard | [13-dashboard](13-dashboard) | parameterized queries against PostgreSQL |

## Reproducible setup

Prerequisites: Docker Desktop and Python 3.11+.

~~~bash
cd metromart-sql-capstone
python -m venv .venv
# Windows: .venv\Scripts\activate
pip install faker numpy psycopg2-binary
python 01-data-generation/generate_data.py
docker compose -f 01-data-generation/docker-compose.yml up -d
python 01-data-generation/load_to_db.py
~~~

Dashboard:

~~~bash
pip install -r 13-dashboard/requirements.txt
streamlit run 13-dashboard/app.py
~~~

For Streamlit Community Cloud, add one secret under **Advanced settings**:

~~~toml
DATABASE_URL = "postgresql://USER:PASSWORD@HOST/DATABASE"
~~~

The dashboard requires SSL and connects directly to that hosted PostgreSQL database.

## Deliberate source-system problems

The seeded generator produces 12,240 CRM rows including 240 near-duplicate identities; 200,800 raw order headers including 800 exact double-inserts; 340,366 items; nine guaranteed no-order dates; SCD2 moves with a small number of history gaps; unequal online/store inventory coverage; and overlapping email/SMS lists. See [data_quality_report.json](01-data-generation/data_quality_report.json).

## Assumptions

- Fixed analysis window: 2023-07-01 through 2026-06-30.
- Four regions: North, South, East, West; 20 stores.
- Completed orders recognize revenue; returned value is reported separately; cancelled orders contribute no revenue.
- SCD2 intervals are half-open: effective date inclusive, end date exclusive.
- Raw source duplicates are retained; analytical metrics use the canonical deduplicated view.

## Resume-ready summary

- Built a PostgreSQL retail analytics engine over 200K orders and 340K line items, applying advanced windows, recursive CTEs, LATERAL joins, cohort analysis, GROUPING SETS, procedures, triggers, and materialized views.
- Designed data-quality controls for duplicate ingestion, customer identity variation, SCD Type 2 history, missing dates, cross-system inventory gaps, and marketing-list reconciliation.
- Reduced measured correlated-query runtime from 13.56 seconds to 3.48 milliseconds (3,895×) through plan-led covering, composite, and partial indexing.
- Delivered a parameterized Streamlit interface that executes PostgreSQL queries live.

## Measurement note

Optimization plans were captured locally on PostgreSQL 18.4. Docker pins PostgreSQL 16 for reproducibility; exact timings vary with hardware and cache, but the included EXPLAIN ANALYZE files make comparison repeatable.
