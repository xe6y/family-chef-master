package models

// MenuTagRelation 菜谱标签关联表
type MenuTagRelation struct {
	MenuID int64 `gorm:"primaryKey;autoIncrement;not null;unique;column:menu_id"`
	TagID  int64 `gorm:"not null;index;column:tag_id"` // 保留，查询标签关联必需
}

// TableName 指定表名
func (MenuTagRelation) TableName() string {
	return "menu_tag_relation"
}
