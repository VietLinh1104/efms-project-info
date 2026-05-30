# Global Exception Handling

## Error Response DTO

```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ErrorResponse(
        int status,
        String code,
        String message,
        Map<String, String> fieldErrors,
        Instant timestamp
) {
    public static ErrorResponse of(int status, String code, String message) {
        return new ErrorResponse(status, code, message, null, Instant.now());
    }

    public static ErrorResponse withFieldErrors(int status, String code,
            String message, Map<String, String> fieldErrors) {
        return new ErrorResponse(status, code, message, fieldErrors, Instant.now());
    }
}
```

---

## Error Code Enum

```java
public enum ErrorCode {
    // Generic
    INTERNAL_SERVER_ERROR("ERR_500", "An unexpected error occurred"),
    VALIDATION_FAILED("ERR_400", "Validation failed"),
    UNAUTHORIZED("ERR_401", "Authentication required"),
    FORBIDDEN("ERR_403", "Access denied"),

    // Resource
    RESOURCE_NOT_FOUND("ERR_404", "Resource not found"),
    DUPLICATE_RESOURCE("ERR_409", "Resource already exists"),

    // Business
    INVALID_STATE("BIZ_001", "Invalid state transition"),
    INSUFFICIENT_BALANCE("BIZ_002", "Insufficient balance");

    public final String code;
    public final String defaultMessage;

    ErrorCode(String code, String defaultMessage) {
        this.code = code;
        this.defaultMessage = defaultMessage;
    }
}
```

---

## Custom Exception Classes

```java
// Base
public abstract class AppException extends RuntimeException {
    public final ErrorCode errorCode;
    public final int httpStatus;

    protected AppException(ErrorCode errorCode, int httpStatus, String message) {
        super(message);
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
    }
}

// 404
public class ResourceNotFoundException extends AppException {
    public ResourceNotFoundException(String resource, Object id) {
        super(ErrorCode.RESOURCE_NOT_FOUND, 404,
              "%s not found with id: %s".formatted(resource, id));
    }

    public ResourceNotFoundException(String resource, String field, Object value) {
        super(ErrorCode.RESOURCE_NOT_FOUND, 404,
              "%s not found with %s: %s".formatted(resource, field, value));
    }
}

// 409
public class DuplicateResourceException extends AppException {
    public DuplicateResourceException(String resource, String field, Object value) {
        super(ErrorCode.DUPLICATE_RESOURCE, 409,
              "%s already exists with %s: %s".formatted(resource, field, value));
    }
}

// 400 Business
public class BusinessException extends AppException {
    public BusinessException(ErrorCode errorCode, String message) {
        super(errorCode, 400, message);
    }
}
```

---

## Global Exception Handler

```java
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    // Handles our custom exceptions
    @ExceptionHandler(AppException.class)
    public ResponseEntity<ErrorResponse> handleAppException(AppException ex,
            HttpServletRequest request) {
        log.warn("AppException [{}] on {}: {}", ex.errorCode.code,
                 request.getRequestURI(), ex.getMessage());
        return ResponseEntity.status(ex.httpStatus)
                .body(ErrorResponse.of(ex.httpStatus, ex.errorCode.code, ex.getMessage()));
    }

    // Handles @Valid validation failures
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(
            MethodArgumentNotValidException ex) {
        Map<String, String> fieldErrors = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .collect(Collectors.toMap(
                        FieldError::getField,
                        fe -> Objects.requireNonNullElse(fe.getDefaultMessage(), "Invalid"),
                        (a, b) -> a));

        log.warn("Validation failed: {}", fieldErrors);
        return ResponseEntity.badRequest()
                .body(ErrorResponse.withFieldErrors(400,
                        ErrorCode.VALIDATION_FAILED.code,
                        "Validation failed", fieldErrors));
    }

    // Handles @RequestParam / @PathVariable constraint violations
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> handleConstraintViolation(
            ConstraintViolationException ex) {
        Map<String, String> fieldErrors = ex.getConstraintViolations()
                .stream()
                .collect(Collectors.toMap(
                        cv -> cv.getPropertyPath().toString(),
                        cv -> cv.getMessage(),
                        (a, b) -> a));

        return ResponseEntity.badRequest()
                .body(ErrorResponse.withFieldErrors(400,
                        ErrorCode.VALIDATION_FAILED.code,
                        "Constraint violation", fieldErrors));
    }

    // Handles Spring Security access denied
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleAccessDenied(AccessDeniedException ex) {
        return ResponseEntity.status(403)
                .body(ErrorResponse.of(403, ErrorCode.FORBIDDEN.code, ex.getMessage()));
    }

    // Catch-all
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneral(Exception ex,
            HttpServletRequest request) {
        log.error("Unhandled exception on {}: {}", request.getRequestURI(), ex.getMessage(), ex);
        return ResponseEntity.internalServerError()
                .body(ErrorResponse.of(500,
                        ErrorCode.INTERNAL_SERVER_ERROR.code,
                        "An unexpected error occurred"));
    }
}
```
