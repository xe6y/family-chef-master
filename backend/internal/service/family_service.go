package service

import (
	"errors"
	"math/rand"

	"family-chef-backend/internal/database"
	"family-chef-backend/internal/models"

	"gorm.io/gorm"
)

// FamilyService 家庭服务
type FamilyService struct{}

// NewFamilyService 创建家庭服务实例
func NewFamilyService() *FamilyService {
	return &FamilyService{}
}

// CreateFamily 创建家庭
func (s *FamilyService) CreateFamily(family *models.SystemFamily) error {
	// 检查家庭名称是否已存在
	var existingFamily models.SystemFamily
	if err := database.DB.Where("name = ?", family.Name).First(&existingFamily).Error; err == nil {
		return errors.New("家庭名称已存在")
	}

	// 使用事务创建家庭
	return database.DB.Transaction(func(tx *gorm.DB) error {
		// 创建家庭
		if err := tx.Create(family).Error; err != nil {
			return err
		}

		// 如果有创建者ID，将创建者设为家庭管理员
		if family.OwnerID > 0 {
			if err := tx.Model(&models.SystemUser{}).
				Where("id = ?", family.OwnerID).
				Updates(map[string]interface{}{
					"family_id":   family.ID,
					"family_role": "admin",
				}).Error; err != nil {
				return err
			}
		}

		return nil
	})
}

// GetFamilyByID 根据ID获取家庭信息
func (s *FamilyService) GetFamilyByID(id int64) (*models.SystemFamily, error) {
	var family models.SystemFamily
	if err := database.DB.First(&family, id).Error; err != nil {
		return nil, err
	}
	return &family, nil
}

// GetFamilyWithMembers 获取家庭信息及成员列表
func (s *FamilyService) GetFamilyWithMembers(id int64) (*models.SystemFamily, []models.SystemUser, error) {
	var family models.SystemFamily
	var members []models.SystemUser

	// 获取家庭信息
	if err := database.DB.First(&family, id).Error; err != nil {
		return nil, nil, err
	}

	// 获取家庭成员
	if err := database.DB.Where("family_id = ?", id).Find(&members).Error; err != nil {
		return nil, nil, err
	}

	return &family, members, nil
}

// UpdateFamily 更新家庭信息
func (s *FamilyService) UpdateFamily(family *models.SystemFamily) error {
	return database.DB.Save(family).Error
}

// DeleteFamily 删除家庭
func (s *FamilyService) DeleteFamily(id int64) error {
	return database.DB.Transaction(func(tx *gorm.DB) error {
		// 删除家庭
		if err := tx.Delete(&models.SystemFamily{}, id).Error; err != nil {
			return err
		}

		// 将家庭成员的家庭ID设为0
		if err := tx.Model(&models.SystemUser{}).
			Where("family_id = ?", id).
			Updates(map[string]interface{}{
				"family_id":   0,
				"family_role": "",
			}).Error; err != nil {
			return err
		}

		return nil
	})
}

// AddFamilyMember 添加家庭成员
func (s *FamilyService) AddFamilyMember(familyID, userID int64, role string) error {
	// 检查用户是否已在其他家庭
	var user models.SystemUser
	if err := database.DB.First(&user, userID).Error; err != nil {
		return errors.New("用户不存在")
	}

	if user.FamilyID > 0 && user.FamilyID != familyID {
		return errors.New("用户已在其他家庭中")
	}

	// 更新用户家庭信息
	updates := map[string]interface{}{
		"family_id":   familyID,
		"family_role": role,
	}
	return database.DB.Model(&models.SystemUser{}).Where("id = ?", userID).Updates(updates).Error
}

// RemoveFamilyMember 移除家庭成员
func (s *FamilyService) RemoveFamilyMember(familyID, userID int64) error {
	// 检查用户是否在该家庭中
	var user models.SystemUser
	if err := database.DB.Where("id = ? AND family_id = ?", userID, familyID).First(&user).Error; err != nil {
		return errors.New("用户不在该家庭中")
	}

	// 移除用户
	updates := map[string]interface{}{
		"family_id":   0,
		"family_role": "",
	}
	return database.DB.Model(&models.SystemUser{}).Where("id = ?", userID).Updates(updates).Error
}

