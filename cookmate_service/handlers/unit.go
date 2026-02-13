package handlers

import (
	"bitePal_service/config"
	"bitePal_service/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// UnitHandler 单位处理器
type UnitHandler struct{}

// NewUnitHandler 创建单位处理器实例
func NewUnitHandler() *UnitHandler {
	return &UnitHandler{}
}

// GetUnits 获取单位列表
// GET /api/units
func (h *UnitHandler) GetUnits(c *gin.Context) {
	var list []models.Unit
	config.DB.Order("sort_order ASC, id ASC").Find(&list)
	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", gin.H{
		"list": list,
	}))
}
