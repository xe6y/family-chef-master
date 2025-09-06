package models

import "time"

// Order 点餐表
type Order struct {
	ID         int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
	FamilyID   int64     `gorm:"index;column:family_id"`
	MenuType   string    `gorm:"type:varchar(50);column:menu_type"`
	CreateTime time.Time `gorm:"autoCreateTime;column:create_time"`
}

// TableName 指定表名
func (Order) TableName() string {
	return "order"
}
