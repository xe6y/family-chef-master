package models

import "time"

// SysFamily 家庭管理表
type SysFamily struct {
	ID          int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
	Name        string    `gorm:"type:varchar(255);column:name"`
	Description string    `gorm:"type:varchar(500);column:description"`
	Avatar      string    `gorm:"type:varchar(255);column:avatar"`
	InviteCode  string    `gorm:"type:varchar(255);uniqueIndex;column:invite_code"`
	OwnerID     int64     `gorm:"column:owner_id"`
	CreateTime  time.Time `gorm:"autoCreateTime;column:create_time"`
}

// TableName 指定表名
func (SysFamily) TableName() string {
	return "sys_family"
}
