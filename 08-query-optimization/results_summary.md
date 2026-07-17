# Measured optimization results

Captured locally on PostgreSQL 18.4 with 200,800 raw order rows and 340,366 order-item rows.

| Variant | Execution time | Plan behavior | Relative |
|---|---:|---|---:|
| Correlated baseline, no indexes | 13,560.194 ms | 1,000 sequential scans of 340K items | 1.0x |
| Same query, covering + dedup indexes | 3.481 ms | bitmap lookup + index-only probes | 3,895x faster |
| Window rewrite, indexed | 5.353 ms | line expansion + WindowAgg + Unique | 2,533x faster |

The covering order-item index works because the lookup key and calculation columns are present, producing zero heap fetches. The partial customer/date index is limited to completed orders, shrinking a common reporting index. Timings are hardware/cache-specific; re-run the included EXPLAIN ANALYZE statements.
