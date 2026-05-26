-- EFMS Database v4 (Microservices Architecture)
-- Base on doc/DB-PostgreSQL-v4.md
-- Created At: 2026-05-01

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. IDENTITY SERVICE
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS identity;

-- 1. Companies — Công ty
CREATE TABLE identity.companies (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         VARCHAR(255) NOT NULL,
    tax_code     VARCHAR(50),
    address      TEXT,
    currency     VARCHAR(3) NOT NULL DEFAULT 'VND',
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP DEFAULT now()
);

-- 2. Roles — Danh mục vai trò
CREATE TABLE identity.roles (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         VARCHAR(100) NOT NULL,
    description  TEXT,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP DEFAULT now()
);

-- 3. Permissions — Danh mục quyền hạn
CREATE TABLE identity.permissions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource     VARCHAR(100) NOT NULL, -- vd: invoice, payment, user
    action       VARCHAR(50) NOT NULL,  -- vd: create, read, update, delete
    description  TEXT,
    created_at   TIMESTAMP DEFAULT now()
);

-- 4. Role Permissions — Quyền của vai trò
CREATE TABLE identity.role_permissions (
    role_id       UUID NOT NULL REFERENCES identity.roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES identity.permissions(id) ON DELETE CASCADE,
    created_at    TIMESTAMP DEFAULT now(),
    PRIMARY KEY (role_id, permission_id)
);

-- 5. Users — Người dùng
CREATE TABLE identity.users (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id   UUID NOT NULL REFERENCES identity.companies(id),
    role_id      UUID NOT NULL REFERENCES identity.roles(id),
    name         VARCHAR(255) NOT NULL,
    email        VARCHAR(255) NOT NULL UNIQUE,
    password     VARCHAR(255) NOT NULL,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP DEFAULT now()
);

-- 6. Audit Logs (Identity) — Nhật ký hệ thống Identity
CREATE TABLE identity.audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name  VARCHAR(100) NOT NULL,
    record_id   UUID NOT NULL,
    action      VARCHAR(20) NOT NULL,   -- INSERT / UPDATE / DELETE
    changed_by  UUID REFERENCES identity.users(id),
    changed_at  TIMESTAMP DEFAULT now(),
    old_data    JSONB,
    new_data    JSONB
);

-- =============================================================================
-- 2. CORE SERVICE
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS core;

-- 7. Fiscal Periods — Kỳ kế toán
CREATE TABLE core.fiscal_periods (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id   UUID NOT NULL, -- UUID từ Identity Service
    name         VARCHAR(50) NOT NULL,
    start_date   DATE NOT NULL,
    end_date     DATE NOT NULL,
    status       VARCHAR(20) NOT NULL DEFAULT 'open',  -- open / closed
    closed_by    UUID, -- UUID từ Identity Service
    closed_at    TIMESTAMP,
    created_at   TIMESTAMP DEFAULT now()
);

-- 8. Accounts — Danh mục tài khoản kế toán
CREATE TABLE core.accounts (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id   UUID NOT NULL, -- UUID từ Identity Service
    code         VARCHAR(20) NOT NULL,
    name         VARCHAR(255) NOT NULL,
    type         VARCHAR(50) NOT NULL,   -- asset / liability / equity / revenue / expense
    balance_type VARCHAR(10) NOT NULL,   -- debit / credit
    parent_id    UUID REFERENCES core.accounts(id),
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP DEFAULT now(),
    UNIQUE(company_id, code)
);

-- 9. Partners — Khách hàng & Nhà cung cấp
CREATE TABLE core.partners (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id    UUID NOT NULL, -- UUID từ Identity Service
    name          VARCHAR(255) NOT NULL,
    type          VARCHAR(20) NOT NULL,   -- customer / vendor / both
    tax_code      VARCHAR(50),
    phone         VARCHAR(50),
    email         VARCHAR(255),
    address       TEXT,
    ar_account_id UUID REFERENCES core.accounts(id),  -- TK phải thu mặc định
    ap_account_id UUID REFERENCES core.accounts(id),  -- TK phải trả mặc định
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP DEFAULT now()
);

-- 10. Journal Entries — Chứng từ kế toán
CREATE TABLE core.journal_entries (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id    UUID NOT NULL, -- UUID từ Identity Service
    period_id     UUID REFERENCES core.fiscal_periods(id),
    entry_date    DATE NOT NULL,
    reference     VARCHAR(255),
    description   TEXT,
    status        VARCHAR(20) NOT NULL DEFAULT 'draft',  -- draft / posted / cancelled
    source        VARCHAR(50),   -- manual / ar / ap / payment / bank
    source_ref_id UUID,
    created_by    UUID, -- UUID từ Identity Service
    posted_by     UUID, -- UUID từ Identity Service
    posted_at     TIMESTAMP,
    created_at    TIMESTAMP DEFAULT now()
);

