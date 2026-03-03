package models

import (
	"database/sql/driver"
	"encoding/json"
	"time"
)

// SimpleMember 简化的成员信息（用于菜单缓存）
type SimpleMember struct {
	ID   string `json:"id"`   // 成员ID
	Name string `json:"name"` // 成员名称
}

// SimpleMemberList 成员列表类型
type SimpleMemberList []SimpleMember

// Scan 从数据库读取值
func (s *SimpleMemberList) Scan(value interface{}) error {
	if value == nil {
		*s = SimpleMemberList{}
		return nil
	}
	return json.Unmarshal(value.([]byte), s)
}

// Value 写入数据库的值
func (s SimpleMemberList) Value() (driver.Value, error) {
	return json.Marshal(s)
}

// MenuCache 菜单缓存模型
// 用于多人协同编辑菜单
type MenuCache struct {
	ID         string           `json:"id" gorm:"primaryKey;type:varchar(100)"`
	FamilyID   string           `json:"familyId" gorm:"type:varchar(50);not null;index:idx_menu_cache_family_date"`
	Date       time.Time        `json:"date" gorm:"type:date;not null;index:idx_menu_cache_family_date"`
	RecipeID   string           `json:"recipeId" gorm:"type:varchar(50);not null;index:idx_menu_cache_recipe"`
	RecipeName string           `json:"recipeName" gorm:"type:varchar(200);not null"`
	Source     string           `json:"source" gorm:"type:varchar(20);not null"` // my/online
	SelectedBy SimpleMemberList `json:"selectedBy" gorm:"type:jsonb;default:'[]'"`
	IsChecked  bool             `json:"isChecked" gorm:"default:true"`
	AddedAt    time.Time        `json:"addedAt" gorm:"autoCreateTime"`
	UpdatedAt  time.Time        `json:"updatedAt" gorm:"autoUpdateTime;index:idx_menu_cache_updated"`
}

// TableName 指定表名
func (MenuCache) TableName() string {
	return "menu_cache"
}
