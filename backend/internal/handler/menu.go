package handler

import (
	"net/http"

	"family-chef-backend/internal/service"

	"github.com/gin-gonic/gin"
)

// MenuHandler 菜谱处理器
type MenuHandler struct {
	menuService *service.MenuService
}

// NewMenuHandler 创建菜谱处理器
func NewMenuHandler() *MenuHandler {
	return &MenuHandler{
		menuService: service.NewMenuService(),
	}
}

// GetPublicMenus 获取公共菜谱
func (h *MenuHandler) GetPublicMenus(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "获取公共菜谱-业务逻辑",
		"data":    []interface{}{},
	})
}

// GetFamilyMenus 获取家庭菜谱
func (h *MenuHandler) GetFamilyMenus(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "获取家庭菜谱-业务逻辑",
		"data":    []interface{}{},
	})
}
