-- Supplier Payments Analysis
-- PostgreSQL portfolio queries

-- 1. Overall payment KPIs
SELECT
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
    ) AS paid_percentage
FROM supplier_payments;

-- 2. Supplier-level summary
SELECT
    supplier_id,
    supplier_name,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_value,
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
GROUP BY supplier_id, supplier_name
ORDER BY total_paid DESC;

-- 3. Suppliers with material outstanding balances
SELECT
    supplier_id,
    supplier_name,
    SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) AS total_pending,
    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS pending_transactions
FROM supplier_payments
GROUP BY supplier_id, supplier_name
HAVING SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) >= 5000
ORDER BY total_pending DESC;

-- 4. Suppliers with repeated pending activity
SELECT
    supplier_id,
    supplier_name,
    COUNT(*) FILTER (WHERE status = 'pending') AS pending_transactions,
    SUM(amount) FILTER (WHERE status = 'pending') AS pending_value
FROM supplier_payments
GROUP BY supplier_id, supplier_name
HAVING COUNT(*) FILTER (WHERE status = 'pending') >= 2
ORDER BY pending_value DESC;

-- 5. Payment-size segmentation
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
FROM supplier_payments
ORDER BY payment_date, payment_id;

-- 6. Distribution by payment-size segment
WITH segmented AS (
    SELECT
        CASE
            WHEN amount < 2000 THEN 'Small'
            WHEN amount BETWEEN 2000 AND 4000 THEN 'Medium'
            ELSE 'Large'
        END AS payment_size,
        amount,
        status
    FROM supplier_payments
)
SELECT
    payment_size,
    COUNT(*) AS transactions,
    SUM(amount) AS total_value,
    SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) AS paid_value,
    SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) AS pending_value
FROM segmented
GROUP BY payment_size
ORDER BY total_value DESC;

-- 7. Monthly payment trend
SELECT
    DATE_TRUNC('month', payment_date)::date AS payment_month,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_value,
    SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) AS paid_value,
    SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) AS pending_value,
    SUM(CASE WHEN status = 'cancelled' THEN amount ELSE 0 END) AS cancelled_value
FROM supplier_payments
GROUP BY DATE_TRUNC('month', payment_date)
ORDER BY payment_month;

-- 8. Compare paid vs. pending amount using CTEs
WITH paid_summary AS (
    SELECT
        supplier_id,
        supplier_name,
        SUM(amount) AS total_paid
    FROM supplier_payments
    WHERE status = 'paid'
    GROUP BY supplier_id, supplier_name
),
pending_summary AS (
    SELECT
        supplier_id,
        supplier_name,
        SUM(amount) AS total_pending
    FROM supplier_payments
    WHERE status = 'pending'
    GROUP BY supplier_id, supplier_name
)
SELECT
    p.supplier_id,
    p.supplier_name,
    p.total_paid,
    COALESCE(pe.total_pending, 0) AS total_pending,
    p.total_paid - COALESCE(pe.total_pending, 0) AS paid_pending_difference
FROM paid_summary p
LEFT JOIN pending_summary pe
    ON p.supplier_id = pe.supplier_id
ORDER BY paid_pending_difference DESC;

-- 9. Latest payment for each supplier
WITH ranked_payments AS (
    SELECT
        payment_id,
        supplier_id,
        supplier_name,
        payment_date,
        amount,
        status,
        ROW_NUMBER() OVER (
            PARTITION BY supplier_id
            ORDER BY payment_date DESC, payment_id DESC
        ) AS row_num
    FROM supplier_payments
)
SELECT
    payment_id,
    supplier_id,
    supplier_name,
    payment_date,
    amount,
    status
FROM ranked_payments
WHERE row_num = 1
ORDER BY supplier_id;

-- 10. Two latest payments for each supplier
WITH ranked_payments AS (
    SELECT
        payment_id,
        supplier_id,
        supplier_name,
        payment_date,
        amount,
        status,
        ROW_NUMBER() OVER (
            PARTITION BY supplier_id
            ORDER BY payment_date DESC, payment_id DESC
        ) AS row_num
    FROM supplier_payments
)
SELECT *
FROM ranked_payments
WHERE row_num <= 2
ORDER BY supplier_id, row_num;

-- 11. Largest payment for each supplier
WITH ranked_payments AS (
    SELECT
        payment_id,
        supplier_id,
        supplier_name,
        payment_date,
        amount,
        status,
        ROW_NUMBER() OVER (
            PARTITION BY supplier_id
            ORDER BY amount DESC, payment_date DESC
        ) AS row_num
    FROM supplier_payments
)
SELECT
    payment_id,
    supplier_id,
    supplier_name,
    payment_date,
    amount,
    status
FROM ranked_payments
WHERE row_num = 1
ORDER BY amount DESC;

-- 12. Rank suppliers by pending balance
WITH supplier_pending AS (
    SELECT
        supplier_id,
        supplier_name,
        SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) AS total_pending
    FROM supplier_payments
    GROUP BY supplier_id, supplier_name
)
SELECT
    supplier_id,
    supplier_name,
    total_pending,
    DENSE_RANK() OVER (ORDER BY total_pending DESC) AS pending_rank
FROM supplier_pending
ORDER BY pending_rank, supplier_id;

-- 13. Suppliers with more paid value than pending value
WITH supplier_summary AS (
    SELECT
        supplier_id,
        supplier_name,
        SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) AS total_paid,
        SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) AS total_pending,
        COUNT(*) AS total_transactions
    FROM supplier_payments
    GROUP BY supplier_id, supplier_name
)
SELECT
    supplier_id,
    supplier_name,
    total_paid,
    total_pending,
    total_paid - total_pending AS difference,
    total_transactions
FROM supplier_summary
WHERE total_paid > total_pending
ORDER BY difference DESC;

-- 14. Transaction-level running paid total by supplier
SELECT
    payment_id,
    supplier_id,
    supplier_name,
    payment_date,
    amount,
    status,
    SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) OVER (
        PARTITION BY supplier_id
        ORDER BY payment_date, payment_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_paid_total
FROM supplier_payments
ORDER BY supplier_id, payment_date, payment_id;
