package models

import "time"

// MenuTutorial 菜谱教程表
type MenuTutorial struct {
	ID         int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
	MenuID     int64     `gorm:"index;column:menu_id"`
	URL        string    `gorm:"type:varchar(255);column:url"`
	CreateTime time.Time `gorm:"autoCreateTime;column:create_time"`
}

// TableName 指定表名
func (MenuTutorial) TableName() string {
	return "menu_tutorial"
}
