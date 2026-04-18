package com.linhdv.efms_common_service.wrapper;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Data;

import java.util.List;

/**
 * Wrapper cho response danh sách có phân trang.
 * Dùng kết hợp với ApiResponse:
 * 
 * <pre>
 * ApiResponse.success(PagedResponse.of(content, page, size, total))
 * </pre>
 *
 * @param <T> kiểu dữ liệu từng phần tử
 */
@Data
@Builder
@Schema(description = "Wrapper cho danh sách có phân trang")
public class PagedResponse<T> {

    @Schema(description = "Danh sách phần tử")
    private List<T> content;

    @Schema(description = "Trang hiện tại (0-indexed)", example = "0")
    private int page;

    @Schema(description = "Số phần tử mỗi trang", example = "20")
    private int size;

    @Schema(description = "Tổng số phần tử", example = "100")
    private long totalElements;

    @Schema(description = "Tổng số trang", example = "5")
    private int totalPages;

    @Schema(description = "Có trang trước không", example = "false")
    private boolean hasPrevious;

    @Schema(description = "Có trang sau không", example = "true")
    private boolean hasNext;

    public static <T> PagedResponse<T> of(List<T> content, int page, int size, long totalElements) {
        int totalPages = (int) Math.ceil((double) totalElements / size);
        return PagedResponse.<T>builder()
                .content(content)
                .page(page)
                .size(size)
                .totalElements(totalElements)
                .totalPages(totalPages)
                .hasPrevious(page > 0)
                .hasNext(page < totalPages - 1)
                .build();
    }
}
