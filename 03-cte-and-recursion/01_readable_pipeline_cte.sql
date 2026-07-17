/*
Business question: Which category-region combinations have strong revenue, low returns, and enough order volume to act on?
*/
WITH canonical_orders AS (
 SELECT * FROM vw_orders_deduplicated WHERE order_date>=current_date-interval '12 months'
), order_value AS (
 SELECT o.order_id,o.region,o.status,p.category,sum(i.quantity*i.unit_price_at_sale) revenue
 FROM canonical_orders o JOIN order_items i USING(order_id) JOIN products p USING(product_id) GROUP BY 1,2,3,4
), metrics AS (
 SELECT region,category,count(DISTINCT order_id) orders,sum(revenue) FILTER(WHERE status='completed') revenue,
 count(DISTINCT order_id) FILTER(WHERE status='returned') returns FROM order_value GROUP BY 1,2
)
SELECT *,round(100.0*returns/nullif(orders,0),2) return_rate_pct FROM metrics
WHERE orders>=100 ORDER BY revenue DESC;
/*
So what: Named CTE stages expose grain changes and business filters, making review safer than deeply nested anonymous subqueries.
*/
