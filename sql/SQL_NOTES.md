# Reconstructed SQL scripts

These scripts were rebuilt from the supplied database column export and the project requirements on 16 November 2026. They are not the recovered original queries.

- `schema.sql`: optional table creation in a new, empty database. The column export does not contain original constraints, defaults, precision, lengths or indexes, so these are not reconstructed.
- `analysis_queries.sql`: read-only checks and FY2025 financial analysis. Run sections separately in pgAdmin against the existing financial_performance database. Do not run schema.sql against existing tables.
- `source_table_structure.csv`: the schema export used for reconstruction.

## Validation status

The user supplied successful PostgreSQL KPI, expense breakdown, budget label and monthly comparison results. The 72 monthly rows were independently reconciled to the original CSV files. See validation/VALIDATION.md for evidence and remaining limits. Run sections 1–8 first. Confirm the budget metric labels from section 7 are handled by section 9; all budget_complete values should be true and unmapped_budget_rows should be zero. Missing budget data remains NULL rather than being silently replaced with zero.

Expected source counts: products 6; sales_transactions 12,450; expense_transactions 643; monthly_budget 204.

Expected section 8 totals: revenue R13,340,305.70; COGS R5,984,666.00; gross profit R7,355,639.70; operating expenses R5,058,648.35; operating profit R2,296,991.35; gross margin 55.14%; operating margin 17.22%.

Section 11 returns margin fractions for Power BI. Sections 8 and 10 return percentages already multiplied by 100. Departmental gross profit excludes operating expense allocation.

The package includes the supplied PBIX and dashboard screenshots. The original four CSV datasets are included in data/.
