---
name: efms-common-service
description: Guidelines and architectural rules for developing the EFMS Common Service (Attachments, Comments).
---

# EFMS Common Service Development Guidelines

This skill provides context and guidelines whenever you are working on the `efms_common_service` module.

## 1. Overview
The **EFMS Common Service** is responsible for managing cross-cutting concerns that apply to various entities across the entire system, regardless of which core module they belong to.
Specifically:
- **Attachments**: File metadata and storage management (file sizes, names, URLs).
- **Comments**: Discussions, activity logs, and workflow approval comments.

It typically runs on Port `8083` and expects incoming gateway requests prefixing `/api/common`.

## 2. Database & Data Association (Polymorphic)
Unlike the Core or Identity service, the Common service heavily utilizes **polymorphic relationships** to maintain independence.
- It does **not** rely on explicit foreign keys (e.g. `REFERENCES invoices(id)`).
- Attachments and Comments are standalone entities.
- Data is linked via a universal intermediate table `entity_links`.
  - `reference_id`: The UUID of the external business object (e.g., Invoice ID).
  - `reference_type`: A string identifier for the target object class (e.g., `'invoice'`, `'payment'`).
  - `item_id`: The UUID of the target comment or attachment.
  - `item_type`: A discriminator string, either `'comment'` or `'attachment'`.

When building endpoints to fetch/upload attachments, or append comments:
- Always enforce multi-tenancy checking (`company_id`) to ensure users only see comments belonging to their enterprise.
- Use `reference_id` and `reference_type` in the API path or payload so that Common Service knows what it's mapping to.

## 3. Authentication & Security
- Must implement JWT checking for `/api/common/**` identical to how Core and Identity validate the stateless token.
- Validate `companyId` and `userId` directly from the Spring Security Context claims.

## 4. Tech Stack & Standardization
- **Package format**: `com.linhdv.efms_common_service.*`
- Maintain consistency using: Java 21, Spring Boot 3.3.x, Lombok, MapStruct.
- Controllers must strictly wrap responses using the generic `ApiResponse<T>` object. Exception handlers must convert any DB isolation or invalid references into appropriate HTTP error codes bundled within the `ApiResponse`.
