---
name: efms-frontend-guidelines
description: Frontend guidelines and architecture rules for the EFMS React project. Triggers on any frontend tasks like UI components, API integration, or page development.
---

# EFMS Frontend Project Guidelines

This skill defines the structural and architectural guidelines for the EFMS (Enterprise Financial Management System) React frontend application. When working on this project, ALWAYS adhere to the following rules:

## 1. UI Components & Styling

- **Shadcn UI First**: Always use Shadcn UI components for building user interfaces.
- **Minimize Custom Styles**: Strictly limit the modification of core UI styles. Use the provided utility classes if variations are absolutely necessary, but prefer to keep Shadcn styles as standard as possible.
- **Consistency in Shared Components**:
  - **Data Table**: Use the shared `DataTable` component located at `src/components/ui/data-table.tsx` for all data grid scenarios. It handles pagination, row selection, and rendering inherently.
  - **Column Definitions**: Structure column definitions following the standard pattern demonstrated in `src/pages/dashboard/invoices/invoices-details/columns.tsx`. Use `@tanstack/react-table` patterns with appropriate cell formatting (dates, currency, badges).
  - **Forms**: Build all forms using `react-hook-form` combined with `zod` for robust schema validation. 
  - **Dialogs**: Utilize the standard Shadcn UI `Dialog` component for all modal interactions.

## 2. API Integration & Services (Microservices Architecture)

- **Microservices Structure**:
  The backend is split into two primary services behind an API Gateway:
  - **Identity Service (`/api/identity`)**: Manages multi-tenancy (`companies`), `users`, `roles`, and `permissions`. Handles login and JWT token distribution.
  - **Core Service (`/api/core`)**: Handles all financial entities like `invoices`, `payments`, `journal_entries`, `accounts`, and `partners`.
  - **Common Service (`/api/common`)**: Handles attachments, comments, and audit logs globally across the system.
  
- **Authentication & Tenants**:
  - Standard API requests MUST include the `Authorization: Bearer <token>` header.
  - Multi-tenancy is enforced. All entities belong to a `company_id`. The UI should cleanly handle tenant segregation (usually configured via token extraction and global state).

- **Standard Response Format**:
  All APIs now return a standard wrapper. To extract the actual data, you must unwrap it:
  ```json
  {
    "status": 200,
    "message": "Success",
    "data": { ... } // Your actual payload list / object is here
  }
  ```

- **Available API Services (`src/api/index.ts`)**:
  All external API service instances are initialized and exported from `src/api/index.ts`. The project uses an OpenAPI generator, typically meaning endpoints reside in `src/api/generated/`.
  - **Identity API**: Context `/api/identity/...`
  - **Core API**: Context `/api/core/...`
  - **Common API**: Context `/api/common/...`
  - **Audit Logging API**: Handled mostly via Identity and Common.

- **Generated Types and Models**:
  - ALWAYS import strong typings (like `InvoiceResponse`, `CreateInvoiceRequest`, etc.) from `src/api/generated` rather than creating redundant manual types.
  - Due to the microservice split, note that the generated client might have updated operation names or prefixes. When in doubt, refer to the generated `api.ts` to inspect available methods.

- **API Method Signatures (OpenAPI Generated Classes)**:
  - Typical API method execution follows standard CRUD patterns:
    - Extract wrapped data: `const response = await invoicesApi.getInvoices(...); return response.data.data;`
  - For currency or monetary values, remember that the backend employs `BigDecimal` (sent as numeric or string in JSON); ensure the frontend formats these values correctly without precision loss.

## 3. Project Directory Structure

Adhere to the following structural conventions when adding or modifying files:
- `src/api/` - Contains API client configurations (`index.ts`) and auto-generated OpenAPI types (`generated/api.ts`).
- `src/assets/` - Static files like images, icons, and global styles.
- `src/components/` - Reusable UI components.
  - `src/components/ui/` - Core Shadcn UI components. Do not add business-specific logic here.
- `src/hooks/` - Custom generic React hooks (e.g., custom toast wrappers).
- `src/lib/` - Utility functions, configurations, and core setup (e.g., Axios setup `axios.ts`, tailwind `utils.ts`).
- `src/pages/` - Page-level components, grouped by feature domains (e.g., `dashboard/invoices/`). Business logic, API calls, and state management should mostly reside here instead of generic UI components.
- `src/main.tsx` & `src/App.tsx` - App entry point, global routing, and context providers.

## 4. General Best Practices

