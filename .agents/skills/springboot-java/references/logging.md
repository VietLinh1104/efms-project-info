# Structured Trace Logging (MDC + Interceptors)

## MDC Trace Filter (runs before every request)

```java
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class MdcTraceFilter extends OncePerRequestFilter {

    private static final String TRACE_ID_HEADER = "X-Trace-Id";

    @Override
    protected void doFilterInternal(HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {

        String traceId = Optional
                .ofNullable(request.getHeader(TRACE_ID_HEADER))
                .filter(StringUtils::hasText)
                .orElse(UUID.randomUUID().toString());

        MDC.put("traceId", traceId);
        response.setHeader(TRACE_ID_HEADER, traceId);

        try {
            filterChain.doFilter(request, response);
        } finally {
            MDC.clear();   // MUST clear to avoid ThreadLocal leaks in thread pools
        }
    }
}
```

---

## Request/Response Logging Interceptor

```java
@Component
@Slf4j
public class RequestLoggingInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
            Object handler) {
        long start = System.currentTimeMillis();
        request.setAttribute("startTime", start);

        log.info("→ {} {} [user={}]",
                request.getMethod(),
                request.getRequestURI(),
                Optional.ofNullable(request.getHeader("X-User-Email")).orElse("anonymous"));
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
            Object handler, Exception ex) {
        long duration = System.currentTimeMillis()
                - (long) request.getAttribute("startTime");

        if (ex != null) {
            log.error("← {} {} {} {}ms [error={}]",
                    request.getMethod(), request.getRequestURI(),
                    response.getStatus(), duration, ex.getMessage());
        } else {
            log.info("← {} {} {} {}ms",
                    request.getMethod(), request.getRequestURI(),
                    response.getStatus(), duration);
        }
    }
}
```

Register in `WebMvcConfig`:
```java
@Configuration
@RequiredArgsConstructor
public class WebMvcConfig implements WebMvcConfigurer {

    private final RequestLoggingInterceptor requestLoggingInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(requestLoggingInterceptor)
                .addPathPatterns("/api/**");
    }
}
```

---

## Logback Configuration (logback-spring.xml)

```xml
<configuration>
    <springProfile name="dev">
        <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
            <encoder>
                <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level [%X{traceId}] %logger{36} - %msg%n</pattern>
            </encoder>
        </appender>
        <root level="DEBUG">
            <appender-ref ref="CONSOLE"/>
        </root>
    </springProfile>

    <springProfile name="prod">
        <appender name="JSON_CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
            <encoder class="net.logstash.logback.encoder.LogstashEncoder">
                <includeMdcKeyName>traceId</includeMdcKeyName>
            </encoder>
        </appender>
        <root level="INFO">
            <appender-ref ref="JSON_CONSOLE"/>
        </root>
    </springProfile>
</configuration>
```

---

## Logging Best Practices

```java
// ✅ Good – structured params, lazy evaluation
log.info("Order processed: orderId={}, total={}, userId={}", orderId, total, userId);
log.debug("Cache miss: key={}", key);
log.error("Payment failed: orderId={}", orderId, ex);

// ❌ Bad – string concatenation (eager, slow)
log.info("Order processed: " + orderId + " total: " + total);

// ✅ Entering/exiting important service methods
log.info("Processing payment: orderId={}, amount={}", orderId, amount);
// ... business logic ...
log.info("Payment completed: orderId={}, transactionId={}", orderId, txId);
```
