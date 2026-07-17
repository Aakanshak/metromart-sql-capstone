/*
Business question: Where do online and store inventory systems disagree or omit product-region combinations?
*/
WITH store AS (
 SELECT product_id,region,sum(stock_qty) stock_qty,max(last_updated) last_updated FROM inventory_instore GROUP BY 1,2
)
SELECT coalesce(o.product_id,s.product_id) product_id,coalesce(o.region,s.region) region,
 o.stock_qty online_qty,s.stock_qty instore_qty,coalesce(o.stock_qty,0)-coalesce(s.stock_qty,0) variance,
 CASE WHEN o.product_id IS NULL THEN 'missing_online' WHEN s.product_id IS NULL THEN 'missing_instore'
      WHEN o.stock_qty<>s.stock_qty THEN 'quantity_mismatch' ELSE 'matched' END reconciliation_status
FROM inventory_online o FULL OUTER JOIN store s USING(product_id,region)
WHERE o.product_id IS NULL OR s.product_id IS NULL OR o.stock_qty<>s.stock_qty
ORDER BY abs(coalesce(o.stock_qty,0)-coalesce(s.stock_qty,0)) DESC;
/*
So what: FULL OUTER JOIN retains one-sided records that an inner or left join would hide, preventing false inventory completeness.
*/
