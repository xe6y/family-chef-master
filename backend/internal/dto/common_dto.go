package dto

// PageRequest 分页请求
type PageRequest struct {
	Page     int `form:"page" binding:"min=1"`      // 页码，最小为1
	PageSize int `form:"page_size" binding:"min=1"` // 每页大小，最小为1
}

// SearchRequest 搜索请求
type SearchRequest struct {
	Keyword  string `form:"keyword"`   // 搜索关键词
	Page     int    `form:"page"`      // 页码
	PageSize int    `form:"page_size"` // 每页大小
}

// Response 通用响应
type Response struct {
	Code    int         `json:"code"`    // 状态码
	Message string      `json:"message"` // 消息
	Data    interface{} `json:"data"`    // 数据
}

// SuccessResponse 成功响应
func SuccessResponse(data interface{}) Response {
	return Response{
		Code:    200,
		Message: "success",
		Data:    data,
	}
}

// ErrorResponse 错误响应
func ErrorResponse(code int, message string) Response {
	return Response{
		Code:    code,
		Message: message,
		Data:    nil,
	}
}

// ListResponse 列表响应
type ListResponse struct {
	List      interface{} `json:"list"`       // 列表数据
	Total     int64       `json:"total"`      // 总数
	Page      int         `json:"page"`       // 当前页
	PageSize  int         `json:"page_size"`  // 每页大小
	TotalPage int64       `json:"total_page"` // 总页数
}

// NewListResponse 创建列表响应
func NewListResponse(list interface{}, total int64, page, pageSize int) ListResponse {
	totalPage := (total + int64(pageSize) - 1) / int64(pageSize)
	return ListResponse{
		List:      list,
		Total:     total,
		Page:      page,
		PageSize:  pageSize,
		TotalPage: totalPage,
	}
}
