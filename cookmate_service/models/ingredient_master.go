package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// IngredientMaster 食材库模型（主数据）
type IngredientMaster struct {
	ID             string  `json:"id" gorm:"type:varchar(36);primaryKey"`                    // 主键
	Name           string  `json:"name" gorm:"type:varchar(100);not null;index"`              // 食材名称
	CategoryID     string  `json:"categoryId" gorm:"type:varchar(36);index"`                 // 关联食材分类（肉类/蔬菜等），可选
	BaseUnitID     string  `json:"baseUnitId" gorm:"type:varchar(20);not null;default:g"`     // 营养数据基准单位，一般为 g
	CaloriesPer100 float64 `json:"caloriesPer100" gorm:"type:decimal(8,2);default:0"`         // 每100克/100ml 热量（千卡）
	ProteinPer100  float64 `json:"proteinPer100" gorm:"type:decimal(8,2);default:0"`           // 每100克 蛋白质（克）
	FatPer100      float64 `json:"fatPer100" gorm:"type:decimal(8,2);default:0"`             // 每100克 脂肪（克）
	CarbPer100     float64 `json:"carbPer100" gorm:"type:decimal(8,2);default:0"`             // 每100克 碳水化合物（克）
	SortOrder      int     `json:"sortOrder" gorm:"default:0;index"`                           // 排序/搜索权重
}

// TableName 指定表名
func (IngredientMaster) TableName() string {
	return "ingredient_master"
}

// BeforeCreate 创建前钩子
func (m *IngredientMaster) BeforeCreate(tx *gorm.DB) error {
	if m.ID == "" {
		m.ID = uuid.New().String()
	}
	return nil
}
