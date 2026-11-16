-- RECONSTRUCTED ANALYSIS: PostgreSQL, FY2025. Read-only SELECT statements.
-- Rebuilt from the supplied schema and documented project requirements.
-- These are not recovered originals. Execute and validate in pgAdmin.
-- Reporting interval: 2025-01-01 inclusive to 2026-01-01 exclusive.
-- Costs use positive amounts; variance = actual - budget.

-- 1. Source record counts (all dates).
SELECT 'products' AS table_name, COUNT(*) AS record_count FROM public.products
UNION ALL SELECT 'sales_transactions', COUNT(*) FROM public.sales_transactions
UNION ALL SELECT 'expense_transactions', COUNT(*) FROM public.expense_transactions
UNION ALL SELECT 'monthly_budget', COUNT(*) FROM public.monthly_budget;

-- 2. Sales date coverage and number of reporting months.
SELECT MIN(transaction_date) AS first_date, MAX(transaction_date) AS last_date,
       COUNT(DISTINCT DATE_TRUNC('month',transaction_date)) AS months_present
FROM public.sales_transactions
WHERE transaction_date >= DATE '2025-01-01' AND transaction_date < DATE '2026-01-01';

-- 3. Required-value checks. Missing optional budget_category is not treated as failure.
SELECT 'sales_transactions' AS source, COUNT(*) FILTER (WHERE transaction_id IS NULL OR transaction_date IS NULL OR product_id IS NULL OR units_sold IS NULL OR revenue_zar IS NULL OR cogs_zar IS NULL) AS rows_with_missing_values FROM public.sales_transactions
UNION ALL SELECT 'expense_transactions',COUNT(*) FILTER (WHERE expense_id IS NULL OR expense_date IS NULL OR department IS NULL OR expense_category IS NULL OR amount_zar IS NULL) FROM public.expense_transactions
UNION ALL SELECT 'products',COUNT(*) FILTER (WHERE product_id IS NULL OR product_name IS NULL OR department IS NULL OR unit_price_zar IS NULL OR unit_cost_zar IS NULL) FROM public.products
UNION ALL SELECT 'monthly_budget',COUNT(*) FILTER (WHERE budget_month IS NULL OR department IS NULL OR metric IS NULL OR budget_amount_zar IS NULL) FROM public.monthly_budget;

-- 4. Values requiring review. Negative amounts may represent legitimate returns.
SELECT 'sales' AS source, COUNT(*) AS rows_to_review FROM public.sales_transactions
WHERE units_sold <= 0 OR revenue_zar < 0 OR cogs_zar < 0 OR discount_amount_zar < 0 OR unit_selling_price_zar < 0
UNION ALL SELECT 'expenses',COUNT(*) FROM public.expense_transactions WHERE amount_zar < 0
UNION ALL SELECT 'budget',COUNT(*) FROM public.monthly_budget WHERE budget_amount_zar < 0
UNION ALL SELECT 'products',COUNT(*) FROM public.products WHERE unit_price_zar < 0 OR unit_cost_zar < 0;

-- 5. Duplicate identifiers (expect no rows; budget has no exported unique ID).
SELECT 'products' AS source, product_id AS identifier, COUNT(*) AS occurrences FROM public.products GROUP BY product_id HAVING COUNT(*) > 1
UNION ALL SELECT 'sales',transaction_id,COUNT(*) FROM public.sales_transactions GROUP BY transaction_id HAVING COUNT(*) > 1
UNION ALL SELECT 'expenses',expense_id,COUNT(*) FROM public.expense_transactions GROUP BY expense_id HAVING COUNT(*) > 1;

-- 6. Sales without a matching product (expect no rows).
SELECT s.product_id, COUNT(*) AS transaction_count
FROM public.sales_transactions s LEFT JOIN public.products p ON p.product_id=s.product_id
WHERE p.product_id IS NULL GROUP BY s.product_id;

