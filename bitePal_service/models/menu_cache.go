package models

import (
	"time"
)

// MenuCache 菜单缓存模型
// 用于多人协同编辑菜单
type MenuCache struct {
	ID         string          `json:"id" gorm:"primaryKey;type:varchar(50)"`
	FamilyID   string          `json:"familyId" gorm:"type:varchar(50);not null;index:idx_menu_cache_family_date"`
	Date       time.Time       `json:"date" gorm:"type:date;not null;index:idx_menu_cache_family_date"`
	RecipeID   string          `json:"recipeId" gorm:"type:varchar(50);not null;index:idx_menu_cache_recipe"`
	RecipeName string          `json:"recipeName" gorm:"type:varchar(200);not null"`
	Source     string          `json:"source" gorm:"type:varchar(20);not null"` // my/online
	SelectedBy []FamilyMember  `json:"selectedBy" gorm:"type:jsonb;default:'[]'"`
	IsChecked  bool            `json:"isChecked" gorm:"default:true"`
	AddedAt    time.Time       `json:"addedAt" gorm:"autoCreateTime"`
	UpdatedAt  time.Time       `json:"updatedAt" gorm:"autoUpdateTime;index:idx_menu_cache_updated"`
}

// TableName 指定表名
func (MenuCache) TableName() string {
	return "menu_cache"
}
