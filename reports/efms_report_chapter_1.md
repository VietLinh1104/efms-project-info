# CHƯƠNG 1. CƠ SỞ LÝ THUYẾT VÀ CÔNG NGHỆ ỨNG DỤNG

## 1.1. Kiến trúc hệ thống phân tán (Microservices)

### 1.1.1. Khái niệm và mô hình Microservices
**Khái niệm:** Khác với kiến trúc nguyên khối (Monolithic) – nơi tất cả các mô-đun chức năng được đóng gói và triển khai trong cùng một ứng dụng duy nhất, kiến trúc Microservices (Kiến trúc vi dịch vụ) là một phương pháp luận phát triển phần mềm bằng cách chia nhỏ một ứng dụng lớn thành một tập hợp các dịch vụ (services) nhỏ gọn, độc lập. Mỗi dịch vụ tập trung giải quyết trọn vẹn một nghiệp vụ kinh doanh cụ thể (Business Capability) độc lập với những logic khác.

**Đặc điểm vòng đời hoạt động:** 
- Các microservices chạy trên các tiến trình (process) nền tảng máy chủ riêng biệt.
- Chúng tương tác với nhau thông qua các giao thức truyền tải dữ liệu nhẹ, thông dụng nhất là giao tiếp đồng bộ qua RESTful API (HTTP/HTTPS) hoặc giao tiếp không đồng bộ thông qua các Message Brokers trung gian (như Kafka, RabbitMQ). 
- Sự độc lập cung cấp khả năng tự chủ tuyệt đối trong quy trình triển khai: có thể cập nhật, bảo trì, hoặc mở rộng quy tải (scale) một dịch vụ riêng lẻ mà không gây ảnh hưởng hay yêu cầu ngừng hoạt động toàn bộ hệ thống lớn. Nhóm phát triển còn linh hoạt quyền chọn lựa bất kỳ ngôn ngữ lập trình, hệ quản trị cơ sở dữ liệu phù hợp sát chuẩn nhất với đặc tả của microservice đó.

**Ưu điểm áp dụng vào EFMS:**
Hệ thống tài chính doanh nghiệp EFMS là phần mềm đồ sộ gồm nhiều phân hệ phức tạp. Bằng cách phân định ranh giới (Bounded Context) rõ ràng thông qua Microservices, EFMS có thể chia nhỏ thành: Phân hệ lõi kế toán (Core Service), Phân hệ phân quyền (Identity Service), Hệ thống quy trình (Workflow). Cách tiếp cận này giúp cô lập rủi ro lỗi phần mềm, đồng thời mỗi một quy trình đều được tách bạch ra từng Cơ sở dữ liệu riêng, từ đó ngăn chặn tình trạng thắt nút cổ chai (bottleneck) khi khối lượng truy vấn tổng hợp kế toán gia tăng đột biến, đảm bảo hệ thống duy trì được tính sẵn sàng cao (High Availability).

### 1.1.2. Vai trò của API Gateway trong định tuyến và bảo mật
**Khái niệm cơ bản:** 
Trong một hệ sinh thái phân tán với hàng chục, hàng trăm microservices nhỏ, việc các ứng dụng của Client (Web Application, Mobile App) gọi trực tiếp đến từng dịch vụ nội bộ sẽ là một thảm họa vì quản lý kết nối chằng chịt, phức tạp và lộ cấu trúc mạng máy chủ nhạy cảm ra ngoài internet. Để giải quyết, API Gateway được sinh ra nhằm đóng vai trò điểm chạm truy cập duy nhất (Single Entry Point), là một bức tường ngoại vi vững chắc ngăn cách thế giới Internet bên ngoài tiếp giáp vào mạng lưới các dịch vụ cốt lõi bên trong.

**Vai trò Định tuyến (Dynamic Routing):**
Khách hàng (Client) chỉ bắt buộc cần gửi tất cả các requests tới IP/Domain của API Gateway. Tại đây, Gateway được cấu hình với các quy tắc định tuyến tự động. Bằng cách soi khớp dựa trên các quy luật về đường dẫn (Path predicate), API Gateway sẽ nhận diện điểm đến hợp lệ và chuyển tiếp (forward) gói tin HTTP một cách trơn tru đến đúng cổng hoạt động âm thầm nội bộ của identity-service hay core-service nằm sâu trong hệ sinh thái.

