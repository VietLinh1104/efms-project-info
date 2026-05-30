# Architecture & Project Structure

## Recommended Package Layout (Layered Architecture)

```
com.<company>.<service>/
├── config/                    # Spring @Configuration classes
│   ├── SecurityConfig.java
│   ├── OpenApiConfig.java
│   └── WebMvcConfig.java
├── controller/                # @RestController – thin, delegates to service
├── service/                   # Business logic interfaces + implementations
│   └── impl/
├── repository/                # Spring Data JPA interfaces
├── entity/                    # @Entity classes (DB model)
├── dto/
│   ├── request/               # Incoming payload DTOs
│   └── response/              # Outgoing payload DTOs
├── mapper/                    # MapStruct mappers
├── exception/                 # Custom exceptions + @ControllerAdvice
├── filter/                    # Servlet filters (JWT, MDC trace)
├── interceptor/               # HandlerInterceptor (logging)
└── util/                      # Pure utility / helper classes
```

## Naming Conventions

| Artefact | Convention | Example |
|---|---|---|
| Entity | `PascalCase` noun | `Invoice`, `UserAccount` |
| Repository | `<Entity>Repository` | `InvoiceRepository` |
| Service interface | `<Entity>Service` | `InvoiceService` |
| Service impl | `<Entity>ServiceImpl` | `InvoiceServiceImpl` |
| Controller | `<Entity>Controller` | `InvoiceController` |
| Request DTO | `<Action><Entity>Request` | `CreateInvoiceRequest` |
| Response DTO | `<Entity>Response` | `InvoiceResponse` |
| Mapper | `<Entity>Mapper` | `InvoiceMapper` |

## Controller → Service → Repository Contract

- **Controller**: validate input (`@Valid`), call service, return `ApiResponse`.  
  No business logic whatsoever.
- **Service**: orchestrate business rules, throw domain exceptions, call repositories.  
  Never return raw entities — always map to DTOs.
- **Repository**: data access only; no business logic.

## DDD Option (for complex domains)

When the domain is complex, use an inner `domain/` package:

```
domain/
├── model/          # Rich domain objects (not JPA entities)
├── port/
│   ├── in/         # Use-case interfaces (commands/queries)
│   └── out/        # Repository port interfaces
└── service/        # Domain services
infrastructure/
├── persistence/    # JPA adapters implementing out-ports
└── web/            # REST controllers implementing in-ports
```
