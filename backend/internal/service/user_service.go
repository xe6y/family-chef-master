package service

import (
	"errors"
	"time"

	"family-chef-backend/internal/database"
	"family-chef-backend/internal/models"
)

// UserService 用户服务
type UserService struct{}

// NewUserService 创建用户服务实例
func NewUserService() *UserService {
	return &UserService{}
}

// CreateUser 创建用户
func (s *UserService) CreateUser(user *models.SystemUser) error {
	// 检查用户是否已存在
	var existingUser models.SystemUser
	if err := database.DB.Where("openid = ?", user.OpenID).First(&existingUser).Error; err == nil {
		return errors.New("用户已存在")
	}

	// 创建新用户
	if err := database.DB.Create(user).Error; err != nil {
		return err
	}
	return nil
}

// GetUserByID 根据ID获取用户
func (s *UserService) GetUserByID(id int64) (*models.SystemUser, error) {
	var user models.SystemUser
	if err := database.DB.First(&user, id).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

// GetUserByOpenID 根据OpenID获取用户
func (s *UserService) GetUserByOpenID(openID string) (*models.SystemUser, error) {
	var user models.SystemUser
	if err := database.DB.Where("openid = ?", openID).First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

// UpdateUser 更新用户信息
func (s *UserService) UpdateUser(user *models.SystemUser) error {
	return database.DB.Save(user).Error
}

// UpdateUserProfile 更新用户基本信息
func (s *UserService) UpdateUserProfile(id int64, nickname, avatar, phone string) error {
	updates := map[string]interface{}{
		"nickname": nickname,
		"avatar":   avatar,
		"phone":    phone,
	}
	return database.DB.Model(&models.SystemUser{}).Where("id = ?", id).Updates(updates).Error
}

// JoinFamily 用户加入家庭
func (s *UserService) JoinFamily(userID, familyID int64, role string) error {
	updates := map[string]interface{}{
		"family_id":   familyID,
		"family_role": role,
	}
	return database.DB.Model(&models.SystemUser{}).Where("id = ?", userID).Updates(updates).Error
}

// LeaveFamily 用户离开家庭
func (s *UserService) LeaveFamily(userID int64) error {
	updates := map[string]interface{}{
		"family_id":   0,
		"family_role": "",
	}
	return database.DB.Model(&models.SystemUser{}).Where("id = ?", userID).Updates(updates).Error
}

// GetFamilyMembers 获取家庭成员列表
func (s *UserService) GetFamilyMembers(familyID int64) ([]models.SystemUser, error) {
	var users []models.SystemUser
	if err := database.DB.Where("family_id = ?", familyID).Find(&users).Error; err != nil {
		return nil, err
	}
	return users, nil
}

// DeleteUser 删除用户
func (s *UserService) DeleteUser(id int64) error {
	return database.DB.Delete(&models.SystemUser{}, id).Error
}

// ListUsers 分页查询用户列表
func (s *UserService) ListUsers(page, pageSize int) ([]models.SystemUser, int64, error) {
	var users []models.SystemUser
	var total int64

	// 获取总数
	if err := database.DB.Model(&models.SystemUser{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := database.DB.Offset(offset).Limit(pageSize).Find(&users).Error; err != nil {
		return nil, 0, err
	}

	return users, total, nil
}

// SearchUsers 搜索用户
func (s *UserService) SearchUsers(keyword string, page, pageSize int) ([]models.SystemUser, int64, error) {
	var users []models.SystemUser
	var total int64

	// 构建查询条件
	query := database.DB.Model(&models.SystemUser{}).Where(
		"nickname LIKE ? OR phone LIKE ?",
		"%"+keyword+"%",
		"%"+keyword+"%",
	)

	// 获取总数
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Offset(offset).Limit(pageSize).Find(&users).Error; err != nil {
		return nil, 0, err
	}

	return users, total, nil
}

// GetUserStats 获取用户统计信息
func (s *UserService) GetUserStats() (map[string]interface{}, error) {
	var stats map[string]interface{}

	// 总用户数
	var totalUsers int64
	if err := database.DB.Model(&models.SystemUser{}).Count(&totalUsers).Error; err != nil {
		return nil, err
	}

	// 今日新增用户数
	var todayUsers int64
	today := time.Now().Format("2006-01-02")
	if err := database.DB.Model(&models.SystemUser{}).
		Where("DATE(create_time) = ?", today).
		Count(&todayUsers).Error; err != nil {
		return nil, err
	}

	// 有家庭的用户数
	var familyUsers int64
	if err := database.DB.Model(&models.SystemUser{}).
		Where("family_id > 0").
		Count(&familyUsers).Error; err != nil {
		return nil, err
	}

	stats = map[string]interface{}{
		"total_users":  totalUsers,
		"today_users":  todayUsers,
		"family_users": familyUsers,
		"lonely_users": totalUsers - familyUsers,
	}

	return stats, nil
}
