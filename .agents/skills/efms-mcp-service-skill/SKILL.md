---
name: efms-mcp-server
description: >
  MCP Server (Node.js/TypeScript) đóng vai trò trung gian giữa Claude AI và hệ thống EFMS.
  Tham khảo skill này khi cần: tạo tool mới, xử lý auth (stdio OAuth hoặc HTTP JWT),
  gọi EFMS API, hoặc hiểu luồng dữ liệu từ Claude → MCP → EFMS API Gateway.
---

# EFMS MCP Server — Skill Reference

## Tổng quan nhanh

```
Claude (AI)
    │  MCP Protocol (stdio hoặc HTTP+SSE)
    ▼
efms-mcp-server  ←── skill này cover toàn bộ phần này
    │  REST + JWT
    ▼
EFMS API Gateway :8080
    ├── /api/identity/** → Identity Service :8081
    └── /api/core/**    → Core Service :8082
```

---

## Cấu trúc project

```
efms-mcp-server/
├── src/
│   ├── index.ts              # Entry point stdio
│   ├── index-http.ts         # Entry point HTTP + SSE
│   ├── auth/
│   │   ├── tokenManager.ts   # OAuth browser flow + file cache (stdio)
│   │   └── jwtVerifier.ts    # Verify Bearer token từ header (HTTP)
│   ├── client/
│   │   └── efmsClient.ts     # axios instance với auth interceptor
│   ├── tools/
│   │   ├── index.ts          # registerAllTools()
│   │   └── efms.ts           # All registered tools
│   └── types/
│       └── efms.ts
├── package.json
└── tsconfig.json
```

---

## Auth — Giao thức HTTP + SSE (OAuth 2.1)

Hệ thống EFMS MCP Server sử dụng 100% **HTTP + SSE Transport** kết hợp với luồng xác thực **OAuth 2.1** tiêu chuẩn.

### Nguyên tắc hoạt động

1. **Không tự mở Browser:** MCP Server không tự gọi trình duyệt. Thay vào đó, Claude Desktop (đóng vai trò là OAuth Client) sẽ đọc cấu hình, mở trình duyệt để xác thực.
2. **Xác thực từng Request:** Mỗi request từ Claude Desktop gửi lên `/mcp` đều kèm theo header `Authorization: Bearer <token>`.
3. **Mỗi Session một User:** Server sẽ verify token bằng cách gọi về EFMS Identity Service. Khi token hợp lệ, nó sẽ tạo một `McpServer` instance gắn với `companyId` của user đó để phân quyền dữ liệu (Multi-tenant).

---

### OAuth Metadata Endpoint (Bắt buộc)

Claude Desktop tự động tìm thông tin xác thực tại endpoint này (theo chuẩn RFC 8414).

```typescript
app.get("/.well-known/oauth-authorization-server", (req, res) => {
  const baseUrl = process.env.EFMS_BASE_URL || "http://localhost:8080";
  res.json({
    issuer: baseUrl,
    authorization_endpoint: `${baseUrl}/api/identity/oauth/authorize`,
    token_endpoint: `${baseUrl}/api/identity/oauth/token`,
    response_types_supported: ["code"],
    grant_types_supported: ["authorization_code", "refresh_token"],
    code_challenge_methods_supported: ["S256"],
    scopes_supported: ["openid", "profile", "email"]
  });
});
```

### Endpoint /mcp (StreamableHTTP Transport)

Đây là nơi Claude Desktop gửi lệnh thực thi tools. Khác với thiết kế SSE cũ chia làm 2 endpoint `/sse` và `/message`, MCP SDK mới sử dụng `StreamableHTTPServerTransport` gói gọn trong duy nhất endpoint `/mcp` (POST).

```typescript
app.post("/mcp", async (req, res) => {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith("Bearer ")) {
    console.error("[MCP] ❌ Thiếu token");
    return res.status(401).json({ error: "Unauthorized" });
  }

  const token = authHeader.slice(7);

  try {
    // Gọi Identity Service để verify token và lấy thông tin User
    const identityRes = await axios.get(
      `${process.env.EFMS_BASE_URL}/api/identity/auth/me`,
      { headers: { Authorization: `Bearer ${token}` } }
    );

    const user = identityRes.data.data;
    if (!user?.companyId) {
      return res.status(400).json({ error: "Missing companyId" });
    }

    console.error(`[MCP] 👤 ${user.email} | ${req.body?.method}`);

    // Khởi tạo MCP server instance riêng cho mỗi request với context
    const server = new McpServer({ name: "efms-mcp-server", version: "1.0.0" });
    registerAllTools(server, { token, companyId: user.companyId });

    // Dùng transport mới (StreamableHTTP)
    const transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: undefined,
    } as any);

    await server.connect(transport as any);
    await transport.handleRequest(req, res, req.body);

  } catch (error: any) {
    console.error(`[MCP] ❌ ${error.message}`);
    if (!res.headersSent) {
      res.status(error.response?.status || 500).json({ error: error.message });
    }
  }
});
```

