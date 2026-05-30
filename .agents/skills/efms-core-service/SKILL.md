---
name: efms-core-service
description: Financial and accounting operations for EFMS.
---

# EFMS Core Service

The Core Service handles all major financial accounting operations, double-entry ledger automation, and cash flows. It is built with **Spring Boot 3** and integrates with **Camunda 8 SaaS** for approval workflows.

> **🎓 Đồ án Scope**: Module này đã được tinh gọn so với thiết kế ERP đầy đủ. Chỉ giữ các module thiết yếu cho luồng nghiệp vụ lõi (Procure-to-Pay). Xem mục cuối để biết chi tiết.

---

## Core Responsibilities (Active)
- **Chart of Accounts (COA)**: Quản lý danh mục tài khoản kế toán.
- **Partners**: Quản lý danh bạ Khách hàng (AR) và Nhà cung cấp (AP).
- **Invoices (AP Bill / AR Invoice)**: Tạo, phê duyệt qua DB state machine, và theo dõi trạng thái hóa đơn.
- **Payments**: Ghi nhận thanh toán (Cash In/Out) liên kết trực tiếp với hóa đơn, post lên Sổ cái.
- **Bank Accounts**: Quản lý tài khoản ngân hàng dùng làm nguồn tiền cho Payments.
- **Journal Entries (Read-only)**: Xem danh sách bút toán kép được hệ thống tự động sinh ra.

---

## Core Database Schema
> DB Schema vẫn giữ nguyên đầy đủ. Các bảng không dùng (xem bên dưới) chỉ bị bỏ qua ở tầng Application.

- `accounts`: Chart of accounts (asset, liability, equity, revenue, expense).
- `partners`: Customers and vendors.
- `journal_entries` & `journal_lines`: Double-entry accounting records — **chỉ ghi bởi hệ thống**, không cho phép nhập tay.
- `invoices` & `invoice_lines`: Receivables (AR) and payables (AP) tracking.
- `payments`: Bank/cash operations and single-invoice mapping (via `invoice_id`).
- `bank_accounts`: Bank accounts used as funding sources for payments.

---

## Approval Workflow (DB State Machine — Không dùng Camunda)
- **Không còn Camunda 8**: Quy trình phê duyệt AP Bill được quản lý hoàn toàn bằng trạng thái lưu trong DB.
- **Luồng trạng thái AP Bill**:
  - `draft` → `confirm()` → `status=open`, `approval_status=pending`
  - `open/pending` → `approve(comment?)` → `approval_status=approved` → (TODO: trigger tạo JournalEntry)
  - `open/pending` → `reject(comment?)` → `approval_status=rejected`
  - Bất kỳ → `cancel()` → `status=cancelled`
- **Luồng AR Invoice**: `draft` → `confirm()` → `status=open` (không cần phê duyệt).
- **Xem danh sách chờ duyệt**: `GET /v1/invoice-tasks/tasks?companyId=...` — filter `type=AP, status=open, approvalStatus=pending` trực tiếp từ DB.

---

## API Endpoints (v1)

**Context Path:** `http://localhost:8080/api/core` (routed via API Gateway)

| Module | Endpoints | Ghi chú |
|---|---|---|
| **Partners** | `GET/POST/PUT /v1/partners` | CRUD đối tác |
| **Bank Accounts** | `GET/POST/PUT /v1/finance/bank-accounts` | CRUD tài khoản ngân hàng |
| **Accounts (COA)** | `GET/POST/PUT /v1/accounting/accounts` | Chart of Accounts |
| **Journal Entries** | `GET /v1/accounting/journals` | **Read-only** — Chỉ xem danh sách & chi tiết |
| **Invoices** | `GET/POST/PUT/DELETE /v1/invoices` | CRUD AP/AR. Draft cho phép xóa |
| **Invoice Approvals** | `GET /v1/invoice-tasks/tasks?companyId=...` | Danh sách AP Bill chờ duyệt (filter DB) |
| | `GET /v1/invoice-tasks/tasks/{invoiceId}/invoice` | Chi tiết hóa đơn chờ duyệt |
| | `POST /v1/invoices/{id}/approve?comment=...` | Phê duyệt AP Bill |
| | `POST /v1/invoices/{id}/reject?comment=...` | Từ chối AP Bill |
| **Payments** | `GET/POST/PUT/DELETE /v1/payments` | CRUD thanh toán |
| | `POST /v1/payments/{id}/post` | Post payment → ghi Sổ cái |

