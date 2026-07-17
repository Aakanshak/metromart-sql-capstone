/*
Business question: How can repeated expensive daily product aggregation be served quickly with controlled freshness?
*/
DROP MATERIALIZED VIEW IF EXISTS mv_daily_product_performance;
CREATE MATERIALIZED VIEW mv_daily_product_performance AS
SELECT o.order_date,p.product_id,p.product_name,p.category,o.region,
 count(DISTINCT o.order_id) orders,sum(i.quantity) units,
 sum(i.quantity*i.unit_price_at_sale)::numeric(16,2) revenue
FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) JOIN products p USING(product_id)
WHERE o.status='completed' GROUP BY 1,2,3,4,5;
CREATE UNIQUE INDEX ux_mv_daily_product_performance ON mv_daily_product_performance(order_date,product_id,region);
-- Production strategy: REFRESH MATERIALIZED VIEW CONCURRENTLY after nightly ingestion; plain REFRESH only for initial/backfill loads.
/*
So what: Pre-aggregation trades controlled overnight staleness for predictable dashboard latency; a regular view remains preferable for real-time status.
*/
