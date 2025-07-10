package models

import "time"

// SystemFamily 家庭管理表
type SystemFamily struct {
	ID         int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
	Name       string    `gorm:"type:varchar(255);column:name"`
	InviteCode string    `gorm:"type:varchar(255);uniqueIndex;column:invite_code"` // 唯一索引，邀请码唯一性必需
	OwnerID    int64     `gorm:"column:owner_id"`
	CreateTime time.Time `gorm:"autoCreateTime;column:create_time"`
}

// TableName 指定表名
func (SystemFamily) TableName() string {
	return "system_family"
}
