# Tài liệu Mô tả Luồng Nghiệp vụ và Phân quyền Hệ thống EFMS (Dựa trên Frontend Active)

Tài liệu này ánh xạ các màn hình (screens) đang được kích hoạt trên Frontend (React) với luồng nghiệp vụ tương ứng trong backend và các quyền hạn (permissions) cần thiết của User/Role để thực hiện.

---

## 1. Các Vai trò & Quyền hạn tham khảo (Roles & Permissions)
Hệ thống EFMS áp dụng cơ chế Role-Based Access Control (RBAC) với mô hình đa doanh nghiệp (Multi-tenant). Mỗi User thuộc một `company_id` và được gán một Role cụ thể.
Các quyền (Authorities) được định nghĩa theo cấu trúc `RESOURCE:ACTION` (VD: `INVOICE:CREATE`).

### Các Role tiêu biểu:
1. **System Admin / Company Admin**: Có toàn quyền hệ thống (`*:*` hoặc tất cả các quyền). Quản trị người dùng, vai trò, cài đặt hệ thống và duyệt các khoản chi lớn.
2. **Finance Manager (Quản lý tài chính)**: Quản lý và phê duyệt cuối cùng (hoặc cấp 1) cho các chứng từ, hoá đơn, thanh toán. Quyền tiêu biểu: `INVOICE:FINANCE_MANAGER_REVIEW`, `PAYMENTS:UPDATE`, `BANKACC:UPDATE`.
3. **Accountant (Kế toán viên)**: Phụ trách tạo chứng từ, hoá đơn, đối tác, và ghi nhận thanh toán. Quyền tiêu biểu: `INVOICE:CREATE`, `INVOICE:READ`, `PAYMENTS:CREATE`, `PARTNERS:CREATE`.
4. **Regular User (Nhân viên)**: Tuỳ thuộc phòng ban, có thể chỉ có quyền Xem (`READ`) hoặc tạo yêu cầu (`CREATE` draft).

---

## 2. Phân rã Luồng Nghiệp vụ theo Màn hình (Active Screens)

Dựa trên thanh điều hướng (`AppSidebar`), hệ thống hiện đang active các phân hệ và màn hình sau:

### 2.1. Phân hệ Chứng từ (Vouchers & Invoices)
Đây là luồng nghiệp vụ lõi (Core Business Flow) hiện tại của hệ thống, quản lý công nợ và dòng tiền.

#### A. Màn hình Đối tác (Partners)
*   **Đường dẫn:** `/partners`
*   **Luồng nghiệp vụ:** Quản lý danh bạ Khách hàng (Customer) và Nhà cung cấp (Vendor). Là dữ liệu gốc bắt buộc phải có trước khi tạo Hoá đơn hay Thanh toán.
*   **Quyền hạn cần thiết:** 
    *   Xem danh sách: `PARTNERS:READ`
    *   Tạo/Sửa: `PARTNERS:CREATE`, `PARTNERS:UPDATE`

#### B. Màn hình Hóa đơn & Chứng từ (Invoices)
*   **Đường dẫn:** `/invoices`, `/invoices/create`, `/invoices/:id/edit`
*   **Luồng nghiệp vụ:** 
    *   **Tạo mới (Draft):** Kế toán viên tạo AP Bill (Hoá đơn phải trả) hoặc AR Invoice (Hoá đơn phải thu). Trạng thái ban đầu là `Draft`.
    *   **Quy trình Duyệt (Camunda Workflow):** Khi bấm xác nhận, hoá đơn đi vào luồng duyệt.
        *   Cấp 1: **Finance Manager** duyệt.
        *   Cấp 2: Nếu tổng tiền `> 100,000,000 VND`, hệ thống (qua Camunda Gateway) yêu cầu **Admin** duyệt thêm.
    *   **Thành công (Approved):** Hoá đơn tự động sinh bút toán (Journal Entry) thông qua Job Worker và chờ thanh toán.
*   **Quyền hạn cần thiết:**
    *   Truy cập/Xem: `INVOICE:READ`
    *   Tạo mới/Chỉnh sửa: `INVOICE:CREATE`, `INVOICE:UPDATE`
    *   Phê duyệt: `INVOICE:FINANCE_MANAGER_REVIEW`
    *   Huỷ/Xoá (khi ở Draft): `INVOICE:CANCEL`, `INVOICE:DELETE`

