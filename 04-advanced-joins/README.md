# Advanced joins

These queries answer sequence, reconciliation, one-time-buyer, and per-customer top-N questions. The inventory FULL OUTER JOIN is necessary because either system can omit a product-region key. LATERAL is appropriate when the right-side top three depends on the current customer.
