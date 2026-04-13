---
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
  - **Core Service (`/api/core`)**: Handles all financial entities like `invoices`, `payments`, `journal_entries`, `accounts`, `partners`, and `fiscal_periods`.
  
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
  - **Audit Logging API**: Both services have `/v1/audit-logs/record` endpoints.
  Do not initialize Axios instances directly in your components.

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
