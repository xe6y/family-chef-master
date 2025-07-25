package service

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math/rand"
	"net/http"
	"time"

	"family-chef-backend/internal/config"
	"family-chef-backend/internal/database"
	"family-chef-backend/internal/dto"
	"family-chef-backend/internal/models"

	"gorm.io/gorm"
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
	// 只更新指定字段，避免更新create_time
	updates := map[string]interface{}{
		"nickname":    user.Nickname,
		"avatar":      user.Avatar,
		"phone":       user.Phone,
		"role":        user.Role,
		"family_id":   user.FamilyID,
		"family_role": user.FamilyRole,
	}
	return database.DB.Model(&models.SystemUser{}).Where("id = ?", user.ID).Updates(updates).Error
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
func (s *UserService) GetUserStats() (map[string]int64, error) {
	var stats map[string]int64

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

	// 无家庭的用户数
	lonelyUsers := totalUsers - familyUsers

	stats = map[string]int64{
		"total_users":  totalUsers,
		"today_users":  todayUsers,
		"family_users": familyUsers,
		"lonely_users": lonelyUsers,
	}

	return stats, nil
}

// Code2Session 微信登录凭证校验
func (s *UserService) Code2Session(code string) (string, error) {
	// 构建微信API请求URL
	url := fmt.Sprintf(
		"https://api.weixin.qq.com/sns/jscode2session?appid=%s&secret=%s&js_code=%s&grant_type=authorization_code",
		config.GlobalConfig.Wechat.AppID,
		config.GlobalConfig.Wechat.AppSecret,
		code,
	)

	fmt.Printf("微信API请求URL: %s\n", url)

	// 发送HTTP请求
	resp, err := http.Get(url)
	if err != nil {
		return "", fmt.Errorf("请求微信API失败: %v", err)
	}
	defer resp.Body.Close()

	// 读取响应
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("读取响应失败: %v", err)
	}

	fmt.Printf("微信API响应: %s\n", string(body))

	// 解析响应
	var result struct {
		OpenID     string `json:"openid"`
		SessionKey string `json:"session_key"`
		UnionID    string `json:"unionid"`
		ErrCode    int    `json:"errcode"`
		ErrMsg     string `json:"errmsg"`
	}

	if err := json.Unmarshal(body, &result); err != nil {
		return "", fmt.Errorf("解析响应失败: %v", err)
	}

	// 检查错误
	if result.ErrCode != 0 {
		return "", fmt.Errorf("微信API错误: %s", result.ErrMsg)
	}

	if result.OpenID == "" {
		return "", fmt.Errorf("获取OpenID失败")
	}

	fmt.Printf("成功获取OpenID: %s\n", result.OpenID)
	return result.OpenID, nil
}

// GetOrCreateUserByOpenID 根据OpenID获取或创建用户
func (s *UserService) GetOrCreateUserByOpenID(openID, nickname, avatar string) (*models.SystemUser, error) {
	// 先尝试查找用户
	user, err := s.GetUserByOpenID(openID)
	if err == nil {
		// 用户存在，返回用户信息
		return user, nil
	}

	// 用户不存在，创建新用户
	newUser := &models.SystemUser{
		OpenID:   openID,
		Nickname: nickname,
		Avatar:   avatar,
		Phone:    "",
	}

	if err := s.CreateUser(newUser); err != nil {
		return nil, err
	}

	return newUser, nil
}

// RegisterUser 用户注册（使用事务）
func (s *UserService) RegisterUser(req *dto.RegisterRequest) (*dto.RegisterResponse, error) {
	var response dto.RegisterResponse

	// 开始事务
	tx := database.DB.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 1. 创建用户
	user := &models.SystemUser{
		OpenID:   req.OpenID,
		Nickname: req.Nickname,
		Avatar:   req.Avatar,
		Phone:    req.Phone,
	}

	if err := tx.Create(user).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("创建用户失败: %v", err)
	}

	// 2. 处理家庭逻辑
	var family *models.SystemFamily
	var isNewFamily bool

	if req.InviteCode != "" {
		// 有邀请码，加入现有家庭
		var existingFamily models.SystemFamily
		if err := tx.Where("invite_code = ?", req.InviteCode).First(&existingFamily).Error; err != nil {
			tx.Rollback()
			if err == gorm.ErrRecordNotFound {
				return nil, fmt.Errorf("邀请码无效")
			}
			return nil, fmt.Errorf("查询家庭失败: %v", err)
		}
		family = &existingFamily
		isNewFamily = false

		// 更新用户家庭信息
		if err := tx.Model(user).Updates(map[string]interface{}{
			"family_id":   family.ID,
			"family_role": "member",
		}).Error; err != nil {
			tx.Rollback()
			return nil, fmt.Errorf("更新用户家庭信息失败: %v", err)
		}
	} else {
		// 无邀请码，不创建家庭，等待用户在家庭创建页面创建
		family = nil
		isNewFamily = false
	}

	// 提交事务
	if err := tx.Commit().Error; err != nil {
		return nil, fmt.Errorf("提交事务失败: %v", err)
	}

	// 重新获取用户信息
	if err := database.DB.First(user, user.ID).Error; err != nil {
		return nil, fmt.Errorf("获取用户信息失败: %v", err)
	}

	// 构建响应
	response.User = dto.UserResponse{
		ID:         user.ID,
		OpenID:     user.OpenID,
		Nickname:   user.Nickname,
		Avatar:     user.Avatar,
		Phone:      user.Phone,
		Role:       user.Role,
		FamilyID:   user.FamilyID,
		FamilyRole: user.FamilyRole,
		CreateTime: user.CreateTime,
	}

	if family != nil {
		response.Family = dto.FamilyResponse{
			ID:          family.ID,
			Name:        family.Name,
			Description: family.Description,
			Avatar:      family.Avatar,
			InviteCode:  family.InviteCode,
			OwnerID:     family.OwnerID,
			CreateTime:  family.CreateTime,
		}
	}

	response.IsNewFamily = isNewFamily

	return &response, nil
}

// generateInviteCode 生成邀请码
func (s *UserService) generateInviteCode() string {
	const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, 6)
	for i := range b {
		b[i] = charset[rand.Intn(len(charset))]
	}
	return string(b)
}
