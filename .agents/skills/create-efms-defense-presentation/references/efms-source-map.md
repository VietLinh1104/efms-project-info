# Bản đồ nguồn EFMS

Nguồn chính: `assets/efms-thesis-report.pdf` gồm 95 trang PDF.

## Thông tin đề tài

- Tên đề tài: Xây dựng hệ thống quản lý tài chính nội bộ doanh nghiệp tích hợp trợ lý AI Agent.
- Sinh viên: Đinh Việt Linh.
- Ngành: Hệ thống thông tin.
- Giảng viên hướng dẫn: Lê Thị Chi.
- Trường Đại học Công nghệ Giao thông Vận tải, Khoa Công nghệ thông tin.
- Năm: 2026.

## Trang nguồn theo chủ đề

| Chủ đề | Trang PDF |
|---|---:|
| Lý do, mục tiêu, phạm vi | 9-12 |
| Microservices và multi-tenancy | 12-14 |
| Frontend, backend, JWT | 14-16 |
| MCP, OAuth 2.1, PostgreSQL | 16-18 |
| Chuẩn API, audit, kiểm thử nền tảng | 18-20 |
| Khảo sát, tác nhân, use case tổng quát | 21-23 |
| Identity và RBAC | 23-31 |
| Core Service và tài khoản kế toán | 31-38 |
| Hóa đơn, phê duyệt, attachment/comment | 38-43 |
| Đối tác, báo cáo, tài khoản ngân hàng | 43-51 |
| Sequence diagrams | 52-61 |
| Activity diagrams, gồm AP Bill | 61-63 |
| Mô hình dữ liệu Identity | 64-67 |
| Mô hình dữ liệu Core | 67-76 |
| Mô hình dữ liệu Common | 76-79 |
| Triển khai, kiến trúc, bảo mật | 80-82 |
| Giao diện | 82-90 |
| Kiểm thử | 90-92 |
| Kết luận, hạn chế, hướng phát triển | 93-94 |

## Nội dung đã triển khai được xác nhận

- Bốn dịch vụ REST: API Gateway `8080`, Identity `8081`, Core `8082`, Common `8083`.
- React, Java 21, Spring Boot 3.3.x, Spring Cloud và PostgreSQL.
- JWT stateless, gateway inject header, downstream SecurityContext và RBAC `@PreAuthorize`.
- Quản lý doanh nghiệp, người dùng, vai trò và quyền.
- Quản lý đối tác, hệ thống tài khoản, tài khoản ngân hàng, hóa đơn AP/AR và thanh toán.
- Quy trình AP Bill hiện dùng DB State Machine.
- Sinh bút toán kép tự động khi nghiệp vụ phù hợp được duyệt/ghi sổ.
- Attachments, comments và audit logs.
- Claude AI kết nối qua MCP Server để tra cứu/phân tích bằng ngôn ngữ tự nhiên.
- Các test case được báo cáo là đạt cho đăng nhập, tạo người dùng và AP Bill.

## Điểm nhấn kỹ thuật

- Gateway là single entry point.
- Cô lập dữ liệu theo `company_id` xuyên suốt request.
- Batch endpoint `/internal/users/batch` giảm gọi chéo từ O(N) xuống O(1) theo số lần gọi service.
- `BigDecimal`/`NUMERIC(18,2)` cho tiền tệ.
- UUID cho định danh phân tán.
- Audit log lưu `old_data` và `new_data` bằng JSONB.
- Common Service dùng `entity_links` để liên kết đa hình, tránh foreign key chéo service.
- AI chỉ được truy cập qua tool có schema và quyền; người dùng có thẩm quyền quyết định cuối cùng.

## Mâu thuẫn phải xử lý

### Camunda 8

- Chương 1 và phần use case mô tả Camunda như mục tiêu hoặc thiết kế.
- Chương 4 nói triển khai hiện tại dùng DB State Machine.
- Kết luận xác nhận Camunda 8 chưa được tích hợp.

Khi thuyết trình, nói: "Camunda 8 là hướng thiết kế/mở rộng; phiên bản đồ án hiện tại dùng DB State Machine." Không demo Camunda nếu chưa có xác nhận mới.

### Multi-tenancy

- Chương 2 mô tả Shared Database, Separate Schema.
- Chương 4 và Kết luận mô tả cô lập logic bằng `company_id` trên cùng hạ tầng database.

Ưu tiên trạng thái triển khai ở Chương 4/Kết luận: cô lập theo `company_id`. Chỉ nêu separate schema như phương án nghiên cứu nếu cần, không trình bày cả hai như cùng được triển khai.

### Tính năng báo cáo

- Phần phân tích mô tả trial balance, income statement và aging report.
- Kết luận nói nghiệp vụ báo cáo tài chính chuyên sâu chưa hoàn thiện đầy đủ.

Chỉ demo báo cáo nào thực sự chạy. Không gọi toàn bộ bộ báo cáo là hoàn thiện.

## Điều không được suy diễn

- Không có số liệu load test định lượng.
- Không có độ chính xác AI hay benchmark mô hình.
- Không có phần trăm coverage.
- "Tất cả test case trong ba bảng đều đạt" không đồng nghĩa toàn hệ thống không lỗi.
- Không tuyên bố mobile, MFA/OTP, tích hợp ngân hàng, hóa đơn điện tử hoặc ERP đã hoàn thành.
