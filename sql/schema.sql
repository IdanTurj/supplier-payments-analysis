DROP TABLE IF EXISTS supplier_payments;

CREATE TABLE supplier_payments (
    payment_id INTEGER PRIMARY KEY,
    supplier_id INTEGER NOT NULL,
    supplier_name VARCHAR(100) NOT NULL,
    payment_date DATE NOT NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    status VARCHAR(20) NOT NULL CHECK (status IN ('paid', 'pending', 'cancelled'))
);

CREATE INDEX idx_supplier_payments_supplier_id
    ON supplier_payments (supplier_id);

CREATE INDEX idx_supplier_payments_payment_date
    ON supplier_payments (payment_date);

CREATE INDEX idx_supplier_payments_status
    ON supplier_payments (status);
