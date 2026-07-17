/*
Business question: What are revenue totals by category, region, their intersections, and company-wide in one scan?
*/
SELECT CASE WHEN grouping(p.category)=1 THEN 'ALL CATEGORIES' ELSE p.category END category,
 CASE WHEN grouping(o.region)=1 THEN 'ALL REGIONS' ELSE o.region END region,
 grouping(p.category) category_is_total,grouping(o.region) region_is_total,
 sum(i.quantity*i.unit_price_at_sale)::numeric(16,2) revenue
FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) JOIN products p USING(product_id)
WHERE o.status='completed' GROUP BY GROUPING SETS((p.category,o.region),(p.category),(o.region),()) ORDER BY 3,4,1,2;
/*
So what: GROUPING SETS returns exactly the subtotal levels the board needs and GROUPING flags distinguish totals from genuine nulls.
*/
