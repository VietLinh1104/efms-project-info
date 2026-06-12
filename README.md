# EFMS - Hướng dẫn sử dụng hệ thống quản trị tài chính

EFMS là hệ thống quản trị tài chính doanh nghiệp dùng để quản lý đối tác, hóa đơn, phê duyệt hóa đơn mua hàng, ghi nhận thanh toán, theo dõi công nợ và xem các bút toán kế toán được hệ thống tự động sinh ra.

Tài liệu này dành cho người dùng nghiệp vụ, kế toán, quản lý tài chính và quản trị hệ thống. Nội dung tập trung vào cách hệ thống vận hành, vai trò người dùng, quyền hạn, quy trình phê duyệt và cách sử dụng EFMS thông qua giao diện web hoặc Claude AI.

## 1. Hệ thống EFMS dùng để làm gì?

EFMS hỗ trợ các nghiệp vụ chính sau:

| Nghiệp vụ | Mục đích |
|---|---|
| Dashboard tài chính | Xem nhanh tổng phải thu, tổng phải trả, thanh toán trong tháng, hóa đơn chờ duyệt |
| Quản lý đối tác | Quản lý khách hàng và nhà cung cấp |
| Quản lý hóa đơn | Tạo, xem, xác nhận, hủy, xóa hóa đơn AP/AR |
| Phê duyệt AP Bill | Kiểm soát hóa đơn mua hàng trước khi ghi nhận chính thức |
| Phân tích AI | Dùng Claude phân tích rủi ro trước khi duyệt hoặc từ chối hóa đơn |
| Quản lý thanh toán | Ghi nhận thu tiền, chi tiền và post thanh toán lên sổ cái |
| Tài khoản kế toán | Tra cứu hệ thống tài khoản để hạch toán đúng |
| Tài khoản ngân hàng | Quản lý nguồn tiền dùng khi tạo thanh toán |
| Bút toán kế toán | Xem các journal entries được sinh tự động |
| Quản trị người dùng | Quản lý user, role và quyền truy cập |

## 2. Vai trò người dùng và quyền hạn

EFMS dùng cơ chế phân quyền theo vai trò. Mỗi người dùng thuộc một công ty và được gán một vai trò phù hợp với nhiệm vụ nghiệp vụ của họ.

### 2.1. Các vai trò trong hệ thống

| Mã vai trò | Tên hiển thị | Số quyền | Trạng thái | Công việc chính |
|---|---|---:|---|---|
| `ROLE_ADMIN` | Quản trị viên toàn hệ thống | 25 | Hoạt động | Quản lý hệ thống, người dùng, vai trò, quyền và cấu hình chung |
| `ROLE_FINANCE_MANAGER` | Quản lý tài chính / Kế toán trưởng | 25 | Hoạt động | Kiểm tra tài chính, phê duyệt hoặc từ chối AP Bill, theo dõi công nợ và thanh toán |
| `ROLE_ACCOUNTANT` | Kế toán viên | 11 | Hoạt động | Tạo đối tác, tạo hóa đơn, tạo thanh toán và kiểm tra dữ liệu kế toán |
| `ROLE_AUDITOR` | Kiểm toán viên | 9 | Hoạt động | Xem dữ liệu, kiểm tra lịch sử nghiệp vụ, đối soát chứng từ và bút toán |

### 2.2. Nguyên tắc phân quyền

- Người dùng chỉ xem và thao tác được dữ liệu thuộc công ty của mình.
- Mỗi chức năng yêu cầu quyền tương ứng, ví dụ xem hóa đơn, tạo hóa đơn, phê duyệt hóa đơn.
- Nếu người dùng không có quyền, hệ thống sẽ từ chối thao tác.
- Quản trị viên có thể cấp hoặc thu hồi quyền thông qua vai trò.

### 2.3. Bảng quyền nghiệp vụ thường gặp