// GetFamilyRecipes 获取家庭菜谱列表
func (s *FamilyService) GetFamilyRecipes(familyID int64, page, pageSize int) ([]models.MenuFamily, int64, error) {
	var recipes []models.MenuFamily
	var total int64

	// 获取总数
	if err := database.DB.Model(&models.MenuFamily{}).Where("family_id = ?", familyID).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := database.DB.Where("family_id = ?", familyID).
		Offset(offset).Limit(pageSize).
		Find(&recipes).Error; err != nil {
		return nil, 0, err
	}

	return recipes, total, nil
}

// GetFamilyOrders 获取家庭订单列表
func (s *FamilyService) GetFamilyOrders(familyID int64, page, pageSize int) ([]models.Order, int64, error) {
	var orders []models.Order
	var total int64

	// 获取总数
	if err := database.DB.Model(&models.Order{}).Where("family_id = ?", familyID).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 分页查询，包含创建者信息
	offset := (page - 1) * pageSize
	if err := database.DB.Preload("Creator").
		Where("family_id = ?", familyID).
		Order("create_time DESC").
		Offset(offset).Limit(pageSize).
		Find(&orders).Error; err != nil {
		return nil, 0, err
	}

	return orders, total, nil
}

// GetFamilyStats 获取家庭统计信息
func (s *FamilyService) GetFamilyStats(familyID int64) (map[string]interface{}, error) {
	var stats map[string]interface{}

	// 家庭成员数量
	var memberCount int64
	if err := database.DB.Model(&models.SystemUser{}).
		Where("family_id = ?", familyID).
		Count(&memberCount).Error; err != nil {
		return nil, err
	}

	// 家庭菜谱数量
	var recipeCount int64
	if err := database.DB.Model(&models.MenuFamily{}).
		Where("family_id = ?", familyID).
		Count(&recipeCount).Error; err != nil {
		return nil, err
	}

	// 家庭订单数量
	var orderCount int64
	if err := database.DB.Model(&models.Order{}).
		Where("family_id = ?", familyID).
		Count(&orderCount).Error; err != nil {
		return nil, err
	}

	// 本月订单数量
	var monthOrderCount int64
	if err := database.DB.Model(&models.Order{}).
		Where("family_id = ? AND DATE_FORMAT(create_time, '%Y-%m') = DATE_FORMAT(NOW(), '%Y-%m')", familyID).
		Count(&monthOrderCount).Error; err != nil {
		return nil, err
	}

	stats = map[string]interface{}{
		"member_count":      memberCount,
		"recipe_count":      recipeCount,
		"order_count":       orderCount,
		"month_order_count": monthOrderCount,
	}

	return stats, nil
}

// SearchFamilies 搜索家庭
func (s *FamilyService) SearchFamilies(keyword string, page, pageSize int) ([]models.SystemFamily, int64, error) {
	var families []models.SystemFamily
	var total int64

	// 构建查询条件
	query := database.DB.Model(&models.SystemFamily{}).Where(
		"name LIKE ?",
		"%"+keyword+"%",
	)

	// 获取总数
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Offset(offset).Limit(pageSize).Find(&families).Error; err != nil {
		return nil, 0, err
	}

	return families, total, nil
}

// JoinFamilyByInviteCode 通过邀请码加入家庭
func (s *FamilyService) JoinFamilyByInviteCode(inviteCode string, userID int64) error {
	// 查找邀请码对应的家庭
	var family models.SystemFamily
	if err := database.DB.Where("invite_code = ?", inviteCode).First(&family).Error; err != nil {
		return errors.New("邀请码无效或已过期")
	}

	// 检查用户是否已在其他家庭
	var user models.SystemUser
	if err := database.DB.First(&user, userID).Error; err != nil {
		return errors.New("用户不存在")
	}

	if user.FamilyID > 0 && user.FamilyID != family.ID {
		return errors.New("用户已在其他家庭中")
	}

	// 检查用户是否已在该家庭中
	if user.FamilyID == family.ID {
		return errors.New("用户已在该家庭中")
	}

	// 使用事务更新用户家庭信息
	return database.DB.Transaction(func(tx *gorm.DB) error {
		updates := map[string]interface{}{
			"family_id":   family.ID,
			"family_role": "member",
		}

		if err := tx.Model(&models.SystemUser{}).Where("id = ?", userID).Updates(updates).Error; err != nil {
			return err
		}

		return nil
	})
}

// GenerateInviteCode 生成邀请码
func (s *FamilyService) GenerateInviteCode() string {
	// 生成6位随机邀请码
	const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	code := make([]byte, 6)
	for i := range code {
		code[i] = charset[rand.Intn(len(charset))]
	}
	return string(code)
}
