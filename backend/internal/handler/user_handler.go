package handler

import (
	"log"
	"net/http"
	"strconv"

	"family-chef-backend/internal/dto"
	"family-chef-backend/internal/models"
	"family-chef-backend/internal/service"

	"github.com/gin-gonic/gin"
)

// UserHandler 用户处理器
type UserHandler struct {
	userService *service.UserService
}

// NewUserHandler 创建用户处理器
func NewUserHandler() *UserHandler {
	return &UserHandler{
		userService: service.NewUserService(),
	}
}

// CreateUser 创建用户
func (h *UserHandler) CreateUser(c *gin.Context) {
	var req dto.CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	user := &models.SystemUser{
		OpenID:   req.OpenID,
		Nickname: req.Nickname,
		Avatar:   req.Avatar,
		Phone:    req.Phone,
	}

	if err := h.userService.CreateUser(user); err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "创建用户失败: "+err.Error()))
		return
	}

	response := dto.UserResponse{
		ID:         user.ID,
		OpenID:     user.OpenID,
		Nickname:   user.Nickname,
		Avatar:     user.Avatar,
		Phone:      user.Phone,
		FamilyID:   user.FamilyID,
		FamilyRole: user.FamilyRole,
		CreateTime: user.CreateTime,
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(response))
}

// GetUser 获取用户信息
func (h *UserHandler) GetUser(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "无效的用户ID"))
		return
	}

	user, err := h.userService.GetUserByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, dto.ErrorResponse(404, "用户不存在"))
		return
	}

	response := dto.UserResponse{
		ID:         user.ID,
		OpenID:     user.OpenID,
		Nickname:   user.Nickname,
		Avatar:     user.Avatar,
		Phone:      user.Phone,
		FamilyID:   user.FamilyID,
		FamilyRole: user.FamilyRole,
		CreateTime: user.CreateTime,
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(response))
}

// GetUserByOpenID 根据OpenID获取用户
func (h *UserHandler) GetUserByOpenID(c *gin.Context) {
	openID := c.Query("openid")
	if openID == "" {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "OpenID不能为空"))
		return
	}

	user, err := h.userService.GetUserByOpenID(openID)
	if err != nil {
		c.JSON(http.StatusNotFound, dto.ErrorResponse(404, "用户不存在"))
		return
	}

	response := dto.UserResponse{
		ID:         user.ID,
		OpenID:     user.OpenID,
		Nickname:   user.Nickname,
		Avatar:     user.Avatar,
		Phone:      user.Phone,
		FamilyID:   user.FamilyID,
		FamilyRole: user.FamilyRole,
		CreateTime: user.CreateTime,
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(response))
}

// UpdateUser 更新用户信息
func (h *UserHandler) UpdateUser(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "无效的用户ID"))
		return
	}

	var req dto.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	user := &models.SystemUser{
		ID:         id,
		Nickname:   req.Nickname,
		Avatar:     req.Avatar,
		Phone:      req.Phone,
		Role:       req.Role,
		FamilyID:   req.FamilyID,
		FamilyRole: req.FamilyRole,
	}

	if err := h.userService.UpdateUser(user); err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "更新用户失败: "+err.Error()))
		return
	}

	// 重新获取用户信息以确保数据正确
	updatedUser, err := h.userService.GetUserByID(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "获取用户信息失败: "+err.Error()))
		return
	}

	response := dto.UserResponse{
		ID:         updatedUser.ID,
		OpenID:     updatedUser.OpenID,
		Nickname:   updatedUser.Nickname,
		Avatar:     updatedUser.Avatar,
		Phone:      updatedUser.Phone,
		Role:       updatedUser.Role,
		FamilyID:   updatedUser.FamilyID,
		FamilyRole: updatedUser.FamilyRole,
		CreateTime: updatedUser.CreateTime,
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(response))
}

// UpdateUserProfile 更新用户基本信息
func (h *UserHandler) UpdateUserProfile(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "无效的用户ID"))
		return
	}

	var req dto.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	if err := h.userService.UpdateUserProfile(id, req.Nickname, req.Avatar, req.Phone); err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "更新用户信息失败: "+err.Error()))
		return
	}

	c.JSON(http.StatusOK, dto.SuccessResponse("用户信息更新成功"))
}

