# Boilerplate Code Patterns

## Base Entity (all entities extend this)

```java
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter
public abstract class BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @CreatedDate
    @Column(updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;

    @CreatedBy
    @Column(updatable = false)
    private String createdBy;

    @LastModifiedBy
    private String updatedBy;
}
```

Enable auditing in main class or config:
```java
@EnableJpaAuditing(auditorAwareRef = "auditorProvider")
```

---

## Entity Example

```java
@Entity
@Table(name = "products")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Product extends BaseEntity {

    @Column(nullable = false, length = 255)
    private String name;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal price;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ProductStatus status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;
}
```

---

## Repository

```java
public interface ProductRepository extends JpaRepository<Product, UUID>,
        JpaSpecificationExecutor<Product> {

    boolean existsByName(String name);

    @Query("SELECT p FROM Product p WHERE p.status = :status AND p.category.id = :categoryId")
    Page<Product> findByStatusAndCategory(
            @Param("status") ProductStatus status,
            @Param("categoryId") UUID categoryId,
            Pageable pageable);
}
```

---

## Service Interface

```java
public interface ProductService {
    ProductResponse create(CreateProductRequest request);
    ProductResponse update(UUID id, UpdateProductRequest request);
    void delete(UUID id);
    ProductResponse findById(UUID id);
    PagedResponse<ProductResponse> findAll(ProductFilterRequest filter, Pageable pageable);
}
```

---

## Service Implementation

```java
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class ProductServiceImpl implements ProductService {

    private final ProductRepository productRepository;
    private final ProductMapper productMapper;

    @Override
    @Transactional
    public ProductResponse create(CreateProductRequest request) {
        log.info("Creating product: name={}", request.name());

        if (productRepository.existsByName(request.name())) {
            throw new DuplicateResourceException("Product", "name", request.name());
        }

        Product product = productMapper.toEntity(request);
        Product saved = productRepository.save(product);

        log.info("Product created: id={}", saved.getId());
        return productMapper.toResponse(saved);
    }

    @Override
    @Transactional
    public ProductResponse update(UUID id, UpdateProductRequest request) {
        log.info("Updating product: id={}", id);
        Product product = findProductOrThrow(id);
        productMapper.updateEntityFromRequest(request, product);
        return productMapper.toResponse(productRepository.save(product));
    }

    @Override
    @Transactional
    public void delete(UUID id) {
        log.info("Deleting product: id={}", id);
        Product product = findProductOrThrow(id);
        productRepository.delete(product);
        log.info("Product deleted: id={}", id);
    }

    @Override
    public ProductResponse findById(UUID id) {
        return productMapper.toResponse(findProductOrThrow(id));
    }

    @Override
    public PagedResponse<ProductResponse> findAll(ProductFilterRequest filter, Pageable pageable) {
        Page<Product> page = productRepository.findAll(
                ProductSpecification.build(filter), pageable);
        return PagedResponse.of(page.map(productMapper::toResponse));
    }

    private Product findProductOrThrow(UUID id) {
        return productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Product", id));
    }
}
```

---

## Controller

```java
@RestController
@RequestMapping("/api/v1/products")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Products", description = "Product management APIs")
public class ProductController {

    private final ProductService productService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a new product")
    public ApiResponse<ProductResponse> create(
            @Valid @RequestBody CreateProductRequest request) {
        return ApiResponse.created(productService.create(request));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an existing product")
    public ApiResponse<ProductResponse> update(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateProductRequest request) {
        return ApiResponse.ok(productService.update(id, request));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a product")
    public void delete(@PathVariable UUID id) {
        productService.delete(id);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get product by ID")
    public ApiResponse<ProductResponse> getById(@PathVariable UUID id) {
        return ApiResponse.ok(productService.findById(id));
    }

    @GetMapping
    @Operation(summary = "List products with filters and pagination")
    public ApiResponse<PagedResponse<ProductResponse>> list(
            @ModelAttribute ProductFilterRequest filter,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC)
            Pageable pageable) {
        return ApiResponse.ok(productService.findAll(filter, pageable));
    }
}
```

---

## MapStruct Mapper

```java
@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface ProductMapper {

    Product toEntity(CreateProductRequest request);

    ProductResponse toResponse(Product product);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    void updateEntityFromRequest(UpdateProductRequest request, @MappingTarget Product product);
}
```

---

## JPA Specification (for dynamic filtering)

```java
public class ProductSpecification {

    public static Specification<Product> build(ProductFilterRequest filter) {
        return Specification
            .where(hasStatus(filter.status()))
            .and(hasCategoryId(filter.categoryId()))
            .and(nameContains(filter.search()));
    }

    private static Specification<Product> hasStatus(ProductStatus status) {
        return (root, query, cb) -> status == null ? null
                : cb.equal(root.get("status"), status);
    }

    private static Specification<Product> hasCategoryId(UUID categoryId) {
        return (root, query, cb) -> categoryId == null ? null
                : cb.equal(root.get("category").get("id"), categoryId);
    }

    private static Specification<Product> nameContains(String search) {
        return (root, query, cb) -> !StringUtils.hasText(search) ? null
                : cb.like(cb.lower(root.get("name")), "%" + search.toLowerCase() + "%");
    }
}
```
