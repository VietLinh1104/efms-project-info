---
name: efms-user
description: >
  Hướng dẫn sử dụng hệ thống EFMS (Enterprise Financial Management System) thông qua Claude AI.
  Kích hoạt skill này khi người dùng muốn: xem hóa đơn, tạo hóa đơn, phê duyệt AP Bill,
  quản lý thanh toán, xem báo cáo tài chính, tra cứu đối tác, hoặc hỏi bất cứ điều gì
  liên quan đến nghiệp vụ kế toán/tài chính trong hệ thống EFMS.
  Luôn dùng skill này khi người dùng đề cập đến hóa đơn, thanh toán, phê duyệt, đối tác,
  tài khoản kế toán, sổ cái, hoặc dashboard tài chính — dù họ không nói rõ "EFMS".
---

# EFMS User Guide — Hướng dẫn sử dụng EFMS qua Claude

## Bạn có thể làm gì với hệ thống này?

Claude kết nối trực tiếp với EFMS qua 18 tools. Bạn có thể nói chuyện tự nhiên bằng tiếng Việt — Claude sẽ tự gọi đúng tool và trả kết quả về cho bạn.

---

## Các luồng nghiệp vụ chính

### 1. Xem tổng quan tài chính
> *"Cho tôi xem dashboard tài chính hiện tại"*  
> *"Tình hình tài chính công ty đang như thế nào?"*

→ Dùng `get_dashboard_summary` để lấy KPI (tổng AR/AP, thanh toán tháng này, số hóa đơn chờ duyệt), biểu đồ trạng thái và dòng tiền 6 tháng.

---

### 2. Quản lý Hóa đơn (AP Bill / AR Invoice)

#### Xem danh sách
> *"Cho tôi xem danh sách hóa đơn chờ xử lý"*  
> *"Liệt kê các AP Bill đang ở trạng thái draft"*

→ `list_invoices` với các filter: `status` (draft/open/cancelled), `invoiceType` (AP_BILL/AR_INVOICE), `fromDate`/`toDate`.

#### Tạo hóa đơn mới
> *"Tạo hóa đơn mua hàng từ nhà cung cấp ABC, trị giá 10 triệu"*

**Quy trình cần thiết trước khi tạo:**
1. `list_partners` — tìm `partnerId` của nhà cung cấp
2. `list_accounts` — tìm `accountId` phù hợp từ Chart of Accounts
3. `create_invoice` — tạo hóa đơn với đúng format

> **⚠️ Quan trọng — Giá trị đúng của `invoiceType`:**
> - `"AP"` → AP Bill (hóa đơn mua hàng, cần phê duyệt)
> - `"AR"` → AR Invoice (hóa đơn bán hàng, không cần phê duyệt)
>
> **⚠️ Các field bắt buộc trong mỗi `lines[]`:**
> - `accountId` — UUID tài khoản kế toán (bắt buộc)
> - `description` — mô tả mặt hàng (bắt buộc, không để trống)
> - `quantity` — số lượng, kiểu số (không phải string)
> - `unitPrice` — đơn giá, kiểu số (không phải string)
> - `taxRate` — tỷ lệ thuế % (bắt buộc, nhập `0` nếu không có thuế)

#### Luồng phê duyệt AP Bill (quan trọng!)
```
Tạo → Xác nhận → [AI Phân tích] → Phê duyệt hoặc Từ chối
```
1. `create_invoice` → tạo AP Bill (status: draft)
2. `confirm_invoice` → chuyển sang open, tạo task chờ duyệt
3. `analyze_invoice_for_approval` → **AI phân tích và khuyến nghị** ⭐
4. `approve_invoice` hoặc `reject_invoice` → quyết định cuối

#### Xem danh sách chờ phê duyệt
> *"Có hóa đơn nào đang chờ tôi phê duyệt không?"*

→ `list_pending_tasks` — trả về danh sách AP Bill có `approvalStatus=pending`.

---

### 3. ⭐ Phân tích AI — Gợi ý Phê duyệt

> *"Phân tích xem có nên phê duyệt hóa đơn này không?"*  
> *"Đánh giá rủi ro tài chính của AP Bill [ID]"*

→ `analyze_invoice_for_approval` là tool thông minh nhất trong hệ thống. Nó:

- Thu thập **song song** 3 nguồn dữ liệu: chi tiết hóa đơn, tổng quan tài chính công ty, lịch sử giao dịch với đối tác
- Tính toán các chỉ số: tỷ lệ AP/AR, % hóa đơn so với tổng nợ, điểm tín nhiệm đối tác
- Đánh giá các **yếu tố rủi ro** cụ thể
- Đưa ra **khuyến nghị rõ ràng**: PHÊ DUYỆT / XEM XÉT KỸ / TỪ CHỐI, kèm giải thích
- Tự động tạo sẵn **💬 Comment gợi ý** — đoạn tóm tắt súc tích từ phân tích AI

