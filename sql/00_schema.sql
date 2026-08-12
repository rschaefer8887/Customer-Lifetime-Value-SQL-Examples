-- DTC marketing analytics schema (DuckDB / portable SQL)

CREATE OR REPLACE TABLE months AS
SELECT * FROM read_csv_auto('data/months.csv', header=true);

CREATE OR REPLACE TABLE marketing_channels AS
SELECT * FROM read_csv_auto('data/marketing_channels.csv', header=true);

CREATE OR REPLACE TABLE customers AS
SELECT * FROM read_csv_auto('data/customers.csv', header=true);

CREATE OR REPLACE TABLE orders AS
SELECT * FROM read_csv_auto('data/orders.csv', header=true);

CREATE OR REPLACE TABLE mail_assignments AS
SELECT * FROM read_csv_auto('data/mail_assignments.csv', header=true);

CREATE OR REPLACE TABLE meta_spend AS
SELECT * FROM read_csv_auto('data/meta_spend.csv', header=true);

CREATE OR REPLACE TABLE channel_monthly_spend AS
SELECT * FROM read_csv_auto('data/channel_monthly_spend.csv', header=true);
