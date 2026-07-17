/*
Business question: How large are the reachable universe, cross-channel overlap, and channel-exclusive marketing audiences?
*/
WITH email AS (SELECT coalesce(customer_id::text,lower(email)) identity_key FROM marketing_email_list),
sms AS (SELECT coalesce(customer_id::text,lower(email)) identity_key FROM marketing_sms_list),
segments AS (
 SELECT 'union_reachable' segment,count(*) contacts FROM (SELECT identity_key FROM email UNION SELECT identity_key FROM sms) x
 UNION ALL SELECT 'intersection_both',count(*) FROM (SELECT identity_key FROM email INTERSECT SELECT identity_key FROM sms) x
 UNION ALL SELECT 'email_only',count(*) FROM (SELECT identity_key FROM email EXCEPT SELECT identity_key FROM sms) x
 UNION ALL SELECT 'sms_only',count(*) FROM (SELECT identity_key FROM sms EXCEPT SELECT identity_key FROM email) x
) SELECT * FROM segments ORDER BY segment;
/*
So what: Set operations make overlap mutually auditable and prevent double-counting the addressable campaign population.
*/
