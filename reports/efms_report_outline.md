# Cấu trúc Báo cáo Đồ án Hệ thống EFMS (Cập nhật Tích hợp MCP Server)

**− LỜI CẢM ƠN**
**− Lời cam đoan**
**− Lời mở đầu**
*   A. Tính cấp thiết
*   B. Phạm vi hệ thống EFMS
*   C. Cấu trúc chuyên đề

**CHƯƠNG 1. CƠ SỞ LÝ THUYẾT VÀ CÔNG NGHỆ ỨNG DỤNG**
1.1. Kiến trúc hệ thống phân tán (Microservices)
*   1.1.1. Khái niệm và mô hình Microservices
*   1.1.2. Vai trò của API Gateway trong định tuyến và bảo mật
*   1.1.3. Mô hình Multi-tenancy (Đa công ty/chi nhánh)
1.2. Front-End
*   1.2.1. React.js và Vite
*   1.2.2. React Router
*   1.2.3. Thư viện giao diện (Shadcn UI & Tailwind CSS)
*   1.2.4. Quản lý trạng thái và liên kết API (Axios/Fetch)
1.3. Back-End
*   1.3.1. Framework Java Spring Boot
*   1.3.2. Kiến trúc Layered (Controller - Service - Repository)
*   1.3.3. JSON Web Token (JWT) trong xác thực và phân quyền
*   1.3.4. Camunda 8 SaaS và BPMN (Công cụ quản lý luồng quy trình)
*   1.3.5. Hệ thống Job Worker (Spring Zeebe SDK)
1.4. Công nghệ Trợ lý AI và Model Context Protocol (MCP)
*   1.4.1. Khái niệm Model Context Protocol (MCP)
*   1.4.2. Khả năng giao tiếp giữa LLMs và hệ thống doanh nghiệp (Resources, Tools, Prompts)
1.5. Hệ quản trị cơ sở dữ liệu
*   1.5.1. PostgreSQL
1.6. Kiểm thử phần mềm
*   1.6.1. Giới thiệu kiểm thử hộp đen và kiểm thử API

**CHƯƠNG 2. PHÂN TÍCH ĐẶC TẢ CHỨC NĂNG CỦA HỆ THỐNG EFMS**
2.1. Kiến trúc tổng thể hệ thống
*   2.1.1. Sơ đồ System Context (Client, Gateway, Identity, Core, Camunda, MCP Server)
*   2.1.2. Giao tiếp giữa các Dịch vụ (Service-to-Service Communication)
2.2. Yêu cầu hệ thống
*   2.2.1. Yêu cầu chức năng
*   2.2.2. Yêu cầu phi chức năng (Bảo mật, cách ly dữ liệu an toàn)
2.3. Usecase Hệ thống
*   2.3.1. Tác nhân hệ thống (Accountant, Finance Manager, Admin, AI Assistant Agent)
*   2.3.2. Biểu đồ Usecase tổng quát
*   2.3.3. Biểu đồ Usecase phân rã theo nhóm Dịch vụ (Identity, Core & AI Assistant)
2.4. Đặc tả chức năng phân hệ Identity (Identity Service)
*   2.4.1. UC#01: Xác thực người dùng (Đăng nhập, Đăng xuất)
*   2.4.2. UC#02: Phân quyền vai trò hệ thống (RBAC)
*   2.4.3. UC#03: Quản lý Hồ sơ người dùng
*   2.4.4. UC#04: Quản lý Công ty (Multi-Company)
2.5. Đặc tả chức năng phân hệ Kế toán (Core Service)
*   2.5.1. UC#05: Quản lý Đối tác (Khách hàng & Nhà cung cấp)
*   2.5.2. UC#06: Thiết lập Hệ thống Tài khoản Kế toán (Chart of Accounts)
*   2.5.3. UC#07: Quản lý Hóa đơn mua vào (AP Bill)
*   2.5.4. UC#08: Phê duyệt chuyển cấp Hóa đơn (AP Bill Approval Workflow)
*   2.5.5. UC#09: Tự động khởi tạo bút toán (Journal Entry)
*   2.5.6. UC#10: Báo cáo & Thống kê tài chính
2.6. Đặc tả chức năng phân hệ Tích hợp AI (MCP Server)
*   2.6.1. Tham chiếu Bối cảnh Dữ liệu (Context/Resources): Đọc hoá đơn, sổ cái, biểu đồ tài khoản.
*   2.6.2. Function Calling (Tools): AI tra cứu tác vụ, duyệt tự động (approve_ap_bill), sinh bút toán dự thảo (draft_journal_entry).
*   2.6.3. Trợ lý Kịch bản Đóng gói (Prompts): Tư vấn hỗ trợ duyệt hoá đơn, đối soát ngân hàng.

