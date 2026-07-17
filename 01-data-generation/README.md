# Data generation and load

The generator is deterministic (seed 20260717) and writes a machine-readable quality report after creating the CSVs. It guarantees rather than merely hopes for the defects used later: 800 exact raw-order copies, 240 near-duplicate CRM identities, nine blackout dates, SCD2 history gaps, unequal inventory coverage, and controlled marketing overlap.

Run `generate_data.py`, start PostgreSQL using the Compose file, then run `load_to_db.py`. The loader rebuilds the `metromart` schema transactionally, bulk copies files in dependency order, validates that every line item has a logical order header, and analyzes tables.

Raw CSVs are reproducible and gitignored to keep the repository lightweight. `data_quality_report.json` is committed as evidence of the generated shape.