// ListUsers 获取用户列表
func (h *UserHandler) ListUsers(c *gin.Context) {
	var req dto.PageRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	users, total, err := h.userService.ListUsers(req.Page, req.PageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "获取用户列表失败: "+err.Error()))
		return
	}

	var userResponses []dto.UserResponse
	for _, user := range users {
		userResponses = append(userResponses, dto.UserResponse{
			ID:         user.ID,
			OpenID:     user.OpenID,
			Nickname:   user.Nickname,
			Avatar:     user.Avatar,
			Phone:      user.Phone,
			Role:       user.Role,
			FamilyID:   user.FamilyID,
			FamilyRole: user.FamilyRole,
			CreateTime: user.CreateTime,
		})
	}

	response := dto.NewListResponse(userResponses, total, req.Page, req.PageSize)
	c.JSON(http.StatusOK, dto.SuccessResponse(response))
}

// SearchUsers 搜索用户
func (h *UserHandler) SearchUsers(c *gin.Context) {
	var req dto.SearchRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	if req.Keyword == "" {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "搜索关键词不能为空"))
		return
	}

	users, total, err := h.userService.SearchUsers(req.Keyword, req.Page, req.PageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "搜索用户失败: "+err.Error()))
		return
	}

	var userResponses []dto.UserResponse
	for _, user := range users {
		userResponses = append(userResponses, dto.UserResponse{
			ID:         user.ID,
			OpenID:     user.OpenID,
			Nickname:   user.Nickname,
			Avatar:     user.Avatar,
			Phone:      user.Phone,
			Role:       user.Role,
			FamilyID:   user.FamilyID,
			FamilyRole: user.FamilyRole,
			CreateTime: user.CreateTime,
		})
	}

	response := dto.NewListResponse(userResponses, total, req.Page, req.PageSize)
	c.JSON(http.StatusOK, dto.SuccessResponse(response))
}

// GetUserStats 获取用户统计信息
func (h *UserHandler) GetUserStats(c *gin.Context) {
	stats, err := h.userService.GetUserStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "获取统计信息失败: "+err.Error()))
		return
	}

	response := dto.UserStatsResponse{
		TotalUsers:  stats["total_users"],
		TodayUsers:  stats["today_users"],
		FamilyUsers: stats["family_users"],
		LonelyUsers: stats["lonely_users"],
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(response))
}

// DeleteUser 删除用户
func (h *UserHandler) DeleteUser(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "无效的用户ID"))
		return
	}

	if err := h.userService.DeleteUser(id); err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "删除用户失败: "+err.Error()))
		return
	}

	c.JSON(http.StatusOK, dto.SuccessResponse("用户删除成功"))
}

// Register 用户注册
func (h *UserHandler) Register(c *gin.Context) {
	var req dto.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	// 检查用户是否已存在
	existingUser, err := h.userService.GetUserByOpenID(req.OpenID)
	if err == nil && existingUser != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "用户已存在"))
		return
	}

	// 执行注册
	response, err := h.userService.RegisterUser(&req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "注册失败: "+err.Error()))
		return
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(response))
}

// WechatLogin 微信登录
func (h *UserHandler) WechatLogin(c *gin.Context) {
	var req struct {
		Code     string `json:"code" binding:"required"` // 微信登录code
		UserInfo struct {
			NickName  string `json:"nickName"`
			AvatarUrl string `json:"avatarUrl"`
			Gender    int    `json:"gender"`
		} `json:"userInfo"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("微信登录参数错误: %v", err)
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	log.Printf("微信登录请求: code=%s, userInfo=%+v", req.Code, req.UserInfo)

	// 调用微信接口获取OpenID
	openID, err := h.userService.Code2Session(req.Code)
	if err != nil {
		log.Printf("微信登录失败 - Code2Session错误: %v", err)
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "微信登录失败: "+err.Error()))
		return
	}

	log.Printf("获取到OpenID: %s", openID)

	// 检查用户是否已注册
	user, err := h.userService.GetUserByOpenID(openID)
	if err != nil {
		// 用户不存在，返回未注册状态
		log.Printf("用户未注册: OpenID=%s", openID)
		response := map[string]interface{}{
			"isRegistered": false,
			"openID":       openID,
			"userInfo":     req.UserInfo,
		}
		c.JSON(http.StatusOK, dto.SuccessResponse(response))
		return
	}

	// 用户已注册，返回用户信息
	log.Printf("用户已注册: ID=%d, OpenID=%s", user.ID, user.OpenID)
	userResponse := dto.UserResponse{
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

	response := map[string]interface{}{
		"isRegistered": true,
		"user":         userResponse,
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(response))
}
