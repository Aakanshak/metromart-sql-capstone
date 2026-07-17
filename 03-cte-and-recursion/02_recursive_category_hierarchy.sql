/*
Business question: How much leaf-category revenue rolls up to every ancestor in the category tree?
*/
WITH RECURSIVE leaf_sales AS (
 SELECT p.subcategory leaf,sum(i.quantity*i.unit_price_at_sale) revenue
 FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) JOIN products p USING(product_id)
 WHERE o.status='completed' GROUP BY 1
), climb AS (
 SELECT h.category_id,h.category_name,h.parent_category_id,h.category_id leaf_id,h.category_name leaf_name,ls.revenue,0 depth
 FROM category_hierarchy h JOIN leaf_sales ls ON ls.leaf=h.category_name
 UNION ALL
 SELECT p.category_id,p.category_name,p.parent_category_id,c.leaf_id,c.leaf_name,c.revenue,c.depth+1
 FROM climb c JOIN category_hierarchy p ON p.category_id=c.parent_category_id
)
SELECT category_id,category_name,sum(revenue)::numeric(16,2) rolled_up_revenue,count(DISTINCT leaf_id) contributing_leaves
FROM climb GROUP BY 1,2 ORDER BY rolled_up_revenue DESC;
/*
So what: Recursive rollup keeps totals correct as merchandising adds levels; no hard-coded parent CASE expression must be maintained.
*/
