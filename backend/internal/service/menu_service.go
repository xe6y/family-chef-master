package service

import (
	"family-chef-backend/internal/database"
	"family-chef-backend/internal/models"
)

// MenuService 菜谱服务
type MenuService struct{}

// NewMenuService 创建菜谱服务实例
func NewMenuService() *MenuService {
	return &MenuService{}
}

// GetPublicMenus 获取公共菜谱列表
func (s *MenuService) GetPublicMenus(page, pageSize int) ([]models.MenuPublic, int64, error) {
	var menus []models.MenuPublic
	var total int64

	// 获取总数
	if err := database.DB.Model(&models.MenuPublic{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := database.DB.Offset(offset).Limit(pageSize).Find(&menus).Error; err != nil {
		return nil, 0, err
	}

	return menus, total, nil
}

// GetFamilyMenus 获取家庭菜谱列表
func (s *MenuService) GetFamilyMenus(familyID int64, page, pageSize int) ([]models.MenuFamily, int64, error) {
	var menus []models.MenuFamily
	var total int64

	// 获取总数
	if err := database.DB.Model(&models.MenuFamily{}).Where("family_id = ?", familyID).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := database.DB.Where("family_id = ?", familyID).
		Offset(offset).Limit(pageSize).Find(&menus).Error; err != nil {
		return nil, 0, err
	}

	return menus, total, nil
}
