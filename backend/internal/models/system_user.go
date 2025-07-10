package models

import "time"

// SystemUser 系统用户表
type SystemUser struct {
	ID         int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
	OpenID     string    `gorm:"type:varchar(255);uniqueIndex;column:openid"` // 唯一索引，登录必需
	Nickname   string    `gorm:"type:varchar(255);column:nickname"`
	Avatar     string    `gorm:"type:varchar(255);column:avatar"`
	Phone      string    `gorm:"type:varchar(20);column:phone"`
	FamilyID   int64     `gorm:"index;column:family_id"`
	FamilyRole string    `gorm:"type:varchar(50);column:family_role"`
	CreateTime time.Time `gorm:"autoCreateTime;column:create_time"`
}

// TableName 指定表名
func (SystemUser) TableName() string {
	return "system_user"
}
