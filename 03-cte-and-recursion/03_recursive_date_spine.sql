/*
Business question: Which dates had zero completed revenue, distinguishing operational gaps from absent rows?
*/
WITH RECURSIVE spine(day) AS (
 VALUES (date '2023-07-01') UNION ALL SELECT day+1 FROM spine WHERE day<date '2026-06-30'
), daily AS (
 SELECT o.order_date AS day,sum(i.quantity*i.unit_price_at_sale) revenue
 FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) WHERE status='completed' GROUP BY 1
)
SELECT s.day,coalesce(d.revenue,0)::numeric(14,2) revenue,(d.day IS NULL) AS is_coverage_gap
FROM spine s LEFT JOIN daily d USING(day) ORDER BY s.day;
/*
So what: An explicit spine makes nine synthetic blackout dates visible as zero rather than disappearing from charts and averages.
*/
