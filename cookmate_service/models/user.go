package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// User 用户模型
type User struct {
	ID        string         `json:"id" gorm:"type:varchar(36);primaryKey"`                     // 用户ID (UUID)
	Username  string         `json:"username" gorm:"type:varchar(50);uniqueIndex;not null"`     // 用户名
	Password  string         `json:"-" gorm:"type:varchar(255);not null"`                       // 密码（JSON不返回）
	Nickname  string         `json:"nickname" gorm:"type:varchar(50)"`                          // 昵称
	Avatar    string         `json:"avatar" gorm:"type:varchar(500)"`                           // 头像URL
	UserID    string         `json:"userId" gorm:"type:varchar(50);uniqueIndex"`                // 用户唯一标识（展示用）
	Phone     string         `json:"phone" gorm:"type:varchar(20);uniqueIndex"`                 // 手机号（唯一）
	FamilyID  string         `json:"familyId" gorm:"type:varchar(36);index"`                        // 所属家庭ID
	CreatedAt time.Time      `json:"createdAt"`                                                 // 创建时间
	UpdatedAt time.Time      `json:"updatedAt"`                                                 // 更新时间
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`                                            // 软删除时间
}

// BeforeCreate 创建前钩子，自动生成ID
func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.ID == "" {
		u.ID = uuid.New().String()
	}
	if u.UserID == "" {
		// 生成用户唯一标识，格式：COOK_年份_序号
		u.UserID = "COOK_" + time.Now().Format("2006") + "_" + uuid.New().String()[:8]
	}
	return nil
}

// UserResponse 用户响应结构（不包含敏感信息）
type UserResponse struct {
	ID       string `json:"id"`       // 用户ID
	Username string `json:"username"` // 用户名
	Nickname string `json:"nickname"` // 昵称
	Avatar   string `json:"avatar"`   // 头像URL
	UserID   string `json:"userId"`   // 用户唯一标识
	FamilyID string `json:"familyId"` // 所属家庭ID
}

// ToResponse 转换为响应结构
// 返回: 用户响应结构
func (u *User) ToResponse() *UserResponse {
	return &UserResponse{
		ID:       u.ID,
		Username: u.Username,
		Nickname: u.Nickname,
		Avatar:   u.Avatar,
		UserID:   u.UserID,
		FamilyID: u.FamilyID,
	}
}

