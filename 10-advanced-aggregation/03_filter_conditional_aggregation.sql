/*
Business question: What order volume, returns, cancellations, and net revenue does each category generate?
*/
SELECT p.category,count(DISTINCT o.order_id) total_orders,
 count(DISTINCT o.order_id) FILTER(WHERE o.status='returned') returned_orders,
 count(DISTINCT o.order_id) FILTER(WHERE o.status='cancelled') cancelled_orders,
 sum(i.quantity*i.unit_price_at_sale) FILTER(WHERE o.status='completed')::numeric(16,2) completed_revenue,
 round(100.0*count(DISTINCT o.order_id) FILTER(WHERE o.status='returned')/nullif(count(DISTINCT o.order_id),0),2) return_rate_pct
FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) JOIN products p USING(product_id) GROUP BY 1;
/*
So what: FILTER keeps metric conditions adjacent and readable while calculating all KPIs in one grouped scan.
*/
