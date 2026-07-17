/*
Business question: How is completed daily revenue accumulating through time, including days with no sales?
*/
WITH RECURSIVE spine AS (
  SELECT min(order_date) AS day FROM vw_orders_deduplicated
  UNION ALL SELECT day + 1 FROM spine WHERE day < (SELECT max(order_date) FROM vw_orders_deduplicated)
), daily AS (
  SELECT o.order_date AS day, sum(i.quantity*i.unit_price_at_sale) AS revenue
  FROM vw_orders_deduplicated o JOIN order_items i USING(order_id)
  WHERE o.status='completed' GROUP BY 1
)
SELECT s.day, coalesce(d.revenue,0)::numeric(14,2) AS daily_revenue,
       sum(coalesce(d.revenue,0)) OVER (ORDER BY s.day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)::numeric(16,2) AS running_revenue
FROM spine s LEFT JOIN daily d USING(day) ORDER BY s.day;
/*
So what: A gap-safe running total separates true zero-sales days from missing reporting rows and supports pacing decisions.
*/
