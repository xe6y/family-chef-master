package dto

import "time"

// CreateFamilyRequest 创建家庭请求
type CreateFamilyRequest struct {
	Name        string `json:"name" binding:"required"`     // 家庭名称
	Description string `json:"description"`                 // 家庭描述
	OwnerID     int64  `json:"owner_id" binding:"required"` // 创建者ID
}

// JoinFamilyRequest 加入家庭请求
type JoinFamilyRequest struct {
	InviteCode string `json:"invite_code" binding:"required"` // 邀请码
	UserID     int64  `json:"user_id" binding:"required"`     // 用户ID
}

// FamilyResponse 家庭响应
type FamilyResponse struct {
	ID          int64     `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Avatar      string    `json:"avatar"`
	OwnerID     int64     `json:"owner_id"`
	InviteCode  string    `json:"invite_code"`
	CreateTime  time.Time `json:"create_time"`
}

// FamilyMemberResponse 家庭成员响应
type FamilyMemberResponse struct {
	ID         int64     `json:"id"`
	OpenID     string    `json:"openid"`
	Nickname   string    `json:"nickname"`
	Avatar     string    `json:"avatar"`
	Phone      string    `json:"phone"`
	FamilyRole string    `json:"family_role"`
	CreateTime time.Time `json:"create_time"`
}

// FamilyWithMembersResponse 家庭及成员响应
type FamilyWithMembersResponse struct {
	Family  FamilyResponse         `json:"family"`
	Members []FamilyMemberResponse `json:"members"`
}

// FamilyListResponse 家庭列表响应
type FamilyListResponse struct {
	Families  []FamilyResponse `json:"families"`
	Total     int64            `json:"total"`
	Page      int              `json:"page"`
	PageSize  int              `json:"page_size"`
	TotalPage int64            `json:"total_page"`
}

// FamilyStatsResponse 家庭统计响应
type FamilyStatsResponse struct {
	MemberCount     int64 `json:"member_count"`
	RecipeCount     int64 `json:"recipe_count"`
	OrderCount      int64 `json:"order_count"`
	MonthOrderCount int64 `json:"month_order_count"`
}
