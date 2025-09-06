package models

import "time"

// SysUser 系统用户表
type SysUser struct {
	ID         int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
	OpenID     string    `gorm:"type:varchar(255);uniqueIndex;column:openid"`
	Nickname   string    `gorm:"type:varchar(255);column:nickname"`
	Avatar     string    `gorm:"type:varchar(255);column:avatar"`
	Phone      string    `gorm:"type:varchar(20);column:phone"`
	Role       string    `gorm:"type:varchar(50);column:role"`
	FamilyID   int64     `gorm:"index;column:family_id"`
	FamilyRole string    `gorm:"type:varchar(50);column:family_role"`
	CreateTime time.Time `gorm:"autoCreateTime;column:create_time;autoUpdateTime:false"`
}

// TableName 指定表名
func (SysUser) TableName() string {
	return "sys_user"
}
