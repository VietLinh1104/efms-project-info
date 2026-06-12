# Kịch bản demo EFMS

## Luồng chính đề xuất: AP Bill

Mục tiêu: chứng minh hệ thống kiểm soát một hóa đơn mua hàng từ người lập đến người duyệt, tự động sinh dữ liệu kế toán và cho phép AI tra cứu có kiểm soát.

## Chuẩn bị

- Profile A: Kế toán viên.
- Profile B: Quản lý tài chính hoặc Admin có quyền phê duyệt.
- Một nhà cung cấp có mã số thuế và tài khoản AP.
- Một hóa đơn mẫu có 2-3 dòng, số tiền dễ đọc.
- Một file PDF/ảnh hóa đơn để đính kèm.
- Một bình luận nghiệp vụ ngắn.
- Dashboard có 20-50 bản ghi hợp lý.
- Kết nối MCP đã xác thực nếu demo AI.

## Timeline 5-7 phút

### 0:00-0:30 - Bối cảnh

Nói rõ hai vai trò và kết quả cuối: hóa đơn được duyệt, phát sinh bút toán và có thể tra cứu qua AI.

### 0:30-3:20 - Happy path

1. Kế toán đăng nhập.
2. Chọn nhà cung cấp.
3. Tạo AP Bill và các dòng chi tiết.
4. Đính kèm chứng từ, thêm bình luận nếu ổn định.
5. Xác nhận/gửi duyệt; chỉ ra trạng thái `pending`.
6. Chuyển sang profile quản lý.
7. Mở danh sách chờ duyệt và phê duyệt.
8. Chỉ ra trạng thái mới và bút toán Nợ/Có được sinh tự động.

Trong lúc thao tác, giải thích request đi qua Gateway, JWT mang ngữ cảnh người dùng/công ty, Core xử lý nghiệp vụ và Common quản lý file/bình luận.

### 3:20-5:20 - Điểm nhấn AI/MCP

Đặt một câu hỏi ngôn ngữ tự nhiên có kết quả kiểm chứng được, ví dụ:

- "Liệt kê các hóa đơn AP đang chờ duyệt."
- "Cho biết trạng thái hóa đơn vừa tạo."
- "Tổng hợp công nợ phải trả quá hạn theo nhà cung cấp."

Chỉ dùng câu hỏi mà tool hiện có hỗ trợ. Nói rõ MCP giới hạn AI vào các tool được định nghĩa và vẫn áp dụng JWT/company context.

### 5:20-6:20 - Ngoại lệ/bảo mật

Chọn một kiểm tra ổn định:

- Người không có quyền phê duyệt nhận 403/không thấy nút.
- Thiếu nhà cung cấp hoặc dòng hóa đơn bị validation chặn.
- Hóa đơn đã gửi duyệt không thể xóa như bản nháp.

Không cố tình làm hỏng dữ liệu sản phẩm.

### 6:20-7:00 - Kết

Tóm tắt ba giá trị: kiểm soát vai trò, tự động hóa kế toán, truy vấn AI có kiểm soát.

## Phương án rút gọn

Nếu chỉ có 5 phút:

- Bỏ tạo đối tác.
- Chuẩn bị sẵn hóa đơn nháp.
- Chỉ đính kèm hoặc bình luận, không làm cả hai.
- Dùng một câu hỏi AI.
- Dùng kiểm tra nút phê duyệt bị ẩn thay vì cố gọi API trái quyền.

## Phương án dự phòng

- Video quay sẵn happy path, tối đa 4 phút.
- Ảnh chụp trạng thái trước/sau phê duyệt.
- Ảnh bút toán Nợ/Có.
- Ảnh câu hỏi và kết quả AI.
- Một slide backup mô tả luồng request khi môi trường không chạy.

## Cổng xác minh

Trước khi viết kịch bản cuối, xác nhận các chức năng sau có thật trong bản đang demo:

- Submit/confirm AP Bill.
- Danh sách task hoặc danh sách hóa đơn chờ duyệt.
- Approve/reject.
- Tự động tạo journal entry.
- Tool MCP tương ứng.

Nếu một chức năng không chạy, thay bằng chức năng đã kiểm chứng và ghi rõ giới hạn; không viết kịch bản giả định như thể đã hoạt động.
