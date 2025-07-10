package models

import "time"

// MenuPublic 公共菜谱表
type MenuPublic struct {
	ID         int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
	Name       string    `gorm:"type:varchar(255);column:name"`
	Image      string    `gorm:"type:varchar(255);column:image"`
	Tags       string    `gorm:"type:text;column:tags"`
	Steps      string    `gorm:"type:text;column:steps"`
	CreateTime time.Time `gorm:"autoCreateTime;column:create_time"`
}

// TableName 指定表名
func (MenuPublic) TableName() string {
	return "menu_public"
}