- Ensure separation of concerns by placing business and page-level logic in `src/pages` and keeping UI elements in `src/components`.
- Always verify API models before passing data from UI components to the API services to ensure type safety.

---

## 5. Form Page Layout Standard (Chuẩn UI/Layout cho mọi Form Page)

> **Bắt buộc áp dụng**: Mọi form trang chi tiết / tạo mới trong EFMS đều **PHẢI** tuân theo cấu trúc này.  
> File tham chiếu chuẩn: `src/pages/dashboard/invoices/invoices-details/InvoiceFormPage.tsx`

---

### 5.1 Cấu trúc tổng thể (Page Shell)

```tsx
<div className="space-y-6">
  {/* 1. Page Header Bar */}
  <div className="flex items-center gap-2">
    <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
      <ArrowLeft className="w-5 h-5" />
    </Button>
    <h2 className="text-xl font-semibold">
      {isEditMode ? `Tiêu đề: ${record?.name || "N/A"}` : "Tạo mới ..."}
    </h2>
  </div>

  {/* 2. Form wrapper */}
  <Form {...form}>
    <form onSubmit={form.handleSubmit(onSubmit)} className="grid grid-cols-10 gap-6">

      {/* 3. Main Content – 8 columns */}
      <div className="space-y-6 col-span-8">
        {/* Card: Thông tin chính */}
        {/* Card: Chi tiết / Line Items */}
      </div>

      {/* 4. Sidebar – 2 columns */}
      <div className="action col-span-2">
        {/* Card: Trạng thái + Actions */}
      </div>

    </form>
  </Form>
</div>
```

**Quy tắc:**
- Wrapper ngoài cùng: `<div className="space-y-6">`.
- Page title bar luôn nằm **trước** `<Form>`, gồm nút `ArrowLeft` ghost + `<h2 className="text-xl font-semibold">`.
- `<form>` dùng `grid grid-cols-10 gap-6` để chia 8/2.
- Cột trái `col-span-8`, cột phải `col-span-2`.

---

### 5.2 Card: Thông tin chính (Header Info Card)

```tsx
<Card>
  <CardHeader>
    <CardTitle>Thông tin chính</CardTitle>
    <CardDescription>Nhập các thông tin chính của ...</CardDescription>
  </CardHeader>
  <CardContent className="grid md:grid-cols-3 gap-4">
    {/* Các FormField */}
  </CardContent>
</Card>
```

**Quy tắc:**
- Nội dung `<CardContent>` dùng `grid md:grid-cols-3 gap-4` (hoặc `grid-cols-2` nếu ít trường hơn).
- Mỗi field dùng `<FormField>` + `<FormItem>` + `<FormLabel>` + `<FormControl>`.
- `Input` thuần: `<Input {...field} readOnly={isReadOnly} />`.
- `Select`: bao bên trong `<FormControl><SelectTrigger className="w-full">`.
- Field nào cần disabled trong read-only mode: truyền `disabled={isReadOnly}` (Select) hoặc `readOnly={isReadOnly}` (Input).

---

### 5.3 Card: Chi tiết / Line Items (Detail Table Card)

```tsx
<Card>
  <CardHeader>
    <CardTitle>Chi tiết</CardTitle>
    <CardDescription>Dòng chi tiết</CardDescription>
    <CardAction>
      {!isReadOnly && (
        <Button type="button" onClick={() => append({ /* default row */ })}>
          <Plus className="w-4 h-4 mr-2" /> Thêm
        </Button>
      )}
    </CardAction>
  </CardHeader>
  <CardContent>
    <Table className="border">
      <TableHeader>
        <TableRow>
          {/* Column headers */}
          <TableHead></TableHead> {/* actions column – no header */}
        </TableRow>
      </TableHeader>
      <TableBody>
        {fields.map((f, i) => (
          <TableRow key={f.id}>
            {/* Editable cells use: <Input className="border-0 !bg-card" /> */}
            <TableCell>
              {!isReadOnly && (
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" className="h-8 w-8 p-0">
                      <MoreHorizontal className="h-4 w-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuLabel>Thao tác</DropdownMenuLabel>
                    <DropdownMenuItem
                      onClick={() => remove(i)}
                      className="text-destructive focus:text-destructive"
                    >
                      <Trash2 className="mr-2 h-4 w-4" /> Hủy/Xóa
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              )}
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
      <TableFooter>
        {/* Summary rows: Subtotal, Tax, Total */}
        <TableRow>
          <TableCell colSpan={N}>Subtotal</TableCell>
          <TableCell>{subtotal.toLocaleString()}</TableCell>
          <TableCell colSpan={1}></TableCell>
        </TableRow>
        <TableRow>
          <TableCell colSpan={N}>Tax</TableCell>
          <TableCell>{taxTotal.toLocaleString()}</TableCell>
          <TableCell colSpan={1}></TableCell>
        </TableRow>
        <TableRow>
          <TableCell colSpan={N}>Total</TableCell>
          <TableCell>{total.toLocaleString()}</TableCell>
          <TableCell colSpan={1}></TableCell>
        </TableRow>
      </TableFooter>
    </Table>
  </CardContent>
</Card>
```

