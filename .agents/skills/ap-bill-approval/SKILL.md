Sau khi loại bỏ Camunda, luồng phê duyệt hóa đơn AP (AP Bill) hiện tại đã được đơn giản hóa thành một State Machine (Máy chuyển trạng thái) lưu trực tiếp trong Database.

Dưới đây là chi tiết luồng nghiệp vụ mới:

1. Sơ đồ trạng thái (State Transitions)
Hành động	Trạng thái (status)	Trạng thái duyệt (approval_status)	Ý nghĩa
Tạo mới	draft	null	Hóa đơn nháp, có thể sửa/xóa.
Xác nhận (Confirm)	open	pending	Chờ Kế toán trưởng phê duyệt.
Phê duyệt (Approve)	open	approved	Đã duyệt. Hệ thống tự động sinh bút toán Sổ cái.
Từ chối (Reject)	open	rejected	Bị từ chối. Có thể kèm theo ghi chú (approval_comment).
Hủy (Cancel)	cancelled	không đổi	Hóa đơn bị hủy bỏ hoàn toàn.
2. Chi tiết các bước thực hiện qua API
Bước 1: Xác nhận hóa đơn (Chuyển từ Draft sang Pending)
Khi User nhấn "Xác nhận" trên giao diện:

API: POST /api/core/v1/invoices/{id}/confirm
Xử lý: Hệ thống cập nhật status = 'open' và approval_status = 'pending'.
Bước 2: Xem danh sách chờ duyệt
Kế toán trưởng (hoặc người có quyền) lấy danh sách các hóa đơn đang đợi mình:

API: GET /api/core/v1/invoice-tasks/tasks?companyId={uuid}
Xử lý: Backend query trực tiếp trong DB các hóa đơn có invoice_type = 'AP' và approval_status = 'pending'.
Bước 3: Thực hiện Phê duyệt hoặc Từ chối
Người duyệt thực hiện hành động kèm theo ghi chú:

Phê duyệt: POST /api/core/v1/invoices/{id}/approve?comment=Nội dung duyệt
approval_status chuyển thành approved.
Ghi nhận approval_comment.
Trigger: Hệ thống sẽ gọi Service tạo Bút toán (Journal Entry).
Từ chối: POST /api/core/v1/invoices/{id}/reject?comment=Lý do từ chối
approval_status chuyển thành rejected.
Ghi nhận approval_comment.
