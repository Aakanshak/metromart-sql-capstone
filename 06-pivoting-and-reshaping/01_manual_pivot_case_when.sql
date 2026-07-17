/*
Business question: What is monthly completed revenue across the three executive categories in a chart-ready wide table?
*/
SELECT date_trunc('month',o.order_date)::date AS month_start,
 sum(i.quantity*i.unit_price_at_sale) FILTER(WHERE p.category='Electronics')::numeric(14,2) electronics,
 sum(i.quantity*i.unit_price_at_sale) FILTER(WHERE p.category='Home')::numeric(14,2) home,
 sum(i.quantity*i.unit_price_at_sale) FILTER(WHERE p.category='Clothing')::numeric(14,2) clothing
FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) JOIN products p USING(product_id)
WHERE o.status='completed' GROUP BY 1 ORDER BY 1;
/*
So what: Conditional aggregation is explicit, portable, and easiest to maintain when the reporting categories are stable and few.
*/
