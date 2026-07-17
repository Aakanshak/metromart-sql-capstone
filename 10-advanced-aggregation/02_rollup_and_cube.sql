/*
Business question: How do hierarchical ROLLUP and all-combination CUBE change the subtotal set?
*/
SELECT 'ROLLUP' method,p.category,o.region,sum(i.quantity*i.unit_price_at_sale)::numeric(16,2) revenue
FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) JOIN products p USING(product_id)
WHERE o.status='completed' GROUP BY ROLLUP(p.category,o.region)
UNION ALL
SELECT 'CUBE',p.category,o.region,sum(i.quantity*i.unit_price_at_sale)::numeric(16,2)
FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) JOIN products p USING(product_id)
WHERE o.status='completed' GROUP BY CUBE(p.category,o.region);
/*
So what: ROLLUP fits ordered category-to-region drilldowns; CUBE adds region-only totals and is useful only when every dimension combination matters.
*/
