---
name: create-efms-defense-presentation
description: Tạo nội dung slide bảo vệ đồ án EFMS, lời thoại thuyết trình theo từng slide, kịch bản demo 5-7 phút, câu chuyển ý, phân bổ thời gian và bộ câu hỏi phản biện. Sử dụng khi người dùng yêu cầu làm dàn ý slide, nội dung PowerPoint/PPTX, speaker notes, kịch bản bảo vệ hoặc demo cho đề tài "Hệ thống quản lý tài chính nội bộ doanh nghiệp tích hợp trợ lý AI Agent", đặc biệt khi phải tuân thủ tài liệu "Cấu trúc Slide báo cáo đồ án" và đối chiếu báo cáo đồ án của Đinh Việt Linh.
---

# Create EFMS Defense Presentation

## Mục tiêu

Tạo một bộ nội dung bảo vệ nhất quán với báo cáo đồ án, ưu tiên tư duy phân tích thiết kế, trình bày đúng mức độ hoàn thiện thực tế và có demo nghiệp vụ thuyết phục.

## Nguồn bắt buộc

Đọc trước khi soạn:

1. `references/slide-structure.md` để tuân thủ bố cục và tỷ trọng.
2. `references/efms-source-map.md` để chọn nội dung đúng trang và xử lý các điểm mâu thuẫn.
3. `references/output-contract.md` để xuất đúng định dạng.
4. `references/demo-playbook.md` khi tạo kịch bản demo.

Chỉ mở tài liệu gốc khi cần kiểm tra hình, bảng hoặc câu chữ:

- `assets/slide-report-structure.docx`
- `assets/efms-thesis-report.pdf`

## Quy trình

### 1. Chốt ràng buộc

Xác định thời lượng thuyết trình, thời lượng demo, số slide, ngôn ngữ và loại đầu ra. Nếu thiếu thông tin, tiếp tục với các mặc định:

- Tiếng Việt.
- Khoảng 18 slide nội dung, có thể co giãn trong khung 16-20 slide.
- Demo 5-7 phút.
- Ưu tiên slide trực quan, ít chữ.

### 2. Xây dựng câu chuyện

Dùng một mạch xuyên suốt:

`Vấn đề quản trị tài chính rời rạc -> yêu cầu nghiệp vụ -> kiến trúc EFMS -> luồng AP Bill trọng tâm -> kết quả triển khai -> AI Agent -> kiểm thử -> giới hạn và hướng phát triển`.

Không biến Chương 2 thành danh sách công nghệ dài. Chỉ giải thích công nghệ gắn trực tiếp với một quyết định thiết kế hoặc rủi ro nghiệp vụ.

### 3. Phân bổ slide

Giữ đúng thứ tự bốn chương. Dành tỷ trọng lớn nhất cho Chương 3. Chọn một luồng xuyên suốt là AP Bill từ tạo hóa đơn, chờ duyệt, phê duyệt đến sinh bút toán kép.

Ưu tiên các hình:

- Sơ đồ kiến trúc bốn dịch vụ và MCP Server.
- Use case tổng quát.
- Sequence hoặc activity diagram của AP Bill.
- ERD rút gọn quanh `invoices`, `invoice_lines`, `journal_entries`, `journal_lines`, `payments`.
- Ảnh Dashboard, danh sách/tạo hóa đơn, RBAC và kết nối MCP.

### 4. Viết nội dung và lời thoại

Với mỗi slide, viết:

- Tiêu đề mang thông điệp, không chỉ tên mục.
- Tối đa 3-5 ý ngắn trên slide.
- Một visual chính.
- Lời thoại tự nhiên, không đọc lại nguyên văn slide.
- Một câu chuyển sang slide kế tiếp.
- Thời lượng dự kiến.
- Trang nguồn trong PDF.

Tách rõ ba mức độ:

- **Đã triển khai:** được Chương 4 hoặc Kết luận xác nhận.
- **Đã thiết kế/nghiên cứu:** có trong phân tích nhưng chưa được xác nhận triển khai.
- **Hướng phát triển:** được ghi trong phần hạn chế/hướng phát triển.

### 5. Tạo demo

Dùng `references/demo-playbook.md`. Trước khi khẳng định một thao tác có thể chạy, kiểm tra ứng dụng hoặc hỏi người dùng về trạng thái môi trường nếu không thể tự kiểm tra.

Demo phải có:

- Bối cảnh và hai vai trò.
- Một happy path hoàn chỉnh.
- Một điểm nhấn kỹ thuật.
- Một ngoại lệ hoặc kiểm tra phân quyền.
- Dữ liệu đẹp và phương án video dự phòng.

### 6. Tự kiểm tra

Trước khi giao kết quả, xác nhận:

- Đủ bốn chương và phần kết.
- Chương 3 chiếm tỷ trọng lớn nhất.
- Không tuyên bố Camunda 8 đã tích hợp.
- Không trộn mô hình multi-tenancy đề xuất với mô hình triển khai thực tế.
- Không bịa số liệu hiệu năng, độ chính xác AI hoặc tỷ lệ kiểm thử.
- Demo phù hợp với tính năng đang chạy.
- Lời thoại nằm trong thời gian.

## Nguyên tắc nội dung

- Dùng thuật ngữ tiếng Việt trước, tiếng Anh trong ngoặc khi cần.
- Giải thích giá trị nghiệp vụ trước chi tiết kỹ thuật.
- Nêu rõ AI chỉ hỗ trợ tra cứu/phân tích; quyết định nghiệp vụ cuối cùng thuộc người có thẩm quyền.
- Dùng kết quả kiểm thử dạng kịch bản đạt, không suy diễn thành chứng nhận chất lượng toàn hệ thống.
- Khi nguồn mâu thuẫn, ưu tiên Chương 4 và Kết luận để mô tả trạng thái triển khai; ghi chú điểm cần người dùng xác nhận.

## Các yêu cầu mẫu

- "Tạo nội dung 18 slide bảo vệ EFMS và lời thoại 15 phút."
- "Viết kịch bản demo AP Bill 6 phút với hai tài khoản."
- "Rút gọn nội dung bảo vệ còn 12 phút nhưng vẫn đủ bốn chương."
- "Tạo speaker notes và câu hỏi phản biện cho slide kiến trúc EFMS."