-- 7. Inspect raw budget labels BEFORE using the mapping in section 9.
SELECT metric, COUNT(*) AS rows, SUM(budget_amount_zar) AS budget_amount_zar
FROM public.monthly_budget
WHERE budget_month >= DATE '2025-01-01' AND budget_month < DATE '2026-01-01'
GROUP BY metric ORDER BY metric;

-- 8. Annual financial KPIs. Aggregate sales and expenses separately to avoid fan-out.
WITH sales AS (
 SELECT SUM(revenue_zar) AS revenue, SUM(cogs_zar) AS cogs
 FROM public.sales_transactions
 WHERE transaction_date >= DATE '2025-01-01' AND transaction_date < DATE '2026-01-01'
), expenses AS (
 SELECT SUM(amount_zar) AS opex FROM public.expense_transactions
 WHERE expense_date >= DATE '2025-01-01' AND expense_date < DATE '2026-01-01'
)
SELECT revenue AS revenue_zar, cogs AS cogs_zar, revenue-cogs AS gross_profit_zar,
       opex AS operating_expenses_zar, cogs+opex AS total_expenses_zar,
       revenue-cogs-opex AS operating_profit_zar,
       ROUND(100*(revenue-cogs)/NULLIF(revenue,0),2) AS gross_profit_margin_pct,
       ROUND(100*(revenue-cogs-opex)/NULLIF(revenue,0),2) AS operating_profit_margin_pct
FROM sales CROSS JOIN expenses;

-- 9. Monthly budget comparison. Includes all 12 months and six financial metrics.
-- Recognised budget labels: revenue, cogs, operating expenses (including
-- underscore/hyphen variants and opex). Any other labels are flagged below.
WITH months AS (
 SELECT GENERATE_SERIES(DATE '2025-01-01',DATE '2025-12-01',INTERVAL '1 month')::date AS month
), sales AS (
 SELECT DATE_TRUNC('month',transaction_date)::date AS month,
        SUM(revenue_zar) AS revenue, SUM(cogs_zar) AS cogs
 FROM public.sales_transactions
 WHERE transaction_date >= DATE '2025-01-01' AND transaction_date < DATE '2026-01-01'
 GROUP BY 1
), expenses AS (
 SELECT DATE_TRUNC('month',expense_date)::date AS month, SUM(amount_zar) AS opex
 FROM public.expense_transactions
 WHERE expense_date >= DATE '2025-01-01' AND expense_date < DATE '2026-01-01'
 GROUP BY 1
), budget_labels AS (
 SELECT DATE_TRUNC('month',budget_month)::date AS month, budget_amount_zar,
        CASE REGEXP_REPLACE(LOWER(TRIM(metric)), '[ _-]+', ' ', 'g')
          WHEN 'revenue' THEN 'revenue' WHEN 'cogs' THEN 'cogs'
          WHEN 'operating expenses' THEN 'opex' WHEN 'operating expense' THEN 'opex'
          WHEN 'opex' THEN 'opex' ELSE NULL END AS metric_key
 FROM public.monthly_budget
 WHERE budget_month >= DATE '2025-01-01' AND budget_month < DATE '2026-01-01'
), budget AS (
 SELECT month, SUM(budget_amount_zar) FILTER (WHERE metric_key='revenue') AS revenue,
        SUM(budget_amount_zar) FILTER (WHERE metric_key='cogs') AS cogs,
        SUM(budget_amount_zar) FILTER (WHERE metric_key='opex') AS opex,
        COUNT(*) FILTER (WHERE metric_key IS NULL) AS unmapped_budget_rows
 FROM budget_labels GROUP BY month
), wide AS (
 SELECT m.month, COALESCE(s.revenue,0) AS ar,COALESCE(s.cogs,0) AS ac,
        COALESCE(e.opex,0) AS ao,b.revenue AS br,b.cogs AS bc,b.opex AS bo,
        COALESCE(b.unmapped_budget_rows,0) AS unmapped_budget_rows,
        b.revenue IS NOT NULL AND b.cogs IS NOT NULL AND b.opex IS NOT NULL
          AND COALESCE(b.unmapped_budget_rows,0)=0 AS budget_complete
 FROM months m LEFT JOIN sales s USING(month) LEFT JOIN expenses e USING(month)
 LEFT JOIN budget b USING(month)
), detail AS (
 SELECT w.month,w.budget_complete,w.unmapped_budget_rows,v.* FROM wide w
 CROSS JOIN LATERAL (VALUES
  ('Revenue',ar,br),('COGS',ac,bc),('Operating Expenses',ao,bo),
  ('Total Expenses',ac+ao,bc+bo),('Gross Profit',ar-ac,br-bc),
  ('Operating Profit',ar-ac-ao,br-bc-bo)
 ) v(metric,actual_zar,budget_zar)
)
SELECT month,metric,actual_zar,budget_zar,actual_zar-budget_zar AS variance_zar,
 ROUND(100*(actual_zar-budget_zar)/NULLIF(budget_zar,0),2) AS variance_pct,
 CASE WHEN NOT budget_complete THEN 'Review budget mapping/coverage'
      WHEN actual_zar=budget_zar THEN 'On budget'
      WHEN (metric IN ('COGS','Operating Expenses','Total Expenses') AND actual_zar<budget_zar)
        OR (metric IN ('Revenue','Gross Profit','Operating Profit') AND actual_zar>budget_zar)
      THEN 'Favourable' ELSE 'Unfavourable' END AS assessment,
 budget_complete,unmapped_budget_rows
