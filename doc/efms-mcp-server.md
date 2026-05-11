# EFMS MCP Server — Tài liệu kỹ thuật

> Tài liệu này mô tả kiến trúc, cơ chế xác thực, và hướng dẫn triển khai MCP Server cho hệ thống EFMS (Enterprise Financial Management System).

---

## Mục lục

1. [Tổng quan](#1-tổng-quan)
2. [Kiến trúc hệ thống](#2-kiến-trúc-hệ-thống)
3. [Cơ chế xác thực](#3-cơ-chế-xác-thực)
   - [Hiểu đúng về 2 lớp auth](#31-hiểu-đúng-về-2-lớp-auth)
   - [OAuth flow — mở browser để đăng nhập](#32-oauth-flow--mở-browser-để-đăng-nhập)
4. [Triển khai stdio (Claude Desktop)](#4-triển-khai-stdio-claude-desktop)
5. [Triển khai HTTP + SSE (Remote Server)](#5-triển-khai-http--sse-remote-server)
6. [So sánh 2 phương thức](#6-so-sánh-2-phương-thức)
7. [Danh sách Tools](#7-danh-sách-tools)
8. [Cấu trúc project](#8-cấu-trúc-project)
9. [Biến môi trường](#9-biến-môi-trường)

---

## 1. Tổng quan

MCP Server là lớp trung gian cho phép **Claude (AI)** gọi trực tiếp vào các API của EFMS — đọc invoice, tạo payment, xem journal entry, v.v. — mà không cần người dùng thao tác thủ công trên giao diện web.

```
Claude Desktop / claude.ai
        │
        │  MCP Protocol
        ▼
  efms-mcp-server (Node.js)
        │
        │  REST + JWT
        ▼
  EFMS API Gateway :8080
        │
   ┌────┴────┐
   ▼         ▼
Identity   Core Service
:8081       :8082
```

**Ví dụ thực tế:** Người dùng gõ vào Claude _"Cho tôi xem danh sách invoice chưa thanh toán tháng 5"_ — Claude tự gọi tool `list_invoices`, lấy dữ liệu từ EFMS và tóm tắt kết quả, không cần mở tab web nào.

---

## 2. Kiến trúc hệ thống

### Các thành phần chính

| Thành phần | Mô tả |
|---|---|
| `Transport Layer` | Nhận/gửi message theo giao thức MCP (stdio hoặc HTTP+SSE) |
| `Tools Registry` | Đăng ký danh sách tools Claude có thể gọi |
| `Auth Handler` | Quản lý JWT — tự login, cache, refresh token |
| `HTTP Client` | Gọi API EFMS với token đã xác thực |

### Công nghệ sử dụng

| Package | Mục đích |
|---|---|
| `@modelcontextprotocol/sdk` | MCP Server SDK chính thức của Anthropic |
| `axios` | HTTP client gọi EFMS API |
| `zod` | Validate input schema cho từng tool |
| `open` | Mở browser tự động (dùng cho stdio OAuth) |
| `typescript` | Type safety toàn project |

---

## 3. Cơ chế xác thực

### 3.1 Hiểu đúng về 2 lớp auth

Hệ thống có **2 lớp xác thực hoàn toàn độc lập**, dễ nhầm lẫn nếu không phân biệt rõ.

#### Lớp 1 — Claude Desktop tin tưởng MCP Server như thế nào?

Câu trả lời: **vì bạn đã khai báo nó trong file config.**

Khi bạn thêm MCP Server vào `claude_desktop_config.json`, Claude Desktop đọc file đó và khởi động MCP Server như một tiến trình con (child process) trên máy tính của bạn. Hai bên nói chuyện qua "ống" nội bộ (stdio) — không qua internet, không cần password hay token.

> Lớp 1 không có "auth" theo nghĩa truyền thống. Bạn tin → Claude Desktop tin → xong.

#### Lớp 2 — MCP Server vào hệ thống EFMS bằng cách nào?

MCP Server cần JWT token hợp lệ mới gọi được EFMS API. Có 2 cách xử lý:

**Cách A — Service Account (đơn giản):** MCP Server dùng một tài khoản hệ thống duy nhất, tự login, cache token, tự refresh. Mọi user Claude Desktop đều dùng chung một quyền.

**Cách B — OAuth flow (khuyến nghị):** Mỗi user đăng nhập bằng tài khoản EFMS của chính họ. Quyền hạn theo đúng role từng người, giống như khi dùng web app EFMS bình thường.

---

### 3.2 OAuth flow — mở browser để đăng nhập

Đây là cách hoạt động khi user kết nối lần đầu tiên:

```
1. User gọi tool lần đầu (chưa có token)
        │
        ▼
2. MCP Server phát hiện chưa có token
        │
        ▼
3. MCP Server mở browser → efms.com/login?redirect_uri=localhost:9999/callback
        │
        ▼
4. User đăng nhập trên web EFMS của bạn
        │
        ▼
5. EFMS redirect về → localhost:9999/callback?token=eyJhbGc...
        │
        ▼
6. MCP Server nhận token, lưu vào ~/.efms-mcp/token.json
        │
        ▼
7. Tiếp tục xử lý tool call ban đầu
        │
        ▼
8. Lần sau: đọc token từ file, không hỏi lại
```

**Quan trọng:** Browser tự mở, user không cần copy-paste link nào trong chat cả. Trải nghiệm giống hệt "Đăng nhập bằng Google".

---

## 4. Triển khai stdio (Claude Desktop)

### Cách hoạt động

MCP Server chạy **trực tiếp trên máy user** dưới dạng child process do Claude Desktop spawn. Giao tiếp qua stdin/stdout.

### Cấu hình Claude Desktop

Thêm vào file `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) hoặc `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "efms": {
      "command": "node",
      "args": ["/absolute/path/to/efms-mcp-server/dist/index.js"],
      "env": {
        "EFMS_BASE_URL": "http://localhost:8080",
        "EFMS_AUTH_URL": "http://efms.com/auth/login",
        "EFMS_CALLBACK_PORT": "9999"
      }
    }
  }
}
```

### Entry point — `src/index.ts`

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { registerAllTools } from "./tools/index.js";

const server = new McpServer({
  name: "efms-mcp-server",
  version: "1.0.0",
});

registerAllTools(server);

const transport = new StdioServerTransport();
await server.connect(transport);
```

### Auth Handler — `src/auth/tokenManager.ts`

```typescript
import open from "open";
import http from "http";
import fs from "fs";
import path from "path";

const TOKEN_PATH = path.join(process.env.HOME!, ".efms-mcp", "token.json");

interface StoredToken {
  accessToken: string;
  expiresAt: number;
}

class TokenManager {
  private cached: StoredToken | null = null;

  async getToken(): Promise<string> {
    // 1. Thử đọc từ cache trong memory
    if (this.cached && Date.now() < this.cached.expiresAt - 60_000) {
      return this.cached.accessToken;
    }

    // 2. Thử đọc từ file trên disk
    const fromDisk = this.readFromDisk();
    if (fromDisk && Date.now() < fromDisk.expiresAt - 60_000) {
      this.cached = fromDisk;
      return fromDisk.accessToken;
    }

    // 3. Chưa có hoặc hết hạn → mở browser để đăng nhập
    return await this.loginViaBrowser();
  }

  private readFromDisk(): StoredToken | null {
    try {
      const raw = fs.readFileSync(TOKEN_PATH, "utf-8");
      return JSON.parse(raw);
    } catch {
      return null;
    }
  }

  private saveToDisk(token: StoredToken) {
    fs.mkdirSync(path.dirname(TOKEN_PATH), { recursive: true });
    fs.writeFileSync(TOKEN_PATH, JSON.stringify(token));
  }

  private loginViaBrowser(): Promise<string> {
    return new Promise((resolve, reject) => {
      const port = Number(process.env.EFMS_CALLBACK_PORT ?? 9999);
      const callbackUrl = `http://localhost:${port}/callback`;
      const loginUrl = `${process.env.EFMS_AUTH_URL}?redirect_uri=${encodeURIComponent(callbackUrl)}`;

      // Bật server nhỏ để hứng callback
      const server = http.createServer((req, res) => {
        const url = new URL(req.url!, `http://localhost:${port}`);
        const token = url.searchParams.get("token");
        const expiresIn = Number(url.searchParams.get("expires_in") ?? 3600);

        if (!token) {
          res.end("Lỗi: không nhận được token.");
          return reject(new Error("No token in callback"));
        }

        const stored: StoredToken = {
          accessToken: token,
          expiresAt: Date.now() + expiresIn * 1000,
        };

        this.cached = stored;
        this.saveToDisk(stored);

        res.end("<h2>Đăng nhập thành công! Bạn có thể đóng tab này.</h2>");
        server.close();
        resolve(token);
      });

      server.listen(port, () => {
        // Mở browser — hệ điều hành tự xử lý
        open(loginUrl);
      });

      // Timeout sau 5 phút nếu user không đăng nhập
      setTimeout(() => {
        server.close();
        reject(new Error("Login timeout sau 5 phút"));
      }, 5 * 60 * 1000);
    });
  }
}

export const tokenManager = new TokenManager();
```

### HTTP Client — `src/client/efmsClient.ts`

```typescript
import axios from "axios";
import { tokenManager } from "../auth/tokenManager.js";

export const efmsClient = axios.create({
  baseURL: process.env.EFMS_BASE_URL,
  timeout: 15_000,
});

// Tự động inject token vào mọi request
efmsClient.interceptors.request.use(async (config) => {
  const token = await tokenManager.getToken();
  config.headers.Authorization = `Bearer ${token}`;
  return config;
});
```

---

## 5. Triển khai HTTP + SSE (Remote Server)

### Cách hoạt động

MCP Server chạy **trên server của bạn**, expose qua HTTP. Client (Claude Desktop hoặc claude.ai) kết nối vào qua mạng.

Điểm khác biệt quan trọng: **MCP Server không thể tự mở browser** vì nó chạy trên server, không phải máy user. Thay vào đó, server trả về `401` theo đúng chuẩn **MCP OAuth 2.1** — chính MCP client (Claude Desktop) sẽ tự lo việc mở browser và lấy token.

### Entry point — `src/index-http.ts`

```typescript
import express from "express";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";
import { registerAllTools } from "./tools/index.js";
import { verifyToken } from "./auth/jwtVerifier.js";

const app = express();
app.use(express.json());

// OAuth metadata endpoint — MCP client đọc để biết cách login
app.get("/.well-known/oauth-authorization-server", (req, res) => {
  res.json({
    issuer: process.env.EFMS_BASE_URL,
    authorization_endpoint: `${process.env.EFMS_AUTH_URL}`,
    token_endpoint: `${process.env.EFMS_BASE_URL}/api/identity/auth/token`,
    response_types_supported: ["code"],
    grant_types_supported: ["authorization_code", "refresh_token"],
  });
});

// SSE endpoint — kết nối MCP
app.get("/sse", async (req, res) => {
  // Kiểm tra token từ Authorization header
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    // Trả 401 kèm thông tin để MCP client biết cần login ở đâu
    res.setHeader(
      "WWW-Authenticate",
      `Bearer realm="efms", error="unauthorized", ` +
      `authorization_uri="${process.env.EFMS_AUTH_URL}"`
    );
    return res.status(401).json({ error: "Chưa đăng nhập" });
  }

  const token = authHeader.slice(7);
  const user = await verifyToken(token); // Verify JWT với EFMS Identity
  if (!user) {
    return res.status(401).json({ error: "Token không hợp lệ" });
  }

  // Tạo MCP server riêng cho mỗi session, kèm context user
  const server = new McpServer({ name: "efms-mcp-server", version: "1.0.0" });
  registerAllTools(server, { userId: user.id, companyId: user.companyId });

  const transport = new SSEServerTransport("/message", res);
  await server.connect(transport);
});

app.post("/message", (req, res) => {
  // MCP client gửi message vào đây
});

app.listen(3000, () => console.log("EFMS MCP Server running on :3000"));
```

### Verify token — `src/auth/jwtVerifier.ts`

```typescript
import axios from "axios";

interface UserClaims {
  id: string;
  companyId: string;
  email: string;
  permissions: string[];
}

// Gọi vào EFMS Identity để verify token (hoặc decode JWT local nếu có shared secret)
export async function verifyToken(token: string): Promise<UserClaims | null> {
  try {
    const res = await axios.get(
      `${process.env.EFMS_BASE_URL}/api/identity/auth/me`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    return res.data.data;
  } catch {
    return null;
  }
}
```

### Cấu hình Claude Desktop cho HTTP

```json
{
  "mcpServers": {
    "efms-remote": {
      "url": "https://mcp.efms.com/sse",
      "transport": "sse"
    }
  }
}
```

> Với HTTP transport, Claude Desktop tự lo việc gắn `Authorization` header vào mỗi request sau khi user đã đăng nhập.

---

## 6. So sánh 2 phương thức

| Tiêu chí | stdio | HTTP + SSE |
|---|---|---|
| Chạy ở đâu? | Máy user (local) | Server của bạn (remote) |
| Ai mở browser? | MCP Server tự mở | MCP Client (Claude Desktop) tự mở |
| Token lưu ở đâu? | File trên máy user | MCP Client tự giữ |
| Phù hợp khi nào? | Nội bộ, ít user, dev | Nhiều user, expose internet |
| Bảo mật | Phụ thuộc vào máy user | Kiểm soát được ở server |
| Cài đặt phức tạp? | Đơn giản hơn | Cần HTTPS, domain thật |
| Phân quyền theo user? | Cần tự xử lý | Tự nhiên — mỗi session có token riêng |

---

## 7. Danh sách Tools

### Invoices

| Tool | Mô tả |
|---|---|
| `list_invoices` | Lấy danh sách invoice, filter theo type/status/partner/date |
| `get_invoice` | Chi tiết một invoice kèm các dòng |
| `create_invoice` | Tạo invoice mới ở trạng thái draft |
| `confirm_invoice` | Xác nhận invoice → trigger Camunda workflow |
| `delete_invoice` | Xóa invoice (chỉ được khi còn draft) |
| `list_approval_tasks` | Danh sách User Tasks đang chờ duyệt (Tasklist API) |
| `complete_approval_task` | Hoàn thành một approval task (Zeebe REST API) |

### Payments

| Tool | Mô tả |
|---|---|
| `list_payments` | Danh sách payments |
| `get_payment` | Chi tiết một payment |
| `create_payment` | Tạo payment mới |
| `post_payment` | Ghi nhận payment vào General Ledger |
| `allocate_payment` | Phân bổ payment vào các open invoice |

### Journal Entries

| Tool | Mô tả |
|---|---|
| `list_journals` | Danh sách journal entries |
| `get_journal` | Chi tiết một journal entry |
| `create_journal` | Tạo journal entry mới (double-entry) |
| `delete_journal` | Xóa journal entry (chỉ khi draft) |

### Partners & Accounts

| Tool | Mô tả |
|---|---|
| `list_partners` | Danh sách khách hàng/nhà cung cấp |
| `get_partner` | Chi tiết một partner |
| `create_partner` | Tạo partner mới |
| `list_accounts` | Chart of Accounts |

### Reports

| Tool | Mô tả |
|---|---|
| `get_trial_balance` | Bảng cân đối phát sinh theo fiscal period |
| `get_aging_report` | Báo cáo tuổi nợ AR/AP |

---

## 8. Cấu trúc project

```
efms-mcp-server/
├── src/
│   ├── index.ts              # Entry point stdio
│   ├── index-http.ts         # Entry point HTTP + SSE
│   ├── auth/
│   │   ├── tokenManager.ts   # OAuth flow, cache token (stdio)
│   │   └── jwtVerifier.ts    # Verify token từ request header (HTTP)
│   ├── client/
│   │   └── efmsClient.ts     # axios instance + interceptor
│   ├── tools/
│   │   ├── index.ts          # Đăng ký tất cả tools
│   │   ├── invoices.ts
│   │   ├── payments.ts
│   │   ├── journals.ts
│   │   ├── partners.ts
│   │   ├── accounts.ts
│   │   └── reports.ts
│   └── types/
│       └── efms.ts           # TypeScript types
├── package.json
├── tsconfig.json
└── .env
```

---

## 9. Biến môi trường

### stdio

```env
EFMS_BASE_URL=http://localhost:8080
EFMS_AUTH_URL=http://efms.com/auth/login
EFMS_CALLBACK_PORT=9999
```

### HTTP + SSE

```env
EFMS_BASE_URL=http://localhost:8080
EFMS_AUTH_URL=https://efms.com/auth/login
JWT_SECRET=your-shared-secret
PORT=3000
```

> **Lưu ý bảo mật:** Không commit file `.env` lên git. Dùng `.env.example` với giá trị placeholder để hướng dẫn setup.