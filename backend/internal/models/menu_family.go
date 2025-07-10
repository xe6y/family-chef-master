package models

import "time"

// MenuFamily 家庭菜谱表
type MenuFamily struct {
	ID           int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
	FamilyID     int64     `gorm:"index;column:family_id"`
	OriginMenuID int64     `gorm:"index;column:origin_menu_id"`
	Name         string    `gorm:"type:varchar(255);column:name"`
	Image        string    `gorm:"type:varchar(255);column:image"`
	Steps        string    `gorm:"type:text;column:steps"`
	CreateBy     int64     `gorm:"column:create_by"`
	CreateTime   time.Time `gorm:"autoCreateTime;column:create_time"`
}

// TableName 指定表名
func (MenuFamily) TableName() string {
	return "menu_family"
}
