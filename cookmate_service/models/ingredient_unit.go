package models

// IngredientUnit 食材-单位关联模型（常用单位与换算）
type IngredientUnit struct {
	IngredientID  string  `json:"ingredientId" gorm:"type:varchar(36);primaryKey;uniqueIndex:idx_ingredient_unit"`  // 食材库 ID
	UnitID        string  `json:"unitId" gorm:"type:varchar(20);primaryKey;uniqueIndex:idx_ingredient_unit"`      // 单位 ID
	FactorToBase  float64 `json:"factorToBase" gorm:"type:decimal(12,4);not null"`                                 // 1 单位 = 多少基准单位
	SortOrder     int     `json:"sortOrder" gorm:"default:0;index"`                                                 // 该食材下单位的展示顺序
}

// TableName 指定表名
func (IngredientUnit) TableName() string {
	return "ingredient_unit"
}
