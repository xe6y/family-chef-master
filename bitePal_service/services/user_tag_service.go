package services

import (
	"bitePal_service/config"
	"bitePal_service/models"
)

// UserTagService 用户标签服务
type UserTagService struct{}

// GetUserTags 获取用户的常用标签列表
// userID: 用户ID
// 返回: 标签列表（按使用次数降序）
func (s *UserTagService) GetUserTags(userID string) ([]*models.UserTag, error) {
	var tags []*models.UserTag
	err := config.DB.Where("user_id = ?", userID).
		Order("use_count DESC, created_at DESC").
		Find(&tags).Error
	return tags, err
}

// CreateOrUpdateTag 创建或更新标签
// userID: 用户ID
// name: 标签名称
// color: 标签颜色
// 返回: 标签对象
func (s *UserTagService) CreateOrUpdateTag(userID, name, color string) (*models.UserTag, error) {
	var tag models.UserTag

	// 查找是否已存在相同名称的标签
	err := config.DB.Where("user_id = ? AND name = ?", userID, name).First(&tag).Error

	if err != nil {
		// 不存在，创建新标签
		tag = models.UserTag{
			UserID:   userID,
			Name:     name,
			Color:    color,
			UseCount: 1,
		}
		err = config.DB.Create(&tag).Error
		return &tag, err
	}

	// 已存在，更新颜色和使用次数
	tag.Color = color
	tag.UseCount++
	err = config.DB.Save(&tag).Error
	return &tag, err
}
