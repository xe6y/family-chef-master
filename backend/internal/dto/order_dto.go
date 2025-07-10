package dto

import "time"

// CreateOrderRequest 创建订单请求
type CreateOrderRequest struct {
	FamilyID int64  `json:"family_id" binding:"required"` // 家庭ID
	MenuType string `json:"menu_type" binding:"required"` // 菜谱类型
}

// OrderResponse 订单响应
type OrderResponse struct {
	ID         int64     `json:"id"`
	FamilyID   int64     `json:"family_id"`
	MenuType   string    `json:"menu_type"`
	CreateTime time.Time `json:"create_time"`
}

// OrderDetailResponse 订单明细响应
type OrderDetailResponse struct {
	ID         int64     `json:"id"`
	OrderID    int64     `json:"order_id"`
	MenuSource string    `json:"menu_source"`
	MenuID     int64     `json:"menu_id"`
	MenuName   string    `json:"menu_name"`
	Image      string    `json:"image"`
	CreateBy   int64     `json:"create_by"`
	CreateTime time.Time `json:"create_time"`
	Status     int8      `json:"status"`
	Sort       int8      `json:"sort"`
	Remark     string    `json:"remark"`
}

// OrderWithDetailsResponse 订单及明细响应
type OrderWithDetailsResponse struct {
	Order   OrderResponse         `json:"order"`
	Details []OrderDetailResponse `json:"details"`
}

// OrderListResponse 订单列表响应
type OrderListResponse struct {
	Orders    []OrderResponse `json:"orders"`
	Total     int64           `json:"total"`
	Page      int             `json:"page"`
	PageSize  int             `json:"page_size"`
	TotalPage int64           `json:"total_page"`
}

// CreateOrderDetailRequest 创建订单明细请求
type CreateOrderDetailRequest struct {
	OrderID    int64  `json:"order_id" binding:"required"`    // 订单ID
	MenuSource string `json:"menu_source" binding:"required"` // 菜谱来源
	MenuID     int64  `json:"menu_id" binding:"required"`     // 菜谱ID
	MenuName   string `json:"menu_name" binding:"required"`   // 菜谱名称
	Image      string `json:"image"`                          // 图片
	CreateBy   int64  `json:"create_by" binding:"required"`   // 创建者ID
	Status     int8   `json:"status"`                         // 状态
	Sort       int8   `json:"sort"`                           // 排序
	Remark     string `json:"remark"`                         // 备注
}
