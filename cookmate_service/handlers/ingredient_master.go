package handlers

import (
	"bitePal_service/config"
	"bitePal_service/models"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// IngredientMasterHandler 食材库处理器
type IngredientMasterHandler struct{}

// NewIngredientMasterHandler 创建食材库处理器实例
func NewIngredientMasterHandler() *IngredientMasterHandler {
	return &IngredientMasterHandler{}
}

// GetIngredientMasterList 获取食材库列表（支持搜索）
// GET /api/ingredient-master?q=鸡腿
func (h *IngredientMasterHandler) GetIngredientMasterList(c *gin.Context) {
	q := strings.TrimSpace(c.Query("q"))
	query := config.DB.Model(&models.IngredientMaster{})
	if q != "" {
		query = query.Where("name ILIKE ?", "%"+q+"%")
	}
	query = query.Order("sort_order ASC, name ASC").Limit(50)

	var list []models.IngredientMaster
	query.Find(&list)
	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", gin.H{
		"list": list,
	}))
}

// IngredientUnitItem 某食材的单位项（含展示名）
type IngredientUnitItem struct {
	UnitID        string  `json:"unitId"`
	FactorToBase  float64 `json:"factorToBase"`
	DisplayName   string  `json:"displayName"`
	SortOrder     int     `json:"sortOrder"`
}

// GetIngredientMasterUnits 获取某食材的常用单位列表
// GET /api/ingredient-master/:id/units
func (h *IngredientMasterHandler) GetIngredientMasterUnits(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"缺少食材ID",
		))
		return
	}

	var iu []models.IngredientUnit
	config.DB.Where("ingredient_id = ?", id).Order("sort_order ASC, unit_id ASC").Find(&iu)
	if len(iu) == 0 {
		c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", gin.H{"list": []IngredientUnitItem{}}))
		return
	}

	unitIds := make([]string, len(iu))
	for i := range iu {
		unitIds[i] = iu[i].UnitID
	}
	var units []models.Unit
	config.DB.Where("id IN ?", unitIds).Find(&units)
	unitMap := make(map[string]string)
	for _, u := range units {
		unitMap[u.ID] = u.DisplayName
	}

	list := make([]IngredientUnitItem, len(iu))
	for i := range iu {
		list[i] = IngredientUnitItem{
			UnitID:       iu[i].UnitID,
			FactorToBase: iu[i].FactorToBase,
			DisplayName:  unitMap[iu[i].UnitID],
			SortOrder:    iu[i].SortOrder,
		}
	}
	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", gin.H{"list": list}))
}
