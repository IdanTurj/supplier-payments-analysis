-- Reporting views for Power BI

CREATE OR REPLACE VIEW vw_supplier_payment_summary AS
SELECT
    supplier_id,
    supplier_name,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_payment_value,
    SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) AS total_pending,
    SUM(CASE WHEN status = 'cancelled' THEN amount ELSE 0 END) AS total_cancelled,
    SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END) AS paid_transactions,
    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS pending_transactions,
    SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_transactions,
    ROUND(
        SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS paid_percentage,
    ROUND(AVG(amount), 2) AS average_payment,
    MAX(amount) AS largest_payment
FROM supplier_payments
GROUP BY supplier_id, supplier_name;


CREATE OR REPLACE VIEW vw_monthly_payment_summary AS
SELECT
    DATE_TRUNC('month', payment_date)::date AS payment_month,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_payment_value,
    SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) AS total_pending,
    SUM(CASE WHEN status = 'cancelled' THEN amount ELSE 0 END) AS total_cancelled
FROM supplier_payments
GROUP BY DATE_TRUNC('month', payment_date);


CREATE OR REPLACE VIEW vw_payment_detail AS
SELECT
    payment_id,
    supplier_id,
    supplier_name,
    payment_date,
    amount,
    status,
    CASE
        WHEN amount < 2000 THEN 'Small'
        WHEN amount BETWEEN 2000 AND 4000 THEN 'Medium'
        ELSE 'Large'
    END AS payment_size
FROM supplier_payments;