-- 11. Journal Lines — Dòng bút toán
CREATE TABLE core.journal_lines (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_entry_id UUID NOT NULL REFERENCES core.journal_entries(id) ON DELETE CASCADE,
    account_id       UUID NOT NULL REFERENCES core.accounts(id),
    partner_id       UUID REFERENCES core.partners(id),
    debit            NUMERIC(18,2) NOT NULL DEFAULT 0,
    credit           NUMERIC(18,2) NOT NULL DEFAULT 0,
    currency_code    VARCHAR(3) NOT NULL DEFAULT 'VND',
    amount_currency  NUMERIC(18,2),
    exchange_rate    NUMERIC(18,6) DEFAULT 1,
    description      TEXT,
    created_at       TIMESTAMP DEFAULT now(),
    CONSTRAINT chk_debit_positive  CHECK (debit >= 0),
    CONSTRAINT chk_credit_positive CHECK (credit >= 0),
    CONSTRAINT chk_not_both        CHECK (NOT (debit > 0 AND credit > 0))
);

-- 16. Bank Accounts — Tài khoản ngân hàng / tiền mặt
-- Created before Payments because Payments references it
CREATE TABLE core.bank_accounts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id      UUID NOT NULL, -- UUID từ Identity Service
    name            VARCHAR(255) NOT NULL,
    bank_name       VARCHAR(255),
    account_number  VARCHAR(100),
    type            VARCHAR(20) NOT NULL,   -- cash / bank
    currency_code   VARCHAR(3) NOT NULL DEFAULT 'VND',
    opening_balance NUMERIC(18,2) DEFAULT 0,
    gl_account_id   UUID REFERENCES core.accounts(id),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT now()
);

-- 12. Invoices — Hóa đơn
CREATE TABLE core.invoices (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id       UUID NOT NULL, -- UUID từ Identity Service
    partner_id       UUID NOT NULL REFERENCES core.partners(id),
    invoice_type     VARCHAR(5) NOT NULL,   -- ar / ap
    invoice_number   VARCHAR(100),
    invoice_date     DATE NOT NULL,
    due_date         DATE,
    currency_code    VARCHAR(3) NOT NULL DEFAULT 'VND',
    exchange_rate    NUMERIC(18,6) DEFAULT 1,
    subtotal         NUMERIC(18,2) NOT NULL DEFAULT 0,
    tax_amount       NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_amount     NUMERIC(18,2) NOT NULL DEFAULT 0,
    paid_amount      NUMERIC(18,2) NOT NULL DEFAULT 0,
    status           VARCHAR(20) NOT NULL DEFAULT 'draft',  -- draft / open / partial / paid / cancelled
    approval_status  VARCHAR(20) DEFAULT NULL,              -- pending / approved / rejected
    approval_comment TEXT DEFAULT NULL,
    camunda_process_id VARCHAR(255) DEFAULT NULL,
    journal_entry_id UUID REFERENCES core.journal_entries(id),
    created_by       UUID, -- UUID từ Identity Service
    created_at       TIMESTAMP DEFAULT now()
);

-- 13. Invoice Lines — Chi tiết hóa đơn
CREATE TABLE core.invoice_lines (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id   UUID NOT NULL REFERENCES core.invoices(id) ON DELETE CASCADE,
    account_id   UUID REFERENCES core.accounts(id),
    description  TEXT NOT NULL,
    quantity     NUMERIC(10,2) NOT NULL DEFAULT 1,
    unit_price   NUMERIC(18,2) NOT NULL DEFAULT 0,
    tax_rate     NUMERIC(5,2) NOT NULL DEFAULT 0,
    tax_amount   NUMERIC(18,2) NOT NULL DEFAULT 0,
    amount       NUMERIC(18,2) NOT NULL DEFAULT 0
);

-- 14. Payments — Thanh toán thu/chi
CREATE TABLE core.payments (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id       UUID NOT NULL, -- UUID từ Identity Service
    partner_id       UUID REFERENCES core.partners(id),
    invoice_id       UUID REFERENCES core.invoices(id), -- Hóa đơn được thanh toán
    payment_type     VARCHAR(10) NOT NULL,   -- receive / pay
    payment_date     DATE NOT NULL,
    currency_code    VARCHAR(3) NOT NULL DEFAULT 'VND',
    exchange_rate    NUMERIC(18,6) DEFAULT 1,
    amount           NUMERIC(18,2) NOT NULL,
    payment_method   VARCHAR(50),   -- cash / bank_transfer / check
    bank_account_id  UUID REFERENCES core.bank_accounts(id),
    reference        VARCHAR(255),
    journal_entry_id UUID REFERENCES core.journal_entries(id),
    created_by       UUID, -- UUID từ Identity Service
    created_at       TIMESTAMP DEFAULT now()
);


