# Validation evidence — 16 November 2026

The original CSV datasets were independently aggregated and compared with the 72-row monthly budget-versus-actual export produced in the user's PostgreSQL database.

- Source counts match: 6 products, 12,450 sales transactions, 643 expense transactions and 204 budget records.
- Product, transaction and expense identifiers are unique. All sales product IDs have a matching product.
- All 72 monthly actual amounts, budget amounts, rand variances, percentage variances and favourable/unfavourable classifications match the CSV recalculation.
- All monthly budget coverage flags are true and no budget rows are unmapped.
- Annual actual totals reconcile to the user's SQL KPI screenshot and Power BI headline results.
- The user executed the analysis script and supplied its expense breakdown, annual KPI results, budget label totals and monthly comparison export. The assistant did not independently execute the full script in PostgreSQL. Other validation query outputs and optional schema creation have not been individually confirmed.

Annual totals (ZAR): revenue 13,340,305.70; COGS 5,984,666.00; operating expenses 5,058,648.35; operating profit 2,296,991.35.
Budget totals (ZAR): revenue 11,479,207.67; COGS 5,078,401.47; operating expenses 5,013,952.32; operating profit 1,386,853.88.

The PBIX is the file supplied by the user. Refresh in Power BI Desktop with a local PostgreSQL connection remains a reviewer setup step.
