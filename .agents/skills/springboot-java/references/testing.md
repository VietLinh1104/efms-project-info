# Testing: Unit, Integration, MockMvc, Testcontainers

## Maven Dependencies

```xml
<!-- Spring Boot Test (includes JUnit 5, Mockito, MockMvc) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>

<!-- Testcontainers for real PostgreSQL in integration tests -->
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>postgresql</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-testcontainers</artifactId>
    <scope>test</scope>
</dependency>
```

---

## Unit Test – Service Layer

```java
@ExtendWith(MockitoExtension.class)
class ProductServiceImplTest {

    @Mock
    private ProductRepository productRepository;

    @Mock
    private ProductMapper productMapper;

    @InjectMocks
    private ProductServiceImpl productService;

    @Test
    void create_shouldReturnResponse_whenNameIsUnique() {
        // Arrange
        var request = new CreateProductRequest("Laptop", BigDecimal.TEN, UUID.randomUUID());
        var entity = Product.builder().name("Laptop").price(BigDecimal.TEN).build();
        entity.setId(UUID.randomUUID());
        var expected = new ProductResponse(entity.getId(), "Laptop", BigDecimal.TEN,
                ProductStatus.ACTIVE, null, Instant.now(), Instant.now());

        given(productRepository.existsByName("Laptop")).willReturn(false);
        given(productMapper.toEntity(request)).willReturn(entity);
        given(productRepository.save(entity)).willReturn(entity);
        given(productMapper.toResponse(entity)).willReturn(expected);

        // Act
        ProductResponse result = productService.create(request);

        // Assert
        assertThat(result.name()).isEqualTo("Laptop");
        then(productRepository).should().save(entity);
    }

    @Test
    void create_shouldThrowDuplicateException_whenNameExists() {
        var request = new CreateProductRequest("Laptop", BigDecimal.TEN, UUID.randomUUID());
        given(productRepository.existsByName("Laptop")).willReturn(true);

        assertThatThrownBy(() -> productService.create(request))
                .isInstanceOf(DuplicateResourceException.class)
                .hasMessageContaining("Laptop");

        then(productRepository).should(never()).save(any());
    }

    @Test
    void findById_shouldThrowNotFound_whenProductMissing() {
        UUID id = UUID.randomUUID();
        given(productRepository.findById(id)).willReturn(Optional.empty());

        assertThatThrownBy(() -> productService.findById(id))
                .isInstanceOf(ResourceNotFoundException.class);
    }
}
```

---

## MockMvc Test – Controller Layer

```java
@WebMvcTest(ProductController.class)
@Import({SecurityConfig.class, JwtAuthFilter.class, JwtService.class})
class ProductControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ProductService productService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @WithMockUser(roles = "USER")
    void create_shouldReturn201_whenRequestValid() throws Exception {
        var request  = new CreateProductRequest("Laptop", new BigDecimal("999.99"), UUID.randomUUID());
        var response = new ProductResponse(UUID.randomUUID(), "Laptop",
                new BigDecimal("999.99"), ProductStatus.ACTIVE, null,
                Instant.now(), Instant.now());

        given(productService.create(any(CreateProductRequest.class)))
                .willReturn(response);

        mockMvc.perform(post("/api/v1/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value(201))
                .andExpect(jsonPath("$.data.name").value("Laptop"));
    }

    @Test
    @WithMockUser
    void create_shouldReturn400_whenNameBlank() throws Exception {
        var invalid = new CreateProductRequest("", BigDecimal.TEN, UUID.randomUUID());

        mockMvc.perform(post("/api/v1/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.name").exists());
    }
}
```

---

## Integration Test with Testcontainers + Real DB

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@ActiveProfiles("test")
class ProductIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres =
            new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private ProductRepository productRepository;

    @BeforeEach
    void setUp() {
        productRepository.deleteAll();
    }

    @Test
    void fullCrudFlow() {
        // Create
        var request = new CreateProductRequest("Keyboard", new BigDecimal("199.99"),
                createCategory().getId());
        var create = restTemplate.postForEntity(
                "/api/v1/products", request, ApiResponse.class);
        assertThat(create.getStatusCode()).isEqualTo(HttpStatus.CREATED);

        // Verify in DB
        assertThat(productRepository.count()).isEqualTo(1);
    }
}
```

---

## application-test.yml

```yaml
spring:
  jpa:
    show-sql: true
    hibernate:
      ddl-auto: create-drop    # Let Hibernate manage schema in tests
  flyway:
    enabled: false             # Testcontainers + ddl-auto handles schema

logging:
  level:
    root: WARN
    com.<company>: DEBUG
```
