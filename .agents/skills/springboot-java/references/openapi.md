# OpenAPI / Swagger Configuration

## Maven Dependency

```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.5.0</version>
</dependency>
```

---

## OpenApiConfig

```java
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("My Service API")
                        .description("REST API documentation")
                        .version("v1.0")
                        .contact(new Contact()
                                .name("Backend Team")
                                .email("backend@company.com")))
                .addSecurityItem(new SecurityRequirement().addList("bearerAuth"))
                .components(new Components()
                        .addSecuritySchemes("bearerAuth", new SecurityScheme()
                                .name("bearerAuth")
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("Provide your JWT token")));
    }
}
```

---

## application.yml settings

```yaml
springdoc:
  api-docs:
    path: /api-docs
  swagger-ui:
    path: /swagger-ui.html
    operations-sorter: alpha
    tags-sorter: alpha
  show-actuator: false
  packages-to-scan: com.<company>.<service>.controller
```

---

## Controller Annotations

```java
@Tag(name = "Products", description = "CRUD operations for products")
@RestController
@RequestMapping("/api/v1/products")
public class ProductController {

    @Operation(
        summary = "Create a new product",
        description = "Creates a product and returns the created resource"
    )
    @ApiResponses({
        @ApiResponse(responseCode = "201", description = "Product created",
            content = @Content(schema = @Schema(implementation = ProductResponse.class))),
        @ApiResponse(responseCode = "400", description = "Validation error",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "409", description = "Duplicate product name")
    })
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ProductResponse> create(@Valid @RequestBody CreateProductRequest request) {
        // ...
    }

    @Operation(summary = "List products", description = "Paginated, filterable product list")
    @Parameter(name = "search",    description = "Partial name match", example = "laptop")
    @Parameter(name = "status",    description = "Filter by status")
    @Parameter(name = "page",      description = "0-indexed page number", example = "0")
    @Parameter(name = "size",      description = "Page size (max 100)",   example = "20")
    @Parameter(name = "sort",      description = "Sort field,direction",  example = "createdAt,desc")
    @GetMapping
    public ApiResponse<PagedResponse<ProductResponse>> list(
            @ModelAttribute ProductFilterRequest filter,
            @PageableDefault Pageable pageable) {
        // ...
    }
}
```

---

## DTO Schema Annotations

```java
@Schema(description = "Request body to create a product")
public record CreateProductRequest(

        @Schema(description = "Product name", example = "Laptop Pro 15")
        @NotBlank String name,

        @Schema(description = "Price in VND", example = "25000000.00")
        @NotNull @DecimalMin("0.0") BigDecimal price,

        @Schema(description = "Parent category UUID")
        @NotNull UUID categoryId
) {}
```
