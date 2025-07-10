package handler

import (
	"net/http"
	"strconv"

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
	var family models.SystemFamily
	if err := c.ShouldBindJSON(&family); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误: " + err.Error()})
		return
	}

	if err := h.familyService.CreateFamily(&family); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建家庭失败: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "家庭创建成功",
		"data":    family,
	})
}

// GetFamily 获取家庭信息
func (h *FamilyHandler) GetFamily(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的家庭ID"})
		return
	}

	family, err := h.familyService.GetFamilyByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "家庭不存在"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": family,
	})
}
