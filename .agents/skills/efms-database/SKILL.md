---
name: efms-database
description: Reference for the EFMS (Enterprise Financial Management System) PostgreSQL v4 schema. Contains full table fields and relationships.
---

# EFMS Database Schema (v4)

This skill provides a detailed reference for the PostgreSQL v4 database schema used in the EFMS application.

## Key Principles
- **UUID Keys**: All primary keys (`id`) use the `gen_random_uuid()` function.
- **Audit Logging**: Use `JSONB` for `old_data` and `new_data` columns in audit tables.
- **Precision**: Monetary amounts use `NUMERIC(18,2)`, exchange rates use `NUMERIC(18,6)`.
- **Foreign Keys across schemas**: Foreign keys to Identity entities (e.g., `company_id`, `created_by`) are NOT enforced at the database level across schemas, but handled at the application level.

---

## 1. EFMS Identity Service (`identity` schema)
Database responsible for organizations, users, and permissions.

### `identity.companies`
- `id` (UUID, PK)
- `name` (VARCHAR 255)
- `tax_code` (VARCHAR 50)
- `address` (TEXT)
- `currency` (VARCHAR 3, Default 'VND')
- `is_active` (BOOLEAN, Default TRUE)
- `created_at` (TIMESTAMP)

### `identity.roles`
- `id` (UUID, PK)
- `name` (VARCHAR 100)
- `description` (TEXT)
- `is_active` (BOOLEAN, Default TRUE)
- `created_at` (TIMESTAMP)

### `identity.permissions`
- `id` (UUID, PK)
- `resource` (VARCHAR 100)
- `action` (VARCHAR 50)
- `description` (TEXT)
- `created_at` (TIMESTAMP)

### `identity.role_permissions`
- `role_id` (UUID, FK -> `identity.roles`)
- `permission_id` (UUID, FK -> `identity.permissions`)
- `created_at` (TIMESTAMP)
- *PK: (role_id, permission_id)*

### `identity.users`
- `id` (UUID, PK)
- `company_id` (UUID, FK -> `identity.companies`)
- `role_id` (UUID, FK -> `identity.roles`)
- `name` (VARCHAR 255)
- `email` (VARCHAR 255, UNIQUE)
- `password` (VARCHAR 255)
- `is_active` (BOOLEAN, Default TRUE)
- `created_at` (TIMESTAMP)

### `identity.audit_logs`
- `id` (UUID, PK)
- `table_name` (VARCHAR 100)
- `record_id` (UUID)
- `action` (VARCHAR 20)
- `changed_by` (UUID, FK -> `identity.users`)
- `changed_at` (TIMESTAMP)
- `old_data` (JSONB)
- `new_data` (JSONB)

---

## 2. EFMS Core Service (`core` schema)
Database containing accounting and financial data. Note: `fiscal_periods` and `bank_transactions` have been removed.

### `core.accounts` (Chart of Accounts)
- `id` (UUID, PK)
- `company_id` (UUID) - *Indexed*
- `code` (VARCHAR 20)
- `name` (VARCHAR 255)
- `type` (VARCHAR 50)
- `balance_type` (VARCHAR 10)
- `parent_id` (UUID, FK -> `core.accounts`)
- `is_active` (BOOLEAN, Default TRUE)
- `created_at` (TIMESTAMP)
- *UNIQUE(company_id, code)*

### `core.bank_accounts`
- `id` (UUID, PK)
- `company_id` (UUID)
- `name` (VARCHAR 255)
- `bank_name` (VARCHAR 255)
- `account_number` (VARCHAR 100)
- `type` (VARCHAR 20)
- `currency_code` (VARCHAR 3, Default 'VND')
- `opening_balance` (NUMERIC 18,2)
- `gl_account_id` (UUID, FK -> `core.accounts`)
- `is_active` (BOOLEAN, Default TRUE)
- `created_at` (TIMESTAMP)

### `core.partners` (Customers/Vendors)
- `id` (UUID, PK)
- `company_id` (UUID) - *Indexed*
- `name` (VARCHAR 255)
- `type` (VARCHAR 20)
- `tax_code` (VARCHAR 50)
- `phone` (VARCHAR 50)
- `email` (VARCHAR 255)
- `address` (TEXT)
- `ar_account_id` (UUID, FK -> `core.accounts`)
- `ap_account_id` (UUID, FK -> `core.accounts`)
- `is_active` (BOOLEAN, Default TRUE)
- `created_at` (TIMESTAMP)

### `core.journal_entries`
- `id` (UUID, PK)
- `company_id` (UUID) - *Indexed*
- `period_id` (UUID) - *Indexed*
- `entry_date` (DATE) - *Indexed*
- `reference` (VARCHAR 255)
- `description` (TEXT)
- `status` (VARCHAR 20, Default 'draft')
- `source` (VARCHAR 50)
- `source_ref_id` (UUID)
- `created_by` (UUID)
- `posted_by` (UUID)
- `posted_at` (TIMESTAMP)
- `created_at` (TIMESTAMP)

