# Window functions

Business questions: revenue pacing, product leadership, growth, demand smoothing, and customer tiers.

| Query | Technique | Sample output fields | Decision |
|---|---|---|---|
| Running revenue | framed SUM | day, daily_revenue, running_revenue | Track pacing without skipping zero days |
| Top products | RANK / DENSE_RANK / ROW_NUMBER | category, product, three ranks | Choose tie policy intentionally |
| MoM growth | LAG / LEAD | month_start, revenue, growth % | Spot trend changes |
| Demand | 7-row frame | product, day, average | Smooth replenishment signal |
| Segmentation | NTILE / PERCENT_RANK | spend, quartile, percentile | Size targeted audiences |

All financial queries use the canonical deduplicated order view.
