-- DTC marketing analytics schema (DuckDB / portable SQL)
-- Tables mirror common warehouse concepts: customers, orders, experiments, paid social spend.

CREATE OR REPLACE TABLE customers AS
SELECT * FROM read_csv_auto('data/customers.csv', header=true);

CREATE OR REPLACE TABLE orders AS
SELECT * FROM read_csv_auto('data/orders.csv', header=true);

CREATE OR REPLACE TABLE mail_assignments AS
SELECT * FROM read_csv_auto('data/mail_assignments.csv', header=true);

CREATE OR REPLACE TABLE meta_spend AS
SELECT * FROM read_csv_auto('data/meta_spend.csv', header=true);
