package dto

import "time"

// CreateFamilyRequest 创建家庭请求
type CreateFamilyRequest struct {
	Name       string `json:"name" binding:"required"`        // 家庭名称
	InviteCode string `json:"invite_code" binding:"required"` // 邀请码
	OwnerID    int64  `json:"owner_id"`                       // 创建者ID
}

// UpdateFamilyRequest 更新家庭请求
type UpdateFamilyRequest struct {
	Name       string `json:"name"`        // 家庭名称
	InviteCode string `json:"invite_code"` // 邀请码
}

// FamilyResponse 家庭响应
type FamilyResponse struct {
	ID         int64     `json:"id"`
	Name       string    `json:"name"`
	InviteCode string    `json:"invite_code"`
	OwnerID    int64     `json:"owner_id"`
	CreateTime time.Time `json:"create_time"`
}

// FamilyWithMembersResponse 家庭及成员响应
type FamilyWithMembersResponse struct {
	Family  FamilyResponse `json:"family"`
	Members []UserResponse `json:"members"`
}

// FamilyStatsResponse 家庭统计响应
type FamilyStatsResponse struct {
	MemberCount     int64 `json:"member_count"`
	RecipeCount     int64 `json:"recipe_count"`
	OrderCount      int64 `json:"order_count"`
	MonthOrderCount int64 `json:"month_order_count"`
}

// JoinFamilyRequest 加入家庭请求
type JoinFamilyRequest struct {
	InviteCode string `json:"invite_code" binding:"required"` // 邀请码
	Role       string `json:"role"`                           // 角色
}
