package models

import "time"

// SysDictType 字典类型表
type SysDictType struct {
	ID           int64     `gorm:"primaryKey;autoIncrement;column:id"`
	Name         string    `gorm:"type:varchar(255);column:name"`
	Code         string    `gorm:"type:varchar(255);not null;unique;column:code"`
	Sort         int8      `gorm:"type:tinyint;column:sort"`
	CreatedAt    time.Time `gorm:"autoCreateTime"`
	CreatedBy    int64
	UpdatedAt    time.Time `gorm:"autoCreateTime"`
	UpdatedBy    int64
	SysDictDatas []SysDictData `gorm:"foreignKey:SysDictTypeCode;references:Code;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
}

func (SysDictType) TableName() string {
	return "sys_dict_type"
}