| Nhóm chức năng | Quyền | Ý nghĩa |
|---|---|---|
| Đối tác | `PARTNERS:READ` | Xem danh sách và chi tiết đối tác |
| Đối tác | `PARTNERS:CREATE` | Tạo khách hàng hoặc nhà cung cấp |
| Đối tác | `PARTNERS:UPDATE` | Cập nhật thông tin đối tác |
| Hóa đơn | `INVOICE:READ` | Xem danh sách và chi tiết hóa đơn |
| Hóa đơn | `INVOICE:CREATE` | Tạo hóa đơn mới |
| Hóa đơn | `INVOICE:UPDATE` | Cập nhật hóa đơn |
| Hóa đơn | `INVOICE:FINANCE_MANAGER_REVIEW` | Phê duyệt hoặc từ chối AP Bill |
| Hóa đơn | `INVOICE:CANCEL` | Hủy hóa đơn |
| Hóa đơn | `INVOICE:DELETE` | Xóa hóa đơn khi còn ở trạng thái nháp |
| Thanh toán | `PAYMENTS:READ` | Xem thanh toán |
| Thanh toán | `PAYMENTS:CREATE` | Tạo thanh toán |
| Thanh toán | `PAYMENTS:UPDATE` | Cập nhật hoặc phân bổ thanh toán |
| Thanh toán | `PAYMENTS:DELETE` | Xóa thanh toán trước khi post |
| Tài khoản kế toán | `ACCOUNTS:READ` | Xem hệ thống tài khoản kế toán |
| Tài khoản ngân hàng | `BANKACC:READ` | Xem tài khoản ngân hàng |
| Tài khoản ngân hàng | `BANKACC:CREATE` | Tạo tài khoản ngân hàng |
| Tài khoản ngân hàng | `BANKACC:UPDATE` | Cập nhật tài khoản ngân hàng |

## 3. Các khái niệm nghiệp vụ cần biết

### 3.1. AP Bill và AR Invoice

| Loại hóa đơn | Ý nghĩa | Đối tượng | Có cần phê duyệt không? |
|---|---|---|---|
| AP Bill | Hóa đơn mua hàng, khoản phải trả | Nhà cung cấp | Có |
| AR Invoice | Hóa đơn bán hàng, khoản phải thu | Khách hàng | Không |

AP Bill dùng khi doanh nghiệp mua hàng hóa/dịch vụ và phát sinh nghĩa vụ thanh toán cho nhà cung cấp. AR Invoice dùng khi doanh nghiệp bán hàng hóa/dịch vụ và phát sinh khoản phải thu từ khách hàng.

### 3.2. Trạng thái hóa đơn

| Trạng thái | Ý nghĩa |
|---|---|
| `draft` | Hóa đơn mới tạo, còn là bản nháp |
| `open` | Hóa đơn đã được xác nhận và có hiệu lực nghiệp vụ |
| `cancelled` | Hóa đơn đã bị hủy |

### 3.3. Trạng thái phê duyệt

| Trạng thái | Ý nghĩa |
|---|---|
| `pending` | AP Bill đang chờ phê duyệt |
| `approved` | AP Bill đã được phê duyệt |
| `rejected` | AP Bill đã bị từ chối |

## 4. Quy trình nghiệp vụ tổng quát

```text
Thiết lập dữ liệu nền
  -> Tạo đối tác
  -> Kiểm tra tài khoản kế toán
  -> Kiểm tra tài khoản ngân hàng

Tạo hóa đơn
  -> AP Bill hoặc AR Invoice
  -> Lưu ở trạng thái draft

Xác nhận hóa đơn
  -> AR Invoice chuyển sang open
  -> AP Bill chuyển sang open và pending approval

Phê duyệt AP Bill
  -> Quản lý tài chính / Kế toán trưởng kiểm tra
  -> Có thể dùng Claude AI phân tích rủi ro
  -> Approve hoặc Reject

Thanh toán
  -> Tạo payment
  -> Gắn với hóa đơn nếu cần
  -> Post payment
  -> Hệ thống tự tạo bút toán kế toán

Theo dõi
  -> Dashboard
  -> Danh sách hóa đơn
  -> Danh sách thanh toán
  -> Bút toán kế toán
  -> Lịch sử comment/phê duyệt
```

## 5. Quy trình tạo và xử lý hóa đơn

### 5.1. Tạo AP Bill

AP Bill là hóa đơn mua hàng từ nhà cung cấp và cần được phê duyệt trước khi xử lý tiếp.

Các bước thực hiện:

1. Vào màn hình Đối tác để kiểm tra nhà cung cấp đã tồn tại hay chưa.
2. Nếu chưa có, tạo mới nhà cung cấp.
3. Vào màn hình Tài khoản kế toán để xác định tài khoản hạch toán phù hợp.
4. Vào màn hình Hóa đơn.
5. Chọn tạo hóa đơn mới.
6. Chọn loại hóa đơn AP Bill.
7. Nhập nhà cung cấp, ngày hóa đơn, hạn thanh toán và các dòng hóa đơn.
8. Lưu hóa đơn ở trạng thái nháp.
9. Xác nhận hóa đơn để chuyển sang trạng thái chờ phê duyệt.