---

### Cấu hình Claude Desktop

Vì sử dụng Remote HTTP Server, cấu hình trong `claude_desktop_config.json` cần chỉ định loại `http` và phần `oauth` để trỏ về API Gateway của hệ thống.

```json
{
  "mcpServers": {
    "efms-mcp": {
      "type": "http",
      "url": "https://efms-mcp-server-sse-production.up.railway.app/mcp",
      "oauth": {
        "authorization_server_metadata_url": "https://efms-api-gateway-production.up.railway.app/api/identity/.well-known/oauth-authorization-server",
        "client_id": "claude-connector"
      }
    }
  }
}
```

---

## Viết Tool mới

Mọi tool đều theo cấu trúc này:

```typescript
// src/tools/efms.ts
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { createEfmsClient } from "../client/efmsClient.js";

export function registerEfmsTools(server: McpServer, ctx: { token: string; companyId?: string }) {
  const client = createEfmsClient(ctx.token, ctx.companyId);

  server.tool(
    "list_invoices",
    "Liệt kê danh sách hóa đơn",
    {
      status: z.string().optional(),
      invoiceType: z.string().optional(),
      partnerId: z.string().optional(),
      page: z.number().default(0),
      size: z.number().default(20),
    },
    async (params) => {
      const response = await client.get("/api/core/v1/invoices", { 
        params: { ...params, companyId: ctx.companyId } 
      });
      return {
        content: [{ type: "text", text: JSON.stringify(response.data.data, null, 2) }],
      };
    }
  );

  // Thêm các tool khác tương tự...
}
```

```typescript
// src/tools/index.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { registerEfmsTools, type McpContext } from "./efms.js";

export function registerAllTools(server: McpServer, ctx: McpContext) {
  registerEfmsTools(server, ctx);
}
```

---

## Danh sách tools cần implement

### Invoices
- `list_invoices` — filter: status, type, partner, fromDate, toDate
- `get_invoice` — trả về invoice + invoice_lines
- `create_invoice` — tạo draft, validate fiscal_period mở
- `confirm_invoice` — POST /post → trigger Camunda
- `delete_invoice` — chỉ khi status = draft
- `list_approval_tasks` — Gọi `/api/core/v1/invoice-tasks/tasks` trả về danh sách kèm taskId
- `complete_approval_task` — (Sắp tới) Tích hợp Zeebe REST API v2 `/v2/user-tasks/{taskId}/completion`

### Payments
- `list_payments`, `get_payment`, `create_payment`
- `post_payment` — POST /v1/payments/{id}/post
- `allocate_payment` — POST /v1/payments/{id}/allocate

### Journals
- `list_journals`, `get_journal`, `create_journal`, `delete_journal`

### Partners & Accounts
- `list_partners`, `get_partner`, `create_partner`
- `list_accounts` — Chart of Accounts

### Reports
- `get_trial_balance` — params: fiscalPeriodId
- `get_aging_report` — params: type (AR/AP), asOfDate

---

## Quy tắc quan trọng

1. **Luôn gọi `tokenManager.getToken()`** trước mọi request (đã tự động qua axios interceptor).
2. **Không hardcode companyId** — lấy từ token claims hoặc ctx được truyền vào.
3. **Fiscal period phải open** trước khi tạo/post transaction — gọi `/v1/accounting/fiscal-periods` kiểm tra trước.
4. **Monetary amounts dùng string** khi truyền vào tool args — EFMS xử lý `BigDecimal`, tránh float precision.
5. **HTTP transport:** mỗi SSE session tạo một McpServer instance riêng để isolate context user.
6. **stdio transport:** token file lưu tại `~/.efms-mcp/token.json`, refresh tự động 60 giây trước khi hết hạn.

---

## Biến môi trường

| Biến | stdio | HTTP | Mô tả |
|---|:---:|:---:|---|
| `EFMS_BASE_URL` | ✓ | ✓ | Base URL của EFMS API Gateway |
| `EFMS_AUTH_URL` | ✓ | ✓ | URL trang login EFMS |
| `EFMS_CALLBACK_PORT` | ✓ | — | Port localhost để hứng OAuth callback (mặc định 9999) |
| `JWT_SECRET` | — | ✓ | Shared secret để verify JWT local (nếu không dùng /auth/me) |
| `PORT` | — | ✓ | Port HTTP server (mặc định 3000) |

---

## So sánh nhanh stdio vs HTTP

| | stdio | HTTP + SSE |
|---|---|---|
| Chạy ở đâu | Máy user | Server remote |
| Ai mở browser | MCP Server tự mở | MCP Client tự mở |
| Token lưu ở đâu | `~/.efms-mcp/token.json` | MCP Client giữ |
| Phân quyền | Dùng chung 1 token | Mỗi user 1 token riêng |
| Phù hợp | Nội bộ, dev, ít user | Production, nhiều user |