**Quy tắc:**
- Nút "Thêm dòng" đặt trong `<CardAction>` (góc phải CardHeader), ẩn khi `isReadOnly`.
- `Input` trong table cell: `className="border-0 !bg-card"` để hòa với nền card.
- Cột cuối cùng luôn là cột action (xóa dòng) – dùng `DropdownMenu` với icon `MoreHorizontal`.
- `<TableFooter>` luôn hiển thị Subtotal / Tax / Total; cột cuối padding bằng `<TableCell colSpan={1}></TableCell>`.
- Nếu form không có line items (không cần table), bỏ card này và đặt toàn bộ fields vào `<CardContent className="grid ...">`.

---

### 5.4 Card: Trạng thái & Actions (Sidebar Card)

```tsx
<Card className="mx-auto w-full">
  <CardHeader>
    <CardTitle>Trạng thái</CardTitle>
    <CardDescription>Trạng thái của bản ghi</CardDescription>
  </CardHeader>
  <CardContent>
    {/* Status badge with dot indicator */}
    <div className="relative w-full">
      <span className={`absolute left-3 top-1/2 -translate-y-1/2 h-2 w-2 rounded-full ${getStatusColor(currentStatus)}`} />
      <Input className="pl-8 uppercase" value={currentStatus} readOnly />
    </div>
    {/* Optional: secondary status (e.g., approval status) */}
  </CardContent>
  <CardFooter className="flex flex-col gap-4 pt-0">
    {/* Action buttons stacked vertically */}
    <ButtonSpin isLoading={isSubmitting} variant="secondary" className="w-full" ...>
      {isEditMode ? "Cập nhật" : "Lưu"}
    </ButtonSpin>
    <ButtonSpin variant="default" ... className="w-full">Xác nhận</ButtonSpin>
    <ButtonSpin variant="default" ... className="w-full">Duyệt</ButtonSpin>
    <ButtonSpin variant="outline" ... className="w-full">Từ chối</ButtonSpin>
  </CardFooter>
</Card>
```

**Quy tắc:**
- Sidebar Card chiếm `col-span-2` (xem phần 5.1).
- **Status badge**: dùng `<Input readOnly className="pl-8 uppercase">` + `<span>` dot tuyệt đối bên trái; màu dot qua hàm `getStatusColor`.
- **Màu status chuẩn**:
  | Status | Class |
  |---|---|
  | `draft` | `bg-amber-300` |
  | `confirmed` | `bg-blue-500` |
  | `approved` | `bg-green-500` |
  | `rejected` | `bg-red-500` |
  | mặc định | `bg-slate-300` |
- **Action buttons**: dùng `<ButtonSpin>` từ `@components/common/ButtonSpin.tsx`, **không** dùng `<Button>` thuần cho các nút có trạng thái loading.
- Tất cả action buttons: `className="w-full"`, xếp dọc trong `<CardFooter className="flex flex-col gap-4 pt-0">`.
- Điều kiện hiện button: kiểm tra `currentStatus` và phân quyền (`isFinanceOrAdmin`, ...) – **không** hiển thị tất cả cùng lúc.

---

### 5.5 Chuẩn Loading State & Read-Only Mode

- **Loading toàn trang**: `if (isLoading) return <div className="p-8 text-center text-muted-foreground">Đang tải...</div>;`
- **isReadOnly flag**:
  ```ts
  const isReadOnly = isEditMode && currentStatus.toLowerCase() !== "draft";
  ```
- Khi `isReadOnly = true`:
  - `Input`: thêm `readOnly={isReadOnly}`
  - `Select`: thêm `disabled={isReadOnly}`
  - Ẩn nút "Thêm dòng" (CardAction) và cột action (DropdownMenu) trong table.

---

### 5.6 Form State Management (react-hook-form + zod)

