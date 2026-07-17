/*
Business question: What is each product's seven-day unit-demand trend without daily noise?
*/
WITH RECURSIVE dates AS (
 SELECT min(order_date) AS day FROM vw_orders_deduplicated UNION ALL
 SELECT day+1 FROM dates WHERE day<(SELECT max(order_date) FROM vw_orders_deduplicated)
), grid AS (
 SELECT d.day,p.product_id FROM dates d CROSS JOIN products p
), demand AS (
 SELECT o.order_date AS day,i.product_id,sum(i.quantity) units FROM vw_orders_deduplicated o
 JOIN order_items i USING(order_id) WHERE o.status='completed' GROUP BY 1,2
)
SELECT g.day,g.product_id,coalesce(d.units,0) units,
 avg(coalesce(d.units,0)) OVER(PARTITION BY g.product_id ORDER BY g.day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)::numeric(10,2) demand_7d_avg
FROM grid g LEFT JOIN demand d USING(day,product_id) ORDER BY g.product_id,g.day;
/*
So what: Filling product-date gaps before the ROWS frame prevents a seven-row window from silently spanning more than seven days.
*/
