package models

import (
	"time"

	"gorm.io/gorm"
)

// User 用户模型
type User struct {
	ID        uint           `json:"id" gorm:"primaryKey"`
	OpenID    string         `json:"open_id" gorm:"uniqueIndex;not null;comment:微信OpenID"`
	UnionID   string         `json:"union_id" gorm:"index;comment:微信UnionID"`
	Nickname  string         `json:"nickname" gorm:"size:50;comment:昵称"`
	Avatar    string         `json:"avatar" gorm:"size:255;comment:头像URL"`
	Gender    int            `json:"gender" gorm:"default:0;comment:性别 0-未知 1-男 2-女"`
	Phone     string         `json:"phone" gorm:"size:20;comment:手机号"`
	Email     string         `json:"email" gorm:"size:100;comment:邮箱"`
	Status    int            `json:"status" gorm:"default:1;comment:状态 0-禁用 1-正常"`
	LastLogin time.Time      `json:"last_login" gorm:"comment:最后登录时间"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联关系
	FamilyMembers []FamilyMember `json:"family_members" gorm:"foreignKey:UserID"`
	ChefSkills    []ChefSkill    `json:"chef_skills" gorm:"foreignKey:UserID"`
	Orders        []Order        `json:"orders" gorm:"foreignKey:UserID"`
	Reviews       []Review       `json:"reviews" gorm:"foreignKey:UserID"`
}

// TableName 指定表名
func (User) TableName() string {
	return "users"
}