- Luôn dùng `useForm` + `zodResolver` + `useFieldArray` (nếu có line items).
- Dùng `useWatch` để reactive tính toán (subtotal, tax, total) thay vì `watch` trực tiếp trong render.
- Dùng `useMemo` cho các giá trị tính toán từ `useWatch`.
- Dùng `useEffect` để `form.setValue` đồng bộ ngược các giá trị phụ thuộc (amount, taxAmount) sau khi tính toán.
- `fetchDetail` (edit mode) dùng `useCallback` + gọi `form.reset(...)` để hydrate form.
- Loading state riêng cho từng action: `isSubmitting`, `isConfirmLoading`, `isApproveLoading`, `isRejectLoading`.

---

### 5.7 Checklist khi tạo Form Page mới

- [ ] Wrapper `<div className="space-y-6">`
- [ ] Page header: nút `ArrowLeft` ghost + `<h2 className="text-xl font-semibold">`
- [ ] `<Form>` + `<form className="grid grid-cols-10 gap-6">`
- [ ] Cột trái `col-span-8` chứa ít nhất 1 Card thông tin chính (`grid md:grid-cols-3 gap-4`)
- [ ] Cột phải `col-span-2` chứa Card Trạng thái + Actions
- [ ] Status badge với dot indicator + `Input` read-only uppercase
- [ ] Action buttons dùng `<ButtonSpin>` + `w-full` + `flex flex-col gap-4`
- [ ] `isReadOnly` flag kiểm soát toàn bộ form inputs
- [ ] Loading state `<div className="p-8 text-center text-muted-foreground">` cho toàn trang
- [ ] Zod schema validation + `zodResolver`
- [ ] Toast notification (`useToastApp`) cho mọi action success/error

---

### 5.8 Quy chuẩn Dialog hiển thị thông tin (Quick View / Detail Dialog)

Mọi dialog có nhiệm vụ hiển thị chi tiết thông tin (chế độ chỉ đọc - read-only) trong EFMS đều phải tuân theo cấu trúc thống nhất sau:

#### 1. Cấu trúc và Layout
- Tiêu đề Dialog phải đi kèm với icon minh họa thích hợp (ví dụ: `ReceiptText`, `FileText`).
- Các badge trạng thái (nếu có) phải được hiển thị gọn gàng bên dưới tiêu đề (sử dụng `DialogDescription`).
- **Tất cả các trường thông tin** phải được bọc trong các thẻ `<Label>` và ô `<Input readOnly />` để mang lại giao diện đồng bộ, sạch sẽ, thay vì sử dụng text thuần hay các row hiển thị tùy ý.
- Sử dụng grid layout hợp lý (ví dụ: `grid grid-cols-2 gap-4` cho các hàng chứa 2 thông tin) để đảm bảo tính cân đối.

#### 2. Quy chuẩn hiển thị Số tiền (Currency / Amount)
Để đảm bảo tính nhất quán trong các báo cáo và giao diện tài chính:
- **Định dạng hiển thị**: Định dạng số phân tách hàng nghìn và nối với tên mã tiền tệ phía sau (ví dụ: `1.000.000 VND`, `5.000 USD`).
- **Không sử dụng ký tự "đ" hoặc "₫"**: Tuyệt đối không thêm ký hiệu tiền tệ tiếng Việt "đ" hay "₫".
- **Kiểu dáng và Màu sắc**: 
  - KHÔNG sử dụng font bold hoặc font-semibold cho giá trị số tiền (sử dụng độ đậm font chữ mặc định).
  - KHÔNG thêm màu sắc (như xanh lá `text-green-600` hay cam `text-amber-600`) cho số tiền, giữ màu văn bản mặc định của input/văn bản.

---

## 6. Quy chuẩn Code & Sử dụng Context (MCP Server)

Khi làm việc với code, component UI, hoặc debug bug tại frontend **efms-react**, bạn **phải** sử dụng **MCP Server `codegraph-efms-react`** để lấy context toàn diện và chính xác nhất.
- Khởi động/kết nối MCP Server `codegraph-efms-react` (lệnh `codegraph serve --mcp` với thư mục `/Users/linhofthenorth/VietLinh/efms-project-info/efms-react`).
- Luôn ưu tiên dùng các tool do server này cung cấp (như `codegraph_search`, `codegraph_context`, `codegraph_callers`, `codegraph_callees`, `codegraph_impact`) thay vì tìm kiếm (grep) thủ công để tiết kiệm context window và tăng độ chính xác.