FROM detail ORDER BY month,metric;

-- 10. Product performance: all products with FY2025 sales, ranked by revenue.
-- Add LIMIT 5 after ORDER BY to reproduce the top-five view.
SELECT p.product_id,p.product_name,p.department,
 SUM(s.units_sold) AS total_units_sold,SUM(s.revenue_zar) AS total_revenue_zar,
 SUM(s.cogs_zar) AS total_cogs_zar,SUM(s.revenue_zar-s.cogs_zar) AS gross_profit_zar,
 ROUND(100*SUM(s.revenue_zar-s.cogs_zar)/NULLIF(SUM(s.revenue_zar),0),2) AS gross_profit_margin_pct
FROM public.products p JOIN public.sales_transactions s USING(product_id)
WHERE s.transaction_date >= DATE '2025-01-01' AND s.transaction_date < DATE '2026-01-01'
GROUP BY p.product_id,p.product_name,p.department ORDER BY total_revenue_zar DESC;

-- 11. Department performance. Margin is a decimal fraction for Power BI
-- Percentage formatting: 0.6088 displays as 60.88%. Do not multiply again by 100.
SELECT p.department,SUM(s.revenue_zar) AS total_revenue_zar,
 SUM(s.units_sold) AS total_units_sold,SUM(s.cogs_zar) AS total_cogs_zar,
 SUM(s.revenue_zar-s.cogs_zar) AS gross_profit_zar,
 ROUND(SUM(s.revenue_zar-s.cogs_zar)/NULLIF(SUM(s.revenue_zar),0),4) AS gross_profit_margin_pct
FROM public.products p JOIN public.sales_transactions s USING(product_id)
WHERE s.transaction_date >= DATE '2025-01-01' AND s.transaction_date < DATE '2026-01-01'
GROUP BY p.department ORDER BY total_revenue_zar DESC;

-- 12. Operating expense breakdown (not total expenses: excludes COGS).
SELECT department,expense_category,SUM(amount_zar) AS operating_expenses_zar
FROM public.expense_transactions
WHERE expense_date >= DATE '2025-01-01' AND expense_date < DATE '2026-01-01'
GROUP BY department,expense_category ORDER BY operating_expenses_zar DESC;
