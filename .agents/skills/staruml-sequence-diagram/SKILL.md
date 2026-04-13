---
name: StarUML Sequence Diagram Specialist
description: Hướng dẫn chuyên biệt cho Agent để phân tích, thiết kế và vẽ Biểu đồ tuần tự (Sequence Diagram) thông qua StarUML MCP Server.
---

# Hướng dẫn Kỹ năng Vẽ Biểu đồ Tuần tự trong StarUML (StarUML Sequence Diagram Specialist)

Kỹ năng này định hướng cách thức bạn (Agent) phân tích yêu cầu, xây dựng mã Mermaid và giao tiếp với StarUML MCP Server để tự động hóa việc tạo Biểu đồ tuần tự (Sequence Diagram). Trong dự án EFMS, các biểu đồ này chủ yếu phục vụ thiết kế quy trình nghiệp vụ (Chương 3 của file Báo cáo).

## 1. Phương pháp Phân tích Nghiệp vụ (Phân tích Luồng)

Trước khi tiến hành sinh mã biểu đồ, bạn luôn phải thực hiện các bước phân tích sâu:
- **Xác định Đối tượng (Participants/Actors):** Xác định rõ đối tượng nào tương tác với đối tượng nào. Ví dụ trong dự án EFMS: `Client`, `API Gateway`, `Identity Service`, `Core Service`, `Camunda 8 (SaaS)`, `Job Worker`, `Database` PostgreSQL.
- **Xác định Trình tự Thời gian:** Diễn đạt tuần tự các sự kiện theo đúng dòng thời gian thực thi (Life-line).
- **Phân loại Thông điệp (Messages):** Phân biệt rành mạch thông điệp đồng bộ (gọi API HTTP), phản hồi (Return/Response), không đồng bộ (Bắn Actor Message/Event), hoặc gọi chính nó (Self-Message).

## 2. Chuẩn hóa Cú pháp Mermaid cho Biểu đồ Tuần tự

StarUML hỗ trợ vẽ Sequence Diagram thông qua khai báo bằng mã trúc **Mermaid**. Đảm bảo mã của bạn hoàn toàn tuân thủ các quy tắc cốt lõi:

- **Bắt buộc:** Luôn bắt đầu bằng định danh `sequenceDiagram`. Nhớ bật `autonumber` nếu cần đánh số thứ tự các bước.
- **Khai báo Participants:** Nên khai báo `participant` và `actor` rõ ràng ở đầu (Có thể sử dụng thẻ `box` để nhóm các service cùng cluster/chức năng). 
  *Ví dụ:* 
  ```mermaid
  sequenceDiagram
      autonumber
      actor C as Client Application
      participant G as API Gateway
      participant I as Identity Service
      
      C->>G: POST /auth/login (Username, Password)
      activate G
      G->>I: Forward Auth Request
      activate I
      I-->>G: JWT Access Token
      deactivate I
      G-->>C: Return 200 OK & Token
      deactivate G
  ```
- **Ký hiệu Mũi tên (Arrow Types):** 
  - `->>`: Yêu cầu đồng bộ (Synchronous request)
  - `-->>`: Phản hồi (Continuous / Reply / Response)
  - `-)`: Lời gọi không đồng bộ (Asynchronous message)
- **Alt/Opt/Par/Loop:** Khai thác triệt để các cấu trúc điều khiển (Fragments):
  - `alt` / `else` / `end`: Dành cho các phân nhánh logic (VD: IF Xác thực thành công / ELSE thất bại).
  - `opt` / `end`: Dành cho các bước tùy chọn có thể xảy ra hoặc không.
  - `loop` / `end`: Trình diễn các thao tác lặp.
- **Lưu ý an toàn cú pháp:** Không sử dụng các thẻ HTML `<br>`, `<b>` vào bên trong nhãn (label) của mũi tên để tránh làm StarUML phân tích cú pháp sai phạm (Syntax Error).

## 3. Quy ước Đặt Tên & Thiết kế Riêng cho nhánh EFMS

- **Microservices:** Đặt tên rõ các Service như `API Gateway`, `Identity`, `Core` dựa vào bản mô tả Backend System Context.
- **Quy trình phê duyệt (Camunda):** Biểu diễn rõ Camunda Engine đóng vai trò Orchestrator. Core Service giao tiếp với Camunda qua Zeebe Client.
- **Thông điệp API / Sự kiện:** Trình bày theo dạng `Giao thức | Method | Tên Hành động`. 
  *Ví dụ: `REST GET /api/v1/invoices` hoặc `Zeebe Client: Publish Message (InvoiceSubmitted)`.*

## 4. Giao tiếp với StarUML MCP Server

Khi người dùng yêu cầu "vẽ biểu đồ tuần tự", bạn thực hiện theo quy trình sau:
1. **Phân tích (Thinking):** Thiết lập tư duy dòng chảy sự kiện, xác định các nhánh nghiệp vụ.
2. **Soạn mã Mermaid:** Tạo mã Mermaid nội bộ chuẩn xác (không in ra cho user dưới dạng text chat trừ khi user yêu cầu preview text).
3. **Thực thi Tool:** Sử dụng công cụ `mcp_staruml-mcp-server_generate_diagram` với tham số `code` chính là đoạn mã Mermaid bạn vừa soạn.
4. **Xác nhận:** Thông báo ngắn gọn cho người dùng biết Biểu đồ Tuần tự đã được khởi tạo/cập nhật và hãy kiểm tra phần mềm StarUML trên máy cá nhân của người dùng.

---
**LƯU Ý:** Tính chính xác của cú pháp (Syntax Check) là yêu cầu tối thượng. Chỉ cần dư một dấu hai chấm (`:`), dấu ngoặc kép không đóng (`"`), hoặc khoảng trắng bất thường trong nhãn cũng có thể làm đổ vỡ thao tác Generate Diagram. Hãy hết sức kiên nhẫn và cẩn thận!
