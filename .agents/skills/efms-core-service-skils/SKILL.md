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
- **Invoices (AP Bill / AR Invoice)**: Tạo, trình duyệt qua Camunda, và theo dõi trạng thái hóa đơn.
- **Payments**: Ghi nhận thanh toán (Cash In/Out), phân bổ vào hóa đơn, post lên Sổ cái.
- **Bank Accounts**: Quản lý tài khoản ngân hàng dùng làm nguồn tiền cho Payments.
- **Journal Entries (Read-only)**: Xem danh sách bút toán kép được hệ thống tự động sinh ra.

---

## Core Database Schema
> DB Schema vẫn giữ nguyên đầy đủ. Các bảng không dùng (xem bên dưới) chỉ bị bỏ qua ở tầng Application.

- `accounts`: Chart of accounts (asset, liability, equity, revenue, expense).
- `partners`: Customers and vendors.
- `journal_entries` & `journal_lines`: Double-entry accounting records — **chỉ ghi bởi hệ thống**, không cho phép nhập tay.
- `invoices` & `invoice_lines`: Receivables (AR) and payables (AP) tracking.
- `payments` & `invoice_payments`: Bank/cash operations and allocation mapping to invoices.
- `bank_accounts`: Bank accounts used as funding sources for payments.
- `fiscal_periods` *(schema only)*: Tồn tại trong DB nhưng không có ORM mapping hay UI/API ở phạm vi đồ án.
- `bank_transactions` *(schema only)*: Tồn tại trong DB nhưng không có ORM mapping hay UI/API ở phạm vi đồ án.

---

## Workflow & Automation (Camunda 8)
- **Engine**: Integrates with Camunda 8 SaaS via `camunda-spring-boot-starter` (8.8.x).
- **Process Instances**: Khởi động trong `InvoiceService.confirm()` cho AP Bill qua `camundaClient.newCreateInstanceCommand()`.
- **User Tasks**: Lấy danh sách Task đang chờ duyệt dùng **Tasklist API v1** trong `InvoiceService.getAllApprovalTasks(page, size)`. Backend tự map Task → Invoice và trả `PagedResponse<InvoiceResponse>` kèm `taskId`, `taskName`. Complete task dùng **Zeebe REST API v2** (`/v2/user-tasks/{taskId}/completion`).
- **Job Workers** (`service/worker/`):
  - `CreateJournalEntryWorker` (type: `create-journal-entry`): Được trigger khi Invoice được **Duyệt**. Cập nhật `approval_status = approved` và **phải gọi `JournalService.createFromInvoice()`** để sinh bút toán kép tự động — (**⚠️ TODO chưa implement**).
  - `NotifyRejectionWorker` (type: `notify-rejection`): Cập nhật `approval_status = rejected` khi bị từ chối.
- **Variables**: Context truyền qua `Map` (e.g., `approved`, `totalAmount`, `invoiceId`). Kết quả worker phải được map lại vào DB (`approval_status`, `camunda_process_id`).

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
| **Invoice Approvals** | `GET/POST /v1/invoice-tasks` | Lấy task chờ duyệt & hành động duyệt/từ chối |
| **Payments** | `GET/POST/PUT/DELETE /v1/payments` | CRUD thanh toán |
| | `POST /v1/payments/{id}/post` | Post payment → ghi Sổ cái |
| | `POST /v1/payments/{id}/allocate` | Phân bổ payment vào Invoice |

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
- **`service`**: Business logic, validation, gọi Camunda. **Không** check fiscal period (đã loại bỏ).
- **`service/worker`**: Chứa các `@JobWorker` class xử lý automated task từ Zeebe engine.
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

**DB Schema KHÔNG thay đổi** — Các bảng tương ứng vẫn tồn tại trong PostgreSQL để đảm bảo tính toàn vẹn và cho phép mở rộng sau này.