Lưu ý khi nhập dòng hóa đơn:

- Mỗi dòng phải có tài khoản kế toán.
- Mỗi dòng phải có mô tả hàng hóa hoặc dịch vụ.
- Số lượng và đơn giá phải hợp lệ.
- Nếu không có thuế, nhập thuế suất là 0.

### 5.2. Tạo AR Invoice

AR Invoice là hóa đơn bán hàng cho khách hàng và không cần luồng phê duyệt AP.

Các bước thực hiện:

1. Kiểm tra hoặc tạo khách hàng trong danh sách Đối tác.
2. Chọn tạo hóa đơn mới.
3. Chọn loại hóa đơn AR Invoice.
4. Nhập khách hàng, ngày hóa đơn, hạn thanh toán và các dòng hóa đơn.
5. Lưu hóa đơn ở trạng thái nháp.
6. Xác nhận hóa đơn để chuyển sang trạng thái mở.

### 5.3. Quy tắc xử lý hóa đơn

- Hóa đơn mới tạo luôn bắt đầu ở trạng thái nháp.
- Hóa đơn nháp có thể chỉnh sửa hoặc xóa nếu người dùng có quyền.
- AP Bill phải được xác nhận trước khi xuất hiện trong danh sách chờ phê duyệt.
- AP Bill không thể được phê duyệt khi còn là nháp.
- Hóa đơn đã hủy không được dùng để thanh toán.
- Hóa đơn đã mở hoặc đã xử lý nên được hủy bằng chức năng hủy, không xóa trực tiếp.

## 6. Quy trình phê duyệt AP Bill

Phê duyệt AP Bill là quy trình kiểm soát chi phí trước khi doanh nghiệp ghi nhận và thanh toán khoản phải trả.

### 6.1. Luồng trạng thái

```text
Tạo AP Bill
  -> draft
  -> Xác nhận
  -> open + pending
  -> Quản lý tài chính / Kế toán trưởng kiểm tra
  -> Phê duyệt hoặc từ chối
```

Nếu được phê duyệt:

```text
pending
  -> approved
  -> Có thể tiếp tục xử lý thanh toán
```

Nếu bị từ chối:

```text
pending
  -> rejected
  -> Lưu lý do từ chối
```

### 6.2. Người phê duyệt cần kiểm tra gì?

Trước khi phê duyệt, Quản lý tài chính / Kế toán trưởng nên kiểm tra:

- Nhà cung cấp có đúng không.
- Số tiền có khớp chứng từ thực tế không.
- Tài khoản kế toán trên từng dòng có phù hợp không.
- Thuế suất có đúng không.
- Hạn thanh toán có hợp lý không.
- Công ty có đủ dòng tiền để thanh toán không.
- Nhà cung cấp có lịch sử giao dịch tốt không.
- Có hóa đơn nào trùng hoặc bất thường không.

### 6.3. Khi nào nên phê duyệt?

Nên phê duyệt khi:

- Hóa đơn hợp lệ và đầy đủ thông tin.
- Nhà cung cấp đúng.
- Giá trị hóa đơn phù hợp với hợp đồng hoặc thực tế mua hàng.
- Tài khoản kế toán và thuế suất đúng.
- Không có rủi ro lớn về dòng tiền hoặc công nợ.

### 6.4. Khi nào nên từ chối?

Nên từ chối hoặc yêu cầu bổ sung thông tin khi:

- Thiếu thông tin quan trọng.
- Sai nhà cung cấp.
- Sai số tiền, thuế hoặc tài khoản kế toán.
- Không có chứng từ/hợp đồng hỗ trợ.
- Giá trị hóa đơn bất thường.
- Nhà cung cấp có lịch sử giao dịch rủi ro.
- Dòng tiền hiện tại không phù hợp để phát sinh thêm nghĩa vụ thanh toán.

### 6.5. Dùng AI để hỗ trợ phê duyệt

Người dùng có thể yêu cầu Claude phân tích AP Bill trước khi quyết định.

Ví dụ:

```text
Phân tích hóa đơn này xem có nên phê duyệt không.
```

Claude sẽ tổng hợp:

- Chi tiết hóa đơn.
- Tổng phải thu và phải trả hiện tại.
- Thanh toán trong tháng.
- Số lượng hóa đơn đang chờ duyệt.
- Lịch sử giao dịch với đối tác.
- Các yếu tố rủi ro.

Kết quả phân tích sẽ có khuyến nghị và comment gợi ý. Khi người duyệt đồng ý với phân tích, có thể dùng comment đó làm lý do phê duyệt hoặc từ chối.

## 7. Quy trình thanh toán

Thanh toán dùng để ghi nhận dòng tiền thực tế: thu tiền từ khách hàng hoặc chi tiền cho nhà cung cấp.

### 7.1. Các loại thanh toán

| Loại | Ý nghĩa | Ví dụ |
|---|---|---|
| `CASH_IN` | Thu tiền | Khách hàng thanh toán công nợ |
| `CASH_OUT` | Chi tiền | Trả tiền cho nhà cung cấp |

### 7.2. Các bước tạo thanh toán

1. Kiểm tra hóa đơn liên quan nếu thanh toán cho một hóa đơn cụ thể.
2. Kiểm tra đối tác.
3. Kiểm tra tài khoản ngân hàng dùng để thu hoặc chi.
4. Tạo thanh toán mới.
5. Chọn loại thanh toán.
6. Nhập đối tác, tài khoản ngân hàng, số tiền, ngày thanh toán và diễn giải.
7. Gắn hóa đơn liên quan nếu cần.
8. Lưu thanh toán.
9. Kiểm tra lại thông tin.
10. Post thanh toán để ghi nhận chính thức.

### 7.3. Lưu ý trước khi post payment

- Post payment là bước ghi nhận nghiệp vụ chính thức.
- Sau khi post, hệ thống sẽ tự động tạo bút toán kế toán.
- Chỉ post khi đã chắc chắn số tiền, đối tác, tài khoản ngân hàng và hóa đơn liên quan đều đúng.
- Không nên post payment nếu còn nghi ngờ về dữ liệu.

## 8. Các màn hình chính

| Màn hình | Người dùng thường dùng | Mục đích |
|---|---|---|
| Dashboard | Quản trị viên, Quản lý tài chính, Kế toán viên, Kiểm toán viên | Xem tổng quan tài chính |
| Partners | Kế toán viên, Quản trị viên, Kiểm toán viên | Quản lý khách hàng và nhà cung cấp |
| Invoices | Kế toán viên, Quản lý tài chính, Quản trị viên, Kiểm toán viên | Tạo, xem, xác nhận, phê duyệt hóa đơn |
| Payments | Kế toán viên, Quản lý tài chính, Quản trị viên, Kiểm toán viên | Tạo và post thanh toán |
| Chart of Accounts | Kế toán viên, Quản lý tài chính, Quản trị viên, Kiểm toán viên | Tra cứu tài khoản kế toán |
| Bank Accounts | Kế toán viên, Quản lý tài chính, Quản trị viên | Quản lý tài khoản ngân hàng |
| Settings | Người dùng, Quản trị viên | Cập nhật thông tin cá nhân, công ty và cấu hình hệ thống |
| User Management | Quản trị viên | Quản lý người dùng |
| Roles & Permissions | Quản trị viên | Quản lý vai trò và quyền |

## 9. Sử dụng EFMS qua Claude AI

EFMS có thể kết nối với Claude thông qua MCP Server. Sau khi kết nối, người dùng có thể thao tác hệ thống bằng ngôn ngữ tự nhiên thay vì phải tự mở từng màn hình.

### 9.1. Kết nối Claude với EFMS

Thực hiện các bước sau:

1. Truy cập Claude.
2. Mở mục `Customize`.
3. Chọn `Connectors`.
4. Nhấn dấu `+`.
5. Chọn `Add custom connector`.
6. Nhập thông tin kết nối:

| Trường | Giá trị |
|---|---|
| `NAME` | `EFMS` |
| `MCP Server URL` | `https://mcp.hnhdecor.com/mcp` |
| `OAuth Client ID` | `claude-connector` |
| `OAuth Client Secret` | `scXLlfmeZSXIcCxu8nbWbwzq` |

7. Lưu connector.
8. Claude sẽ mở luồng đăng nhập EFMS.
9. Đăng nhập bằng tài khoản EFMS của bạn.
10. Sau khi kết nối thành công, Claude có thể truy cập các chức năng EFMS theo đúng quyền của tài khoản đã đăng nhập.

