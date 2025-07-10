package models

import "time"

// OrderDetail 点餐明细表
type OrderDetail struct {
	ID         int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
	OrderID    int64     `gorm:"index;column:order_id"` // 保留，查询订单明细必需
	MenuSource string    `gorm:"type:varchar(50);column:menu_source"`
	MenuID     int64     `gorm:"index;column:menu_id"` // 保留，关联菜谱查询
	MenuName   string    `gorm:"type:varchar(255);column:menu_name"`
	Image      string    `gorm:"type:varchar(255);column:image"`
	CreateBy   int64     `gorm:"column:create_by"`
	CreateTime time.Time `gorm:"autoCreateTime;column:create_time"`
	Status     int8      `gorm:"type:tinyint;column:status"`
	Sort       int8      `gorm:"type:tinyint;column:sort"`
	Remark     string    `gorm:"type:text;column:remark"`
}

// TableName 指定表名
func (OrderDetail) TableName() string {
	return "order_detail"
}