-- 17. Bank Transactions — Giao dịch ngân hàng
CREATE TABLE core.bank_transactions (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bank_account_id  UUID NOT NULL REFERENCES core.bank_accounts(id),
    transaction_date DATE NOT NULL,
    description      TEXT,
    type             VARCHAR(10) NOT NULL,   -- in / out
    amount           NUMERIC(18,2) NOT NULL,
    reference        VARCHAR(255),
    is_reconciled    BOOLEAN NOT NULL DEFAULT FALSE,
    journal_entry_id UUID REFERENCES core.journal_entries(id),
    created_at       TIMESTAMP DEFAULT now()
);

-- 18. Audit Logs (Core) — Nhật ký thay đổi Core
CREATE TABLE core.audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name  VARCHAR(100) NOT NULL,
    record_id   UUID NOT NULL,
    action      VARCHAR(20) NOT NULL,   -- INSERT / UPDATE / DELETE
    changed_by  UUID, -- UUID từ Identity Service
    changed_at  TIMESTAMP DEFAULT now(),
    old_data    JSONB,
    new_data    JSONB
);

-- =============================================================================
-- 3. COMMON SERVICE
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS common;

-- 1. Attachments — Tệp đính kèm (Độc lập)
CREATE TABLE common.attachments (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id   UUID NOT NULL, -- UUID từ Identity Service
    file_name    VARCHAR(255) NOT NULL,
    file_type    VARCHAR(100),
    file_size    BIGINT,
    file_url     TEXT NOT NULL,
    created_by   UUID, -- UUID từ Identity Service
    created_at   TIMESTAMP DEFAULT now()
);

-- 2. Comments — Bình luận (Độc lập)
CREATE TABLE common.comments (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id       UUID NOT NULL, -- UUID từ Identity Service
    content          TEXT NOT NULL,
    author_id        UUID, -- UUID từ Identity Service (người bình luận)
    created_at       TIMESTAMP DEFAULT now()
);

-- 3. Entity Links — Bảng trung gian liên kết dùng chung (Polymorphic)
CREATE TABLE common.entity_links (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reference_id     UUID NOT NULL, -- vd: ID của Invoice, ID của Payment
    reference_type   VARCHAR(50) NOT NULL, -- vd: 'invoice', 'payment'
    item_id          UUID NOT NULL, -- ID của Comment hoặc Attachment
    item_type        VARCHAR(50) NOT NULL, -- 'comment' hoặc 'attachment'
    created_at       TIMESTAMP DEFAULT now(),
    UNIQUE(reference_id, reference_type, item_id, item_type)
);

-- 4. Audit Logs (Common) — Nhật ký hệ thống Common
CREATE TABLE common.audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name  VARCHAR(100) NOT NULL,
    record_id   UUID NOT NULL,
    action      VARCHAR(20) NOT NULL,   -- INSERT / UPDATE / DELETE
    changed_by  UUID, -- UUID từ Identity Service
    changed_at  TIMESTAMP DEFAULT now(),
    old_data    JSONB,
    new_data    JSONB
);

-- =============================================================================
-- INDEXES ĐỀ XUẤT
-- =============================================================================

-- Identity Service
CREATE INDEX idx_users_company                    ON identity.users(company_id);
CREATE INDEX idx_users_role                       ON identity.users(role_id);
CREATE INDEX idx_audit_logs_identity_record       ON identity.audit_logs(table_name, record_id);

-- Core Service
CREATE INDEX idx_accounts_company                 ON core.accounts(company_id);
CREATE INDEX idx_partners_company                 ON core.partners(company_id);
CREATE INDEX idx_journal_entries_company          ON core.journal_entries(company_id);
CREATE INDEX idx_journal_entries_period           ON core.journal_entries(period_id);
CREATE INDEX idx_journal_entries_date             ON core.journal_entries(entry_date);
CREATE INDEX idx_invoices_company                 ON core.invoices(company_id);
CREATE INDEX idx_invoices_partner                 ON core.invoices(partner_id);
CREATE INDEX idx_invoices_type_status             ON core.invoices(invoice_type, status);
CREATE INDEX idx_invoices_due_date                ON core.invoices(due_date);
CREATE INDEX idx_payments_company                 ON core.payments(company_id);
CREATE INDEX idx_payments_invoice                 ON core.payments(invoice_id);
CREATE INDEX idx_bank_transactions_account        ON core.bank_transactions(bank_account_id);
CREATE INDEX idx_bank_transactions_reconciled     ON core.bank_transactions(is_reconciled);
CREATE INDEX idx_audit_logs_core_record           ON core.audit_logs(table_name, record_id);

-- Common Service
CREATE INDEX idx_attachments_company              ON common.attachments(company_id);
CREATE INDEX idx_entity_links_ref                 ON common.entity_links(reference_type, reference_id);
CREATE INDEX idx_entity_links_item                ON common.entity_links(item_type, item_id);
CREATE INDEX idx_audit_logs_common_record         ON common.audit_logs(table_name, record_id);
