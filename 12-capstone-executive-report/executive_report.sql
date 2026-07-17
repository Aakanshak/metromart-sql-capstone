/*
Business question: What board-ready monthly/category/region view combines revenue, quality, top products, subtotals, and retention?
Techniques: layered CTEs, FILTER, window functions, GROUPING SETS, and safe ratios.
*/
WITH line_fact AS (
 SELECT date_trunc('month',o.order_date)::date month_start,o.region,p.category,p.product_id,p.product_name,o.order_id,o.customer_id,o.status,i.quantity*i.unit_price_at_sale line_value
 FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) JOIN products p USING(product_id)
), product_month AS (
 SELECT month_start,region,category,product_id,product_name,sum(line_value) FILTER(WHERE status='completed') revenue FROM line_fact GROUP BY 1,2,3,4,5
), ranked_products AS (
 SELECT *,row_number() OVER(PARTITION BY month_start,region,category ORDER BY revenue DESC NULLS LAST,product_id) rn FROM product_month
), metrics AS (
 SELECT month_start,region,category,count(DISTINCT order_id) total_orders,count(DISTINCT order_id) FILTER(WHERE status='returned') returned_orders,
 sum(line_value) FILTER(WHERE status='completed') revenue,count(DISTINCT customer_id) FILTER(WHERE status='completed') active_customers
 FROM line_fact GROUP BY GROUPING SETS((month_start,region,category),(month_start,category),(month_start,region),(month_start),())
), retention AS (
 SELECT date_trunc('month',o.order_date)::date month_start,count(DISTINCT o.customer_id) FILTER(WHERE o.order_date>=c.signup_date+interval '1 month') repeat_customers,
 count(DISTINCT o.customer_id) active_customers FROM vw_orders_deduplicated o JOIN customers c USING(customer_id) WHERE o.status='completed' GROUP BY 1
)
SELECT m.month_start,coalesce(m.region,'ALL REGIONS') region,coalesce(m.category,'ALL CATEGORIES') category,m.total_orders,m.returned_orders,
 round(100.0*m.returned_orders/nullif(m.total_orders,0),2) return_rate_pct,m.revenue::numeric(16,2),m.active_customers,
 round(100.0*(m.revenue-lag(m.revenue) OVER(PARTITION BY m.region,m.category ORDER BY m.month_start))/nullif(lag(m.revenue) OVER(PARTITION BY m.region,m.category ORDER BY m.month_start),0),2) mom_growth_pct,
 rp.product_name top_product,rp.revenue::numeric(14,2) top_product_revenue,
 CASE WHEN m.region IS NULL AND m.category IS NULL AND m.month_start IS NOT NULL THEN round(100.0*r.repeat_customers/nullif(r.active_customers,0),2) END retention_snapshot_pct
FROM metrics m LEFT JOIN ranked_products rp ON rp.month_start=m.month_start AND rp.region=m.region AND rp.category=m.category AND rp.rn=1
LEFT JOIN retention r USING(month_start) ORDER BY m.month_start NULLS LAST,m.region NULLS LAST,m.category NULLS LAST;
/*
So what: One auditable pipeline gives executives trends and totals while preserving drill-down keys; subtotal rows avoid separate queries with drifting logic.
*/
