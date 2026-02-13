package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// UserTag 用户常用标签模型
type UserTag struct {
	ID        string         `json:"id" gorm:"type:varchar(36);primaryKey"`                             // 标签ID
	UserID    string         `json:"userId" gorm:"type:varchar(36);not null;index"`                     // 用户ID
	Name      string         `json:"name" gorm:"type:varchar(20);not null"`                             // 标签名称
	Color     string         `json:"color" gorm:"type:varchar(20);not null"`                            // 标签颜色（CSS颜色值或类名）
	UseCount  int            `json:"useCount" gorm:"default:0"`                                         // 使用次数
	CreatedAt time.Time      `json:"createdAt"`                                                         // 创建时间
	UpdatedAt time.Time      `json:"updatedAt"`                                                         // 更新时间
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`                                                    // 软删除时间
}

// BeforeCreate 创建前钩子，自动生成ID
func (ut *UserTag) BeforeCreate(tx *gorm.DB) error {
	if ut.ID == "" {
		ut.ID = uuid.New().String()
	}
	return nil
}

// UserTagResponse 用户标签响应结构
type UserTagResponse struct {
	ID       string `json:"id"`       // 标签ID
	Name     string `json:"name"`     // 标签名称
	Color    string `json:"color"`    // 标签颜色
	UseCount int    `json:"useCount"` // 使用次数
}

// ToResponse 转换为响应结构
func (ut *UserTag) ToResponse() *UserTagResponse {
	return &UserTagResponse{
		ID:       ut.ID,
		Name:     ut.Name,
		Color:    ut.Color,
		UseCount: ut.UseCount,
	}
}