#### C. Màn hình Thanh toán (Payments)
*   **Đường dẫn:** `/payments`, `/payments/new`, `/payments/:id/edit`
*   **Luồng nghiệp vụ:** 
    *   Ghi nhận luồng tiền thực tế (Cash In / Cash Out).
    *   Thanh toán chỉ được thực hiện dựa trên các Hoá đơn (Invoices) đã ở trạng thái `Approved`.
    *   **Allocate (Phân bổ):** User có thể thanh toán một phần hoặc toàn bộ hoá đơn.
    *   **Post:** Bước cuối cùng để ghi sổ cái (General Ledger) cho khoản thanh toán này.
*   **Quyền hạn cần thiết:**
    *   Truy cập/Xem: `PAYMENTS:READ`
    *   Tạo mới/Phân bổ: `PAYMENTS:CREATE`, `PAYMENTS:UPDATE`
    *   Xoá (trước khi Post): `PAYMENTS:DELETE`

---

### 2.2. Phân hệ Kế toán (Accounting)

#### A. Hệ thống tài khoản (Chart of Accounts)
*   **Đường dẫn:** `/accounting/accounts`
*   **Luồng nghiệp vụ:** Xem và quản lý Danh mục Tài khoản kế toán (COA) của Công ty. Bao gồm các tài khoản Tài sản, Nợ, Vốn chủ, Doanh thu, Chi phí.
*   **Quyền hạn cần thiết:** `ACCOUNTS:READ` (và `ACCOUNTS:CREATE` / `UPDATE` nếu có chức năng sửa).

*(Lưu ý đối với Đồ án: Màn hình Bút toán nhật ký được giữ ở dạng Chỉ xem (Read-only) để minh chứng khả năng tự động sinh Bút toán kép từ hệ thống. Các Báo cáo kế toán chuyên sâu như Bảng cân đối thử được lược bỏ, thay vào đó sẽ gom số liệu hiển thị trực tiếp lên Dashboard tổng quan).*

---

### 2.3. Phân hệ Tiền mặt & Ngân hàng (Cash & Bank)

#### A. Tài khoản ngân hàng (Bank Accounts)
*   **Đường dẫn:** `/finance/accounts`
*   **Luồng nghiệp vụ:** Quản lý các tài khoản ngân hàng thực tế của doanh nghiệp (VD: Vietcombank, Techcombank). Dữ liệu này được liên kết làm nguồn tiền khi thực hiện tạo `Payments`.
*   **Quyền hạn cần thiết:**
    *   Truy cập/Xem: `BANKACC:READ`
    *   Tạo mới/Cập nhật: `BANKACC:CREATE`, `BANKACC:UPDATE`

*(Lưu ý đối với Đồ án: Các nghiệp vụ phức tạp như Lịch sử giao dịch, Đối soát ngân hàng và Quản lý Kỳ kế toán (Fiscal Periods) đã được lược bỏ khỏi phạm vi UI nhằm tập trung làm nổi bật luồng nghiệp vụ Phê duyệt Hoá đơn và Thanh toán).*

---

### 2.4. Phân hệ Cấu hình & Quản trị (Settings & Admin)

Luồng nghiệp vụ cấu hình hệ thống, thường chỉ dành cho Admin hoặc Manager.

#### A. Quản trị Cấu hình (Settings)
*   **Đường dẫn:** `/settings/user`, `/settings/company`, `/settings/mcp`
*   **Luồng nghiệp vụ:** Cập nhật hồ sơ cá nhân (User Settings), thiết lập thông tin Doanh nghiệp gốc (Company Settings - dùng để in ấn báo cáo), và cấu hình tích hợp Claude AI (MCP Settings).
*   **Quyền hạn:** Mọi user có thể xem/sửa User Settings của mình. Company & MCP Settings yêu cầu quyền Admin.

#### B. Quản trị Người dùng và Phân quyền (Admin)
*   **Đường dẫn:** `/admin/users`, `/admin/roles-permissions`
*   **Luồng nghiệp vụ:** 
    *   Tạo người dùng mới, vô hiệu hoá nhân viên nghỉ việc.
    *   Tạo các Role (Vai trò) tuỳ chỉnh và map các Permissions (`RESOURCE:ACTION`) vào Role đó.
*   **Quyền hạn:** Bắt buộc phải có Role `ADMIN` cấp hệ thống. Các API này nằm ở Identity Service và yêu cầu bảo mật cao nhất.
