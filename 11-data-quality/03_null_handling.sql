/*
Business question: How can contact and return metrics stay meaningful when optional source fields or zero denominators occur?
*/
SELECT c.customer_id,coalesce(nullif(trim(lower(c.email)),''),'unknown') normalized_email,
 coalesce(e.campaign_source,s.campaign_source,'unmarketable') preferred_campaign_source,
 coalesce(sum(i.quantity*i.unit_price_at_sale) FILTER(WHERE o.status='returned'),0)::numeric(14,2) return_value,
 round(100.0*count(DISTINCT o.order_id) FILTER(WHERE o.status='returned')/
 nullif(count(DISTINCT o.order_id) FILTER(WHERE o.status IN('completed','returned')),0),2) return_rate_pct
FROM customers c LEFT JOIN marketing_email_list e USING(customer_id) LEFT JOIN marketing_sms_list s USING(customer_id)
LEFT JOIN vw_orders_deduplicated o USING(customer_id) LEFT JOIN order_items i USING(order_id)
GROUP BY 1,2,3;
/*
So what: COALESCE supplies explicit reporting defaults, NULLIF prevents division errors, and null rates remain distinguishable from true zero.
*/
