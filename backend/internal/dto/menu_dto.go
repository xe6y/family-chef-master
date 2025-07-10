package dto

import "time"

// MenuResponse 菜谱响应
type MenuResponse struct {
	ID         int64     `json:"id"`
	Name       string    `json:"name"`
	Image      string    `json:"image"`
	Tags       string    `json:"tags"`
	Steps      string    `json:"steps"`
	CreateTime time.Time `json:"create_time"`
}

// FamilyMenuResponse 家庭菜谱响应
type FamilyMenuResponse struct {
	ID           int64     `json:"id"`
	FamilyID     int64     `json:"family_id"`
	OriginMenuID int64     `json:"origin_menu_id"`
	Name         string    `json:"name"`
	Image        string    `json:"image"`
	Steps        string    `json:"steps"`
	CreateBy     int64     `json:"create_by"`
	CreateTime   time.Time `json:"create_time"`
}

// MenuListResponse 菜谱列表响应
type MenuListResponse struct {
	Menus     []MenuResponse `json:"menus"`
	Total     int64          `json:"total"`
	Page      int            `json:"page"`
	PageSize  int            `json:"page_size"`
	TotalPage int64          `json:"total_page"`
}

// FamilyMenuListResponse 家庭菜谱列表响应
type FamilyMenuListResponse struct {
	Menus     []FamilyMenuResponse `json:"menus"`
	Total     int64                `json:"total"`
	Page      int                  `json:"page"`
	PageSize  int                  `json:"page_size"`
	TotalPage int64                `json:"total_page"`
}

// CreateFamilyMenuRequest 创建家庭菜谱请求
type CreateFamilyMenuRequest struct {
	FamilyID     int64  `json:"family_id" binding:"required"` // 家庭ID
	OriginMenuID int64  `json:"origin_menu_id"`               // 原菜谱ID（可选）
	Name         string `json:"name" binding:"required"`      // 菜谱名称
	Image        string `json:"image"`                        // 图片
	Steps        string `json:"steps" binding:"required"`     // 制作步骤
	CreateBy     int64  `json:"create_by" binding:"required"` // 创建者ID
}
