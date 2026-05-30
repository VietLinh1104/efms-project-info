# Request / Response DTOs & Pagination

## Universal API Response Wrapper

```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiResponse<T>(
        int status,
        String message,
        T data,
        Instant timestamp
) {
    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(200, "Success", data, Instant.now());
    }

    public static <T> ApiResponse<T> created(T data) {
        return new ApiResponse<>(201, "Created", data, Instant.now());
    }

    public static <T> ApiResponse<T> noData(int status, String message) {
        return new ApiResponse<>(status, message, null, Instant.now());
    }
}
```

---

## Paginated Response Wrapper

```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public record PagedResponse<T>(
        List<T> data,
        int page,
        int size,
        long totalElements,
        int totalPages,
        boolean last
) {
    public static <T> PagedResponse<T> of(Page<T> page) {
        return new PagedResponse<>(
                page.getContent(),
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages(),
                page.isLast()
        );
    }
}
```

Usage in controller:
```java
return ApiResponse.ok(productService.findAll(filter, pageable));
// Produces: { status, message, data: { data: [...], page, size, totalElements, ... } }
```

---

## Request DTOs (Java Records + Validation)

```java
// Create
public record CreateProductRequest(
        @NotBlank(message = "Name is required")
        @Size(max = 255)
        String name,

        @NotNull(message = "Price is required")
        @DecimalMin(value = "0.0", inclusive = false, message = "Price must be positive")
        BigDecimal price,

        @NotNull(message = "Category ID is required")
        UUID categoryId
) {}

// Update (all fields optional for partial update)
public record UpdateProductRequest(
        @Size(max = 255)
        String name,

        @DecimalMin(value = "0.0", inclusive = false)
        BigDecimal price
) {}

// Filter / Query
public record ProductFilterRequest(
        String search,
        ProductStatus status,
        UUID categoryId
) {}
```

---

## Response DTOs

```java
public record ProductResponse(
        UUID id,
        String name,
        BigDecimal price,
        ProductStatus status,
        String categoryName,
        Instant createdAt,
        Instant updatedAt
) {}
```

---

## Pageable Config (enable sort by multiple fields via URL)

`GET /api/v1/products?page=0&size=10&sort=name,asc&sort=createdAt,desc`

```java
// In WebMvcConfig or just rely on Spring default
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Override
    public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
        // Spring auto-registers PageableHandlerMethodArgumentResolver
        // Optionally set max page size:
        PageableHandlerMethodArgumentResolver resolver =
                new PageableHandlerMethodArgumentResolver();
        resolver.setMaxPageSize(100);
        resolvers.add(resolver);
    }
}
```
