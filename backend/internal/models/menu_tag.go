package models

// MenuTag 菜谱标签表
type MenuTag struct {
	ID      int64  `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
	TagName string `gorm:"type:varchar(255);uniqueIndex;column:tag_name"` // 唯一索引，标签名不能重复
}

// TableName 指定表名
func (MenuTag) TableName() string {
	return "menu_tag"
}