### `core.journal_lines`
- `id` (UUID, PK)
- `journal_entry_id` (UUID, FK -> `core.journal_entries` ON DELETE CASCADE)
- `account_id` (UUID, FK -> `core.accounts`)
- `partner_id` (UUID, FK -> `core.partners`)
- `debit` (NUMERIC 18,2, Default 0)
- `credit` (NUMERIC 18,2, Default 0)
- `currency_code` (VARCHAR 3, Default 'VND')
- `amount_currency` (NUMERIC 18,2)
- `exchange_rate` (NUMERIC 18,6, Default 1)
- `description` (TEXT)
- `created_at` (TIMESTAMP)
- *Constraints: debit >= 0, credit >= 0, not both > 0*

### `core.invoices`
- `id` (UUID, PK)
- `company_id` (UUID) - *Indexed*
- `partner_id` (UUID, FK -> `core.partners`) - *Indexed*
- `invoice_type` (VARCHAR 5) - *Indexed with status*
- `invoice_number` (VARCHAR 100)
- `invoice_date` (DATE)
- `due_date` (DATE) - *Indexed*
- `currency_code` (VARCHAR 3, Default 'VND')
- `exchange_rate` (NUMERIC 18,6, Default 1)
- `subtotal` (NUMERIC 18,2, Default 0)
- `tax_amount` (NUMERIC 18,2, Default 0)
- `total_amount` (NUMERIC 18,2, Default 0)
- `paid_amount` (NUMERIC 18,2, Default 0)
- `status` (VARCHAR 20, Default 'draft')
- `approval_status` (VARCHAR 20)
- `approval_comment` (TEXT)
- `journal_entry_id` (UUID, FK -> `core.journal_entries`)
- `created_by` (UUID)
- `created_at` (TIMESTAMP)

### `core.invoice_lines`
- `id` (UUID, PK)
- `invoice_id` (UUID, FK -> `core.invoices` ON DELETE CASCADE)
- `account_id` (UUID, FK -> `core.accounts`)
- `description` (TEXT)
- `quantity` (NUMERIC 10,2, Default 1)
- `unit_price` (NUMERIC 18,2, Default 0)
- `tax_rate` (NUMERIC 5,2, Default 0)
- `tax_amount` (NUMERIC 18,2, Default 0)
- `amount` (NUMERIC 18,2, Default 0)

### `core.payments`
- `id` (UUID, PK)
- `company_id` (UUID) - *Indexed*
- `partner_id` (UUID, FK -> `core.partners`)
- `invoice_id` (UUID, FK -> `core.invoices`) - *Indexed*
- `payment_type` (VARCHAR 10)
- `payment_date` (DATE)
- `currency_code` (VARCHAR 3, Default 'VND')
- `exchange_rate` (NUMERIC 18,6, Default 1)
- `amount` (NUMERIC 18,2)
- `payment_method` (VARCHAR 50)
- `bank_account_id` (UUID, FK -> `core.bank_accounts`)
- `reference` (VARCHAR 255)
- `journal_entry_id` (UUID, FK -> `core.journal_entries`)
- `created_by` (UUID)
- `created_at` (TIMESTAMP)

### `core.audit_logs`
- `id` (UUID, PK)
- `table_name` (VARCHAR 100)
- `record_id` (UUID)
- `action` (VARCHAR 20)
- `changed_by` (UUID)
- `changed_at` (TIMESTAMP)
- `old_data` (JSONB)
- `new_data` (JSONB)
- *Index: table_name, record_id*

---

## 3. EFMS Common Service (`common` schema)
Database handling document, attachments, and internal communications for any entity without hard foreign keys.

### `common.attachments`
- `id` (UUID, PK)
- `company_id` (UUID)
- `file_name` (VARCHAR 255)
- `file_type` (VARCHAR 100)
- `file_size` (BIGINT)
- `file_url` (TEXT)
- `created_by` (UUID)
- `created_at` (TIMESTAMP)

### `common.comments`
- `id` (UUID, PK)
- `company_id` (UUID)
- `content` (TEXT)
- `author_id` (UUID)
- `created_at` (TIMESTAMP)

### `common.entity_links`
- `id` (UUID, PK)
- `reference_id` (UUID) - *Indexed with reference_type*
- `reference_type` (VARCHAR 50)
- `item_id` (UUID) - *Indexed with item_type*
- `item_type` (VARCHAR 50)
- `created_at` (TIMESTAMP)
- *UNIQUE(reference_id, reference_type, item_id, item_type)*

### `common.audit_logs`
- `id` (UUID, PK)
- `table_name` (VARCHAR 100)
- `record_id` (UUID)
- `action` (VARCHAR 20)
- `changed_by` (UUID)
- `changed_at` (TIMESTAMP)
- `old_data` (JSONB)
- `new_data` (JSONB)

---

## Sử dụng Context (MCP Servers)
Khi cần tìm kiếm các Entity, Repository hay luồng lưu trữ xuống DB của các dịch vụ, hãy sử dụng **Codegraph MCP Server** của module tương ứng:
- Ví dụ: cần xem cấu trúc code mapping với `journal_entries`, sử dụng tool của `codegraph-efms-core-service`.
- Điều này giúp tiết kiệm context window và đạt hiệu năng cao thay vì text-search qua toàn bộ mã nguồn.
