# SQL design tradeoffs

## Windows versus correlated subqueries

Windows fit month-over-month growth because adjacent periods already exist in one result set. The selective optimization exercise shows the exception: after a covering index, 1,000 correlated lookups ran in 3.481 ms versus 5.353 ms for a window query that expanded and deduplicated lines. Set based is a principle, not a substitute for reading the plan.

## View versus materialized view

The customer summary is a regular view because status updates should appear immediately. Daily product performance is materialized because it repeatedly scans hundreds of thousands of lines while overnight freshness is acceptable. A unique index enables concurrent refresh.

## GROUPING SETS, ROLLUP, and CUBE

The executive query uses explicit GROUPING SETS because the board needs a known set of totals. ROLLUP implies hierarchy and omits region-only totals. CUBE creates every combination and can add costly unused rows.

## EXISTS, IN, and JOIN

EXISTS communicates membership intent and can stop at the first match. PostgreSQL commonly decorrelates EXISTS and IN into semi-joins. JOIN may multiply customer rows and require DISTINCT. Plans, cardinality, and null behavior decide.

## Raw versus canonical orders

Raw orders accept duplicate business IDs, so they use a surrogate ingestion key. Financial queries use the deduplicated view. Since an item cannot reference a deliberately non-unique header key, the transactional loader performs an orphan check and rolls back on failure.
