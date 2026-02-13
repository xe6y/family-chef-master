package models

// 单位类型常量
const (
	UnitTypeWeight      = "weight"      // 重量
	UnitTypeVolume      = "volume"      // 体积
	UnitTypeCount       = "count"       // 计数
	UnitTypeUnspecified = "unspecified" // 未指定（如适量）
)

// Unit 单位表模型（全局单位定义）
type Unit struct {
	ID          string `json:"id" gorm:"type:varchar(20);primaryKey"`           // 主键，如 g, kg, pcs, ml, tbsp, suitable
	DisplayName string `json:"displayName" gorm:"type:varchar(20);not null"`   // 显示名称，如 克、千克、只、毫升、勺、适量
	UnitType    string `json:"unitType" gorm:"type:varchar(20);default:unspecified"` // weight, volume, count, unspecified
	SortOrder   int    `json:"sortOrder" gorm:"default:0;index"`               // 排序
}

// TableName 指定表名
func (Unit) TableName() string {
	return "units"
}