Lưu ý: không chia sẻ thông tin kết nối và OAuth Client Secret cho người không được phép sử dụng hệ thống.

### 9.2. Người dùng có thể hỏi Claude những gì?

Dashboard:

```text
Cho tôi xem dashboard tài chính hiện tại.
Tình hình công nợ phải thu và phải trả đang như thế nào?
```

Hóa đơn:

```text
Liệt kê các hóa đơn đang ở trạng thái draft.
Có AP Bill nào đang chờ duyệt không?
Xem chi tiết hóa đơn này giúp tôi: <invoiceId>.
```

Tạo hóa đơn:

```text
Tạo AP Bill cho nhà cung cấp ABC, ngày hóa đơn hôm nay,
gồm dịch vụ tư vấn 10.000.000 VND, thuế 10%.
```

Phê duyệt:

```text
Phân tích hóa đơn <invoiceId> xem có nên phê duyệt không.
Nếu hợp lý thì phê duyệt hóa đơn đó và lưu comment gợi ý của AI.
Từ chối hóa đơn này với lý do sai số tiền.
```

Thanh toán:

```text
Liệt kê các khoản thanh toán chưa post.
Tạo thanh toán 5.000.000 VND cho nhà cung cấp ABC từ tài khoản Vietcombank.
Post thanh toán <paymentId>.
```

Đối tác và dữ liệu tham chiếu:

```text
Tìm nhà cung cấp tên ABC.
Tạo khách hàng mới tên Công ty Minh Long.
Liệt kê tài khoản kế toán loại chi phí.
Liệt kê tài khoản ngân hàng của công ty.
```

### 9.3. Các nguyên tắc khi dùng Claude

- Claude chỉ thao tác được dữ liệu theo quyền của tài khoản đã đăng nhập.
- Với thao tác quan trọng như phê duyệt, từ chối hoặc post payment, người dùng nên kiểm tra lại kết quả trước khi xác nhận.
- Khi tạo hóa đơn hoặc thanh toán, nên cung cấp rõ đối tác, ngày, số tiền, loại nghiệp vụ và mô tả.
- Nếu Claude hỏi lại thông tin, hãy cung cấp thông tin còn thiếu thay vì yêu cầu tạo ngay.

## 10. Lỗi thường gặp và cách xử lý

| Tình huống | Nguyên nhân thường gặp | Cách xử lý |
|---|---|---|
| Không đăng nhập được | Sai tài khoản, mật khẩu hoặc tài khoản bị khóa | Kiểm tra lại thông tin đăng nhập hoặc liên hệ Quản trị viên |
| Không thấy dữ liệu công ty | Tài khoản chưa được gắn đúng công ty | Liên hệ Quản trị viên kiểm tra thông tin người dùng |
| Không thực hiện được thao tác | Thiếu quyền nghiệp vụ | Liên hệ Quản trị viên để kiểm tra role và permissions |
| Không thấy hóa đơn chờ duyệt | Hóa đơn chưa được xác nhận hoặc không phải AP Bill | Kiểm tra trạng thái hóa đơn |
| Không phê duyệt được AP Bill | Hóa đơn chưa ở trạng thái pending hoặc user thiếu quyền duyệt | Kiểm tra trạng thái và quyền phê duyệt |
| Không xóa được hóa đơn | Hóa đơn không còn là nháp | Dùng chức năng hủy nếu nghiệp vụ cho phép |
| Không post được payment | Payment thiếu thông tin hoặc user thiếu quyền | Kiểm tra payment, hóa đơn liên quan và quyền người dùng |
| Claude không kết nối được EFMS | Connector sai URL, sai OAuth thông tin hoặc chưa đăng nhập | Kiểm tra cấu hình connector và đăng nhập lại |

## 11. Ghi nhớ nhanh

- AP Bill là hóa đơn mua hàng và cần phê duyệt.
- AR Invoice là hóa đơn bán hàng và không cần phê duyệt AP.
- Hóa đơn phải được xác nhận trước khi đi tiếp trong quy trình.
- AP Bill phải ở trạng thái pending thì mới phê duyệt hoặc từ chối được.
- Payment chỉ nên post khi dữ liệu đã được kiểm tra chắc chắn.
- Bút toán kế toán do hệ thống tự động sinh ra.
- Người dùng chỉ thao tác được trong phạm vi công ty và quyền được cấp.
- Claude AI là công cụ hỗ trợ, quyết định cuối cùng vẫn thuộc người dùng có thẩm quyền.
