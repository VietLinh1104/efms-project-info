-- Script migration để chuyển đổi cấu trúc bảng: loại bỏ bảng trung gian core.invoice_payments và thêm liên kết trực tiếp core.payments -> core.invoices.

-- 1. Drop bảng liên kết trung gian
DROP TABLE IF EXISTS core.invoice_payments CASCADE;

-- 2. Thêm cột invoice_id vào bảng payments
ALTER TABLE core.payments ADD COLUMN invoice_id UUID REFERENCES core.invoices(id);

-- 3. Tạo index cho cột mới để tối ưu truy vấn
CREATE INDEX idx_payments_invoice ON core.payments(invoice_id);
