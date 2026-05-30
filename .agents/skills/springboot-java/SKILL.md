---
name: springboot-java
description: >
  Expert Spring Boot 3.x / Java 21 assistant. Use this skill for ANY of the following:
  generating boilerplate code (Entity, Repository, Service, Controller, DTO, Mapper);
  designing layered / DDD / hexagonal architecture; configuring application.yml, Spring
  Security (JWT/OAuth2), datasource, Docker & Docker Compose; writing unit and integration
  tests (JUnit 5, Mockito, MockMvc, Testcontainers); global exception handling
  (@ControllerAdvice, custom error codes); OpenAPI / Swagger documentation;
  structured trace logging (MDC, request/response interceptors); and standardised
  paginated API responses using Request/Response DTOs with data, message, status fields.
  Trigger whenever the user mentions Spring Boot, Spring MVC, Spring Data JPA, Spring
  Security, @RestController, @Service, @Repository, @Entity, Maven, Gradle, or any
  Java backend task — even if the request feels simple.
---

# Spring Boot Java Skill

Java 21 + Spring Boot 3.x full-stack backend skill.  
Always produce **production-quality, compilable** code unless told otherwise.

---

## Quick-Reference Index

| Topic | Reference File |
|---|---|
| Project structure, naming, layers | `references/architecture.md` |
| Entity, Repository, Service, Controller boilerplate | `references/boilerplate.md` |
| Request/Response DTOs, Pagination wrapper | `references/dto-pagination.md` |
| Global exception handling + error codes | `references/exception-handling.md` |
| OpenAPI / Swagger annotations | `references/openapi.md` |
| Trace logging (MDC, interceptors) | `references/logging.md` |
| Spring Security – JWT / OAuth2 | `references/security.md` |
| application.yml, Docker, Docker Compose | `references/configuration.md` |
| Unit & integration tests | `references/testing.md` |

**Rule**: Before writing code for any topic, `view` the matching reference file first.  
For tasks that span multiple topics, read all relevant files.

---

## Non-Negotiable Standards

1. **Language / Framework**: Java 21 (records, sealed classes, pattern matching welcome), Spring Boot 3.3.x.
2. **Build**: Maven (`pom.xml`) by default; switch to Gradle only when user asks.
3. **Mandatory libraries**: Lombok, MapStruct, Spring Validation (`@Valid`), SpringDoc OpenAPI 2.x.
4. **Primary keys**: `UUID` everywhere unless user specifies otherwise.
5. **All APIs return `ApiResponse<T>`** — see `references/dto-pagination.md`.
6. **Pagination**: every list endpoint uses `Page<T>` + `PagedResponse<T>` wrapper.
7. **Logging**: SLF4J + MDC `traceId` on every request — see `references/logging.md`.
8. **Exception handling**: never throw raw exceptions to the client — see `references/exception-handling.md`.
9. **No `@Autowired` on fields** — use constructor injection (Lombok `@RequiredArgsConstructor`).
10. **Profiles**: `dev`, `staging`, `prod` in separate `application-{profile}.yml` files.

---

## Decision Flow

```
User request
    │
    ├── New feature / CRUD?        → read boilerplate.md + dto-pagination.md
    ├── Error / exception?         → read exception-handling.md
    ├── Security config?           → read security.md
    ├── Swagger / docs?            → read openapi.md
    ├── Logging / tracing?         → read logging.md
    ├── Config / infra?            → read configuration.md
    ├── Tests?                     → read testing.md
    └── Architecture question?     → read architecture.md
```

---

## Code Style Checklist (apply to every generated class)

- [ ] Package follows `com.<company>.<service>.<layer>` convention
- [ ] `@Slf4j` on every class that needs logging
- [ ] `log.info/debug/warn/error` with structured params, never string concat
- [ ] `@Operation` + `@Tag` on controllers (Swagger)
- [ ] `@Valid` on `@RequestBody` parameters
- [ ] Service methods are `public`; helper methods are `private`
- [ ] DTOs are immutable Java `record`s (or use Lombok `@Value`) when possible
- [ ] MapStruct `@Mapper(componentModel = "spring")` for entity ↔ DTO
- [ ] Repository custom queries use JPQL `@Query`, not native SQL, unless necessary