**Vai trò kiểm soát an ninh (Security & Access Control):** 
Là lớp cửa ngõ tiền tuyến, API Gateway gánh vác trách nhiệm bảo mật và sàng lọc dữ liệu thô quan trọng trước khi đi vào hệ thống xử lý nội bộ:
- **Kiểm soát xác thực (Authentication/CORS):** Chỉ cho phép chặn lọc những Request có chữ ký xác thực JWT hợp lệ đi qua và thiết lập chốt chặn quy tắc nguồn gốc chéo cấu hình CORS chặt chẽ.
- **Giới hạn truy cập chặn tấn công (Rate Limiting):** Sàng lọc chống tấn công từ chối dịch vụ (DDoS), hoặc thư rác Spam bằng cách thiết lập giới hạn ngưỡng nhận tín hiệu requests từ một máy trạm trong vài tích tắc thời gian quy đổi.
- **Cân bằng tải (Load Balancing):** Nếu một core-service có tới 5 instances đồng thời đang được chạy, API Gateway sẽ thông minh chia đều vòng lưu lượng (Round-robin) đến từng instance để san sát tối đa dung lượng tải phần cứng của Server.

### 1.1.3. Mô hình Multi-tenancy (Đa công ty/chi nhánh)
**Khái niệm:** 
Multi-tenant (Đa khách thuê hay đa chi nhánh) là một cấu trúc kiến trúc phần mềm hiện đại mà trong đó một phiên bản cốt lõi duy nhất (Single Instance) của ứng dụng hoặc phần cứng được chia sẻ sử dụng bởi, phục vụ cho nhiều nhóm khách hàng/đơn vị khác biệt biệt lập. Trái ngược lại với Single-tenant, mọi dự án EFMS được triển khai chỉ cần chạy thông qua một hạ tầng Cloud và Database Cluster chung, nhưng vẫn có thể cấp phát tài khoản chia tài nguyên, lưu trữ một cách tách rời theo cấp độ "Công ty Mẹ - Thành viên con" (Company/Tenant).

**Các chiến lược xây dựng Multi-tenant Database:**
- **Dùng chung Database và dùng chung Lược đồ (Shared Database - Shared Schema):** 
  Tất cả các Tenants dùng chug mọi Table vật lý trong một Cơ sở dữ liệu duy nhất. Cột tham chiếu phân định danh tính dữ liệu mang tên Tenant ID.
  + *Ưu điểm:* Cực kỳ đơn giản khi triển khai, vận hành nhanh nhất và ít tản mác trên hạ tầng máy và tiết kiệm ngân sách máy tính tối đa. 
  + *Khuyết điểm:* Lỗ hổng tiềm tàng lớn nhất là nếu quên cài đặt tham số bộ lọc truy vấn thông qua Tenant ID theo vòng đời request, hệ thống sẽ gây rò rỉ dữ liệu chéo nhau vô cùng nguy hại. Và Database cực kỳ dễ sập khi một cái máy chứa Data hàng chục Tenant bùng nổ dữ liệu tỷ lệ thuận. 

- **Dùng chung Database nhưng phân tách Lược đồ (Shared Database - Separate Schema):** 
  Toàn bộ các Tenant được hệ thống tạo mới trên chung một cụm máy chủ phần cứng Database. Nhưng, mỗi Tenant được cấp phép sử dụng 1 Schema (Lược đồ bảng - là ranh giới quản lý database logic) biệt tập độc quyền hoàn toàn riêng biệt nhau.
  + *Ưu điểm:* Giải quyết cân bằng được bài toán tối ưu về giá thành thiết lập, nhưng vẫn tách bạch đảm bảo một rào cản ngăn chặn chéo dữ liệu rất chắc chắn trên mức cấu trúc dữ liệu. (Dự án EFMS lựa chọn thiết kế áp dụng mô hình thiết kế này, nhằm đáp ứng độ chuẩn xác phù hợp mô tả tài chính nhưng ngân sách vận hành Cloud hợp lý).

- **Phân tách hoàn toàn Database cho từng phần (Separate Database):**
  Mỗi Tenant được gán cho một Cụm Database vật lý chuyên trách hoạt động biệt lập từ ban đầu và là hệ thống vô can với nhau hoàn toàn.
  + *Ưu điểm:* Cấp độ bảo mật được đánh giá tuyệt đối không có lỗ hổng dò rỉ, đồng thời bảo đảm phân luồng hiệu năng tài nguyên độc lập 100%. 
  + *Khuyết điểm:* Rất khó thiết lập chi phí đầu tư máy ban đầu (Sẽ cực kỳ đắt đỏ), quy trình backup và hệ thống nâng cấp vận hành (DevOps) theo thời gian sẽ đòi hỏi kỹ thuật cao vô vàn hơn mức bình thường.