**Quy trình kết hợp phân tích + hành động:**

Sau khi `analyze_invoice_for_approval` trả về báo cáo, **luôn lấy nội dung trong block "💬 Comment gợi ý"** và dùng làm giá trị tham số `comment` khi gọi `approve_invoice` hoặc `reject_invoice`. Không cần người dùng tự nhập comment thủ công.

```
analyze_invoice_for_approval(invoiceId)
    → Báo cáo phân tích + 💬 Comment gợi ý

approve_invoice(id, comment="[AI Review] HĐ ... : Phê duyệt. ...")
    hoặc
reject_invoice(id, comment="[AI Review] HĐ ... : Đề nghị từ chối. Lý do: ...")
```

---

### 4. Quản lý Thanh toán (Payments)

#### Xem thanh toán
> *"Các khoản thanh toán chưa được post lên sổ cái?"*

→ `list_payments` với `posted: false`.

#### Ghi nhận thanh toán mới
> *"Ghi nhận thanh toán 5 triệu cho nhà cung cấp ABC từ tài khoản Vietcombank cho hóa đơn [ID]"*

**Quy trình:**
1. `list_bank_accounts` — tìm `bankAccountId`
2. `list_partners` — tìm `partnerId`  
3. `create_payment` với `paymentType: CASH_OUT` và `invoiceId` (tùy chọn, để liên kết trực tiếp với hóa đơn cần trừ nợ)
4. `post_payment` → ghi chính thức lên Sổ Cái (tạo bút toán tự động)

> **Lưu ý:** Sau khi `post_payment`, thanh toán **không thể sửa**. Kiểm tra kỹ trước khi post.

---

### 5. Quản lý Đối tác

> *"Tìm thông tin nhà cung cấp Công ty ABC"*  
> *"Thêm khách hàng mới vào hệ thống"*

- `list_partners` — tìm kiếm theo tên hoặc loại (CUSTOMER/VENDOR)
- `get_partner` — xem chi tiết đầy đủ
- `create_partner` — tạo mới, cần cung cấp: tên, loại, email/phone (tùy chọn), mã số thuế

---

### 6. Dữ liệu tham chiếu (Reference Data)

| Tool | Dùng khi nào |
|---|---|
| `list_accounts` | Cần tra cứu mã tài khoản kế toán (COA) để tạo hóa đơn |
| `list_journals` | Xem bút toán kép đã được hệ thống tự động tạo ra |
| `list_bank_accounts` | Cần `bankAccountId` để tạo thanh toán |

---

## Quy tắc nghiệp vụ cần nhớ

1. **Hóa đơn phải confirm trước khi approve** — không thể approve trực tiếp từ draft.
2. **AP Bill cần phê duyệt, AR Invoice thì không** — AR Invoice confirm xong là open ngay.
3. **Chỉ xóa được hóa đơn ở trạng thái draft** — đã confirm/open phải dùng cancel.
4. **Post thanh toán là hành động không thể hoàn tác** — luôn kiểm tra trước.
5. **Số tiền dùng string** — khi nhập `amount` hoặc `unitPrice`, dùng `"5000000"` không phải `5000000`.
6. **Bút toán kép chỉ do hệ thống tạo** — không nhập tay journal entries.

---

## Xử lý lỗi thường gặp

| Lỗi | Nguyên nhân thường gặp | Cách xử lý |
|---|---|---|
| 400 Bad Request | Thiếu field bắt buộc hoặc sai định dạng | Kiểm tra lại `invoiceType`, `partnerId`, `accountId` |
| 403 Forbidden | Người dùng không có quyền thực hiện | Liên hệ admin hệ thống |
| 404 Not Found | ID không tồn tại hoặc không thuộc công ty | Dùng list tool để tra cứu lại |
| 409 Conflict | Hành động không hợp lệ với trạng thái hiện tại | Kiểm tra `status` và `approvalStatus` của tài nguyên |

---

## Mẫu hội thoại gợi ý

**Demo luồng phê duyệt đầy đủ:**
```
User: "Tình hình tài chính hiện tại thế nào?"
→ get_dashboard_summary

User: "Có hóa đơn nào chờ duyệt không?"
→ list_pending_tasks

User: "Phân tích hóa đơn [ID] xem có nên duyệt không?"
→ analyze_invoice_for_approval → báo cáo chi tiết + khuyến nghị

User: "OK, phê duyệt hóa đơn đó đi"
→ approve_invoice (kèm comment nếu muốn)

User: "Ghi nhận thanh toán cho hóa đơn này"
→ list_bank_accounts → create_payment (kèm invoiceId) → post_payment
```
