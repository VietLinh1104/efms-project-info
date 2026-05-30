# Configuration: application.yml, Docker, Docker Compose

## application.yml (base)

```yaml
spring:
  application:
    name: my-service
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:dev}

  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/mydb}
    username: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:postgres}
    hikari:
      maximum-pool-size: 10
      minimum-idle: 2
      connection-timeout: 30000

  jpa:
    hibernate:
      ddl-auto: validate          # Use Flyway/Liquibase for migrations
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true
        default_batch_fetch_size: 50

  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: true

server:
  port: ${SERVER_PORT:8080}
  servlet:
    context-path: /
  error:
    include-message: never       # Never leak stack traces

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
  endpoint:
    health:
      show-details: when-authorized

app:
  jwt:
    secret: ${JWT_SECRET}        # Must be Base64-encoded, ≥256 bits
    expiration-ms: ${JWT_EXPIRATION_MS:86400000}   # 24h default

logging:
  level:
    com.<company>.<service>: DEBUG
    org.springframework.security: WARN
```

---

## application-dev.yml

```yaml
spring:
  jpa:
    show-sql: true
  flyway:
    clean-on-validation-error: true   # Allows schema resets in dev

logging:
  level:
    root: INFO
    com.<company>: DEBUG

springdoc:
  swagger-ui:
    enabled: true
```

---

## application-prod.yml

```yaml
spring:
  jpa:
    show-sql: false
  datasource:
    hikari:
      maximum-pool-size: 30

logging:
  level:
    root: WARN
    com.<company>: INFO

springdoc:
  swagger-ui:
    enabled: false    # Disable in production
```

---

## Dockerfile (multi-stage)

```dockerfile
# ---- Build stage ----
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN ./mvnw dependency:go-offline -q
COPY src ./src
RUN ./mvnw package -DskipTests -q

# ---- Runtime stage ----
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

COPY --from=builder /app/target/*.jar app.jar

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1
```

---

## docker-compose.yml (dev environment)

```yaml
version: '3.9'

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      SPRING_PROFILES_ACTIVE: dev
      DB_URL: jdbc:postgresql://postgres:5432/mydb
      DB_USERNAME: postgres
      DB_PASSWORD: postgres
      JWT_SECRET: <base64-encoded-256-bit-secret>
    depends_on:
      postgres:
        condition: service_healthy
    restart: on-failure

volumes:
  postgres_data:
```

---

## Flyway Migration Naming

```
src/main/resources/db/migration/
├── V1__init_schema.sql
├── V2__add_products_table.sql
├── V3__add_product_status_column.sql
```

Each file is **append-only** — never edit an existing migration.
