package handler

import (
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
		ID:       id,
		Nickname: req.Nickname,
		Avatar:   req.Avatar,
		Phone:    req.Phone,
	}

	if err := h.userService.UpdateUser(user); err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "更新用户失败: "+err.Error()))
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
		TotalUsers:  stats["total_users"].(int64),
		TodayUsers:  stats["today_users"].(int64),
		FamilyUsers: stats["family_users"].(int64),
		LonelyUsers: stats["lonely_users"].(int64),
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
