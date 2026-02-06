package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// StorageLocation 存储位置模型
type StorageLocation struct {
	ID        string         `json:"id" gorm:"type:varchar(36);primaryKey"`                                    // 位置ID
	Name      string         `json:"name" gorm:"type:varchar(50);not null;uniqueIndex:idx_user_storage_name"` // 位置名称
	SortOrder int            `json:"sortOrder" gorm:"default:0;index"`                                         // 排序顺序
	IsSystem  bool           `json:"isSystem" gorm:"default:false;index"`                                      // 是否为系统预设
	UserID    string         `json:"userId" gorm:"type:varchar(36);uniqueIndex:idx_user_storage_name"`         // 用户ID（系统预设为空）
	FamilyID  string         `json:"familyId" gorm:"type:varchar(36);index"`                                   // 家庭ID（用于家庭成员共享位置）
	CreatedAt time.Time      `json:"createdAt"`                                                                // 创建时间
	UpdatedAt time.Time      `json:"updatedAt"`                                                                // 更新时间
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`                                                           // 软删除时间
}

// BeforeCreate 创建前钩子，自动生成ID
func (s *StorageLocation) BeforeCreate(tx *gorm.DB) error {
	if s.ID == "" {
		s.ID = uuid.New().String()
	}
	return nil
}

// GetDefaultStorageLocations 获取默认的系统存储位置列表
// 返回: 默认存储位置列表
func GetDefaultStorageLocations() []*StorageLocation {
	return []*StorageLocation{
		{ID: "room", Name: "常温", SortOrder: 1, IsSystem: true},
		{ID: "fridge", Name: "冷藏", SortOrder: 2, IsSystem: true},
		{ID: "freezer", Name: "冷冻", SortOrder: 3, IsSystem: true},
	}
}
