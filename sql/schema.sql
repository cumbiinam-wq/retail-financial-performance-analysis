-- RECONSTRUCTED from the supplied information_schema export, 16 November 2026.
-- Optional: run only in a NEW, EMPTY database. No DROP or overwrite statements.
-- Exact original lengths, numeric precision, defaults, constraints and indexes
-- were not present in the export and are deliberately not inferred.
-- Load the original CSV data after creating these tables.

CREATE TABLE public.expense_transactions (
    expense_id character varying,
    expense_date date,
    department character varying,
    expense_category character varying,
    amount_zar numeric
);

CREATE TABLE public.monthly_budget (
    budget_month date,
    department character varying,
    metric character varying,
    budget_category character varying,
    budget_amount_zar numeric
);

CREATE TABLE public.products (
    product_id character varying,
    product_name character varying,
    department character varying,
    unit_price_zar numeric,
    unit_cost_zar numeric
);

CREATE TABLE public.sales_transactions (
    transaction_id character varying,
    transaction_date date,
    product_id character varying,
    units_sold integer,
    unit_selling_price_zar numeric,
    discount_amount_zar numeric,
    revenue_zar numeric,
    cogs_zar numeric
);