**CHƯƠNG 3. THIẾT KẾ CHỨC NĂNG VÀ CƠ SỞ DỮ LIỆU**
3.1. Các biểu đồ thiết kế quy trình nghiệp vụ
*   3.1.1. Biểu đồ tuần tự chức năng Đăng nhập & Xác thực JWT qua Gateway
*   3.1.2. Biểu đồ BPMN (Luồng hoạt động trên Camunda) phê duyệt AP Bill
*   3.1.3. Biểu đồ tuần tự luồng tương tác giữa Core Service và Camunda SaaS
*   3.1.4. Biểu đồ tuần tự Job Worker tự động sinh bút toán kép (Dr/Cr)
3.2. Thiết kế tích hợp Model Context Protocol (MCP Server)
*   3.2.1. Tầng Giao tiếp Transport (Local Sidecar / Spring Boot Native SSE)
*   3.2.2. Thiết kế Custom Resources Scheme (efms-core://database/schema-v4, efms-core://invoices/...)
*   3.2.3. Ràng buộc bảo mật Context & Định dạng đa nhóm (Multi-Company Authentication cho AI)
3.3. Thiết kế Cơ sở dữ liệu
*   3.3.1. Ràng buộc thiết kế theo Multi-tenancy (Company_ID isolation)
*   3.3.2. Cấu trúc bảng phân hệ Identity (Users, Roles, Company...)
*   3.3.3. Cấu trúc bảng phân hệ Core (Invoices, Invoice Lines, Journal Entries...)
*   3.3.4. Chi tiết các trường dữ liệu quan trọng

**CHƯƠNG 4. KIỂM THỬ VÀ TRIỂN KHAI HỆ THỐNG**
4.1. Kiểm thử phần mềm
*   4.1.1. Phân tích các trường hợp kiểm thử (Testcase)
*   4.1.2. Danh sách Testcase nghiệp vụ Hóa đơn và Luồng phê duyệt
*   4.1.3. Thử nghiệm thực thi tương tác giữa MCP Client (AI Assistant) và MCP Core Server
4.2. Yêu cầu và Môi trường Cài đặt
*   4.2.1. Yêu cầu cấu hình (Camunda Cloud, Database Postgres)
*   4.2.2. Cài đặt các Dịch vụ Backend (Identity Service, Core Service, Gateway, MCP Server Runtime)
*   4.2.3. Cài đặt môi trường Frontend
4.3. Kết quả thực nghiệm hệ thống
*   4.3.1. Giao diện Xác thực & Xử lý Profile
*   4.3.2. Giao diện Bảng điều khiển (Dashboard Kế toán)
*   4.3.3. Giao diện Quản lý Danh sách và Chi tiết Hóa đơn (AP Bill)
*   4.3.4. Giao diện Tương tác Phê duyệt cho Finance Manager
*   4.3.5. Giao diện Xác nhận sổ nhật ký bút toán (Journal Entries)
*   4.3.6. Log tương tác: Trợ lý AI rà soát và ra lệnh Approve hóa đơn qua MCP Tools

**CHƯƠNG 5. KẾT LUẬN**
5.1. Kết quả đạt được (Kiến trúc Microservices, Quản trị luồng Camunda & Trợ lý thông minh MCP AI)
5.2. Điểm hạn chế
5.3. Hướng phát triển tương lai

**− Tài liệu tham khảo**
**− Phụ lục** (Sơ đồ API thiết kế, Scripts Migrate DB, Config Template, Danh sách JSON Schema các MCP Tools, v.v.)
