/*
Business question: Which customers have exactly one completed order and never repeated?
*/
WITH first_order AS (
 SELECT customer_id,min(order_id) order_id FROM vw_orders_deduplicated WHERE status='completed' GROUP BY customer_id
)
SELECT c.customer_id,c.name,f.order_id FROM first_order f JOIN customers c USING(customer_id)
LEFT JOIN vw_orders_deduplicated later ON later.customer_id=f.customer_id AND later.status='completed' AND later.order_id<>f.order_id
WHERE later.order_id IS NULL;
/*
So what: The anti-join isolates one-time buyers for onboarding or second-purchase interventions without fragile count filtering.
*/