> **Đã xóa khỏi codebase**: `/v1/finance/bank-transactions`, `/v1/finance/reconciliation`, `/v1/accounting/fiscal-periods`, `/v1/accounting/trial-balance`, `/v1/reports/*`

---

## Accounting Rules
- **Double-Entry**: Mọi `journal_entry` được tạo bởi hệ thống phải có ít nhất 2 `journal_lines`, trong đó tổng Nợ (Debit) bằng tổng Có (Credit).
- **Automated Journals Only**: Bút toán chỉ được sinh tự động qua `CreateJournalEntryWorker` (khi Invoice Approved) và `PaymentService.post()` (khi Payment Posted). **Không cho phép nhập tay**.
- **Draft vs Posted**: Giao dịch bắt đầu ở `draft`, phải qua bước `/post` để chính thức ghi nhận.
- **BigDecimal**: Bắt buộc dùng `BigDecimal` cho mọi giá trị tiền tệ.

---

## Implementation Details

- **Package**: `com.linhdv.efms_core_service`
- **Identity Links**: `company_id`, `created_by`, `updated_by` là `UUID` tham chiếu sang `efms-identity-service`. Không có FK database — isolation thực hiện bằng cách filter `companyId` trên tầng Service.
- **Security & Authorization**:
  - **`GatewayHeaderFilter`**: Filter tùy chỉnh đọc các header `X-User-*` do API Gateway inject vào.
  - **`SecurityContextHolder`**: Được populate với identity và authorities từ header `X-User-Permission`.
  - **Method Security**: `@PreAuthorize("hasAuthority('RESOURCE:ACTION')")` ở Controller/Service.

---

## Code Structure Rules
- **`controller`**: Nhóm theo domain: `controller.accounting`, `controller.finance`, `controller.invoice`. Luôn trả về `ApiResponse<T>`.
- **`service`**: Business logic, validation. **Không** dùng Camunda, **không** check fiscal period.
- **`service/accounting`**: Accounting service (Journal).
- **`service/finance`**: Finance service (Payment, BankAccount).
- **`repository`**: Truy vấn DB, luôn filter theo `companyId`.
- **`entity` / `dto` / `wrapper`**: Entity map 1-1 với table. DTO tách biệt request/response. Dùng `ApiResponse<T>` và `PagedResponse<T>` làm wrapper chuẩn.

---

## Guidelines
1. **KHÔNG** check `fiscal_period` — Validation này đã bị loại bỏ ở phạm vi đồ án.
2. Validate `@Valid` trên tất cả `xxxRequest` DTO đầu vào.
3. Mọi thay đổi tài chính nên được ghi vào `audit_logs` nếu có thời gian.

---

## 🎓 Thesis Scope Adaptations — Những thứ đã lược bỏ

Các module sau đã bị **xóa hoàn toàn khỏi codebase** (Controller, Service, Repository, DTO, Entity):

| Module đã xóa | Lý do |
|---|---|
| `FiscalPeriod` (Controller, Service, Repo, Entity) | Quá phức tạp, không cần cho demo |
| `TrialBalance` (Controller, Service, DTO) | Gộp vào Dashboard frontend |
| `BankTransaction` (Controller, Service, Repo, Entity) | Không cần nhập sao kê ngân hàng |
| `Reconciliation` (Controller, Service) | Nghiệp vụ quá phức tạp |
| `Report` (Controller, Service, toàn bộ thư mục) | Gộp vào Dashboard frontend |
| Manual Journal Entry (POST/PUT/DELETE `/journals`) | Bút toán chỉ được sinh tự động |

**DB Schema đã được cập nhật** — Các bảng `fiscal_periods` và `bank_transactions` đã bị loại bỏ hoàn toàn khỏi thiết kế CSDL (PostgreSQL).

---

## 🎓 Quy chuẩn Code & Sử dụng Context (MCP Server)

Khi làm việc với code, architecture, hoặc debug module **EFMS Core Service**, bạn **phải** sử dụng **MCP Server `codegraph-efms-core-service`** để lấy context toàn diện và chính xác nhất.
- Khởi động/kết nối MCP Server `codegraph-efms-core-service` (lệnh `codegraph serve --mcp` với thư mục `/Users/linhofthenorth/VietLinh/efms-project-info/efms-core-service`).
- Luôn ưu tiên dùng các tool do server này cung cấp (như `codegraph_search`, `codegraph_context`, `codegraph_callers`, `codegraph_callees`, `codegraph_impact`) thay vì tìm kiếm (grep) thủ công để tiết kiệm context window và tăng độ chính xác.
