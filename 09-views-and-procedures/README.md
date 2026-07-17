# Views, materialized views, functions, and triggers

Regular views provide current semantic definitions. The materialized daily product layer favors dashboard speed with nightly freshness; refresh concurrently after normal ingestion and use blocking refresh for initial/backfill loads. The reporting function validates dates. The trigger records status changes with actor and timestamp.
