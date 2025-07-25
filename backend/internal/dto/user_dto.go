package dto

import "time"

// CreateUserRequest 创建用户请求
type CreateUserRequest struct {
	OpenID   string `json:"openid" binding:"required"`   // 微信OpenID
	Nickname string `json:"nickname" binding:"required"` // 昵称
	Avatar   string `json:"avatar"`                      // 头像
	Phone    string `json:"phone"`                       // 手机号
}

// UpdateUserRequest 更新用户请求
type UpdateUserRequest struct {
	Nickname   string `json:"nickname"`    // 昵称
	Avatar     string `json:"avatar"`      // 头像
	Phone      string `json:"phone"`       // 手机号
	Role       string `json:"role"`        // 用户角色
	FamilyID   int64  `json:"family_id"`   // 家庭ID
	FamilyRole string `json:"family_role"` // 家庭角色
}

// UserResponse 用户响应
type UserResponse struct {
	ID         int64     `json:"id"`
	OpenID     string    `json:"openid"`
	Nickname   string    `json:"nickname"`
	Avatar     string    `json:"avatar"`
	Phone      string    `json:"phone"`
	Role       string    `json:"role"`
	FamilyID   int64     `json:"family_id"`
	FamilyRole string    `json:"family_role"`
	CreateTime time.Time `json:"create_time"`
}

// UserListResponse 用户列表响应
type UserListResponse struct {
	Users     []UserResponse `json:"users"`
	Total     int64          `json:"total"`
	Page      int            `json:"page"`
	PageSize  int            `json:"page_size"`
	TotalPage int64          `json:"total_page"`
}

// UserStatsResponse 用户统计响应
type UserStatsResponse struct {
	TotalUsers  int64 `json:"total_users"`
	TodayUsers  int64 `json:"today_users"`
	FamilyUsers int64 `json:"family_users"`
	LonelyUsers int64 `json:"lonely_users"`
}

// RegisterRequest 用户注册请求
type RegisterRequest struct {
	OpenID     string `json:"openid" binding:"required"`   // 微信OpenID
	Nickname   string `json:"nickname" binding:"required"` // 昵称
	Avatar     string `json:"avatar"`                      // 头像
	Phone      string `json:"phone"`                       // 手机号
	InviteCode string `json:"invite_code"`                 // 家庭邀请码（可选）
}

// RegisterResponse 用户注册响应
type RegisterResponse struct {
	User        UserResponse   `json:"user"`
	Family      FamilyResponse `json:"family"`
	IsNewFamily bool           `json:"is_new_family"`
}
