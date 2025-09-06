package models

import "time"

// SysDictData 字典数据表
type SysDictData struct {
	ID              int64     `gorm:"primaryKey;autoIncrement;column:id"`
	SysDictTypeCode string    `gorm:"type:varchar(255);column:dict_type;not null;index"`
	Name            string    `gorm:"type:varchar(255);column:name"`
	Value           string    `gorm:"type:varchar(255);column:code"`
	ValueEx1        string    `gorm:"type:varchar(255);column:value_ex1"`
	ValueEx2        string    `gorm:"type:varchar(255);column:value_ex2"`
	Sort            int8      `gorm:"type:tinyint;column:sort"`
	CreatedAt       time.Time `gorm:"autoCreateTime"`
	CreatedBy       int64
	UpdatedAt       time.Time `gorm:"autoCreateTime"`
	UpdatedBy       int64
}

func (SysDictData) TableName() string {
	return "sys_dict_data"
}
