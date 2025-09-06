package handler

import (
	"net/http"
	"strconv"

	"family-chef-backend/internal/dto"
	"family-chef-backend/internal/models"
	"family-chef-backend/internal/service"

	"github.com/gin-gonic/gin"
)

// FamilyHandler 家庭处理器
type FamilyHandler struct {
	familyService *service.FamilyService
}

// NewFamilyHandler 创建家庭处理器
func NewFamilyHandler() *FamilyHandler {
	return &FamilyHandler{
		familyService: service.NewFamilyService(),
	}
}

// CreateFamily 创建家庭
func (h *FamilyHandler) CreateFamily(c *gin.Context) {
	var req dto.CreateFamilyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	// 生成邀请码
	inviteCode := h.familyService.GenerateInviteCode()

	family := &models.SysFamily{
		Name:        req.Name,
		Description: req.Description,
		OwnerID:     req.OwnerID,
		InviteCode:  inviteCode,
	}

	if err := h.familyService.CreateFamily(family); err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "创建家庭失败: "+err.Error()))
		return
	}

	response := dto.FamilyResponse{
		ID:          family.ID,
		Name:        family.Name,
		Description: family.Description,
		Avatar:      family.Avatar,
		OwnerID:     family.OwnerID,
		InviteCode:  family.InviteCode,
		CreateTime:  family.CreateTime,
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(response))
}

// GetFamily 获取家庭信息
func (h *FamilyHandler) GetFamily(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "无效的家庭ID"))
		return
	}

	family, err := h.familyService.GetFamilyByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, dto.ErrorResponse(404, "家庭不存在"))
		return
	}

	response := dto.FamilyResponse{
		ID:          family.ID,
		Name:        family.Name,
		Description: family.Description,
		Avatar:      family.Avatar,
		OwnerID:     family.OwnerID,
		InviteCode:  family.InviteCode,
		CreateTime:  family.CreateTime,
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(response))
}

// JoinFamily 加入家庭
func (h *FamilyHandler) JoinFamily(c *gin.Context) {
	var req dto.JoinFamilyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	if err := h.familyService.JoinFamilyByInviteCode(req.InviteCode, req.UserID); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "加入家庭失败: "+err.Error()))
		return
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(gin.H{
		"message": "成功加入家庭",
	}))
}
