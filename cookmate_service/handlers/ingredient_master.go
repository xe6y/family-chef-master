package handlers

import (
	"bitePal_service/config"
	"bitePal_service/models"
	"net/http"
	"strings"
	"unicode"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
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

// ============================================================
// 批量食材解析接口（供外部工具/workflow 使用）
// ============================================================

// ResolveIngredientInput 单条解析输入
type ResolveIngredientInput struct {
	Name string `json:"name" binding:"required"` // 食材名称（中文）
	Unit string `json:"unit"`                    // 单位名称（中文），空则不解析单位
}

// ResolveIngredientResult 单条解析结果
type ResolveIngredientResult struct {
	InputName      string `json:"inputName"`      // 原始输入名称
	InputUnit      string `json:"inputUnit"`      // 原始输入单位
	IngredientID   string `json:"ingredientId"`   // 解析到的食材 ID（未找到为空串）
	IngredientName string `json:"ingredientName"` // 数据库中的食材名称
	UnitID         string `json:"unitId"`         // 解析到的单位 ID（未找到为空串）
	UnitName       string `json:"unitName"`       // 数据库中的单位展示名
	Matched        bool   `json:"matched"`        // 食材和单位均成功匹配时为 true
}

// ResolveIngredientsRequest 批量解析请求体
type ResolveIngredientsRequest struct {
	Ingredients []ResolveIngredientInput `json:"ingredients" binding:"required,min=1"`
}

// normalizeStr 去除空格并转小写，用于模糊比较
func normalizeStr(s string) string {
	var b strings.Builder
	for _, r := range s {
		if !unicode.IsSpace(r) {
			b.WriteRune(unicode.ToLower(r))
		}
	}
	return b.String()
}

// resolveUnit 在食材专属单位和全局单位中查找最佳匹配
// 匹配优先级：精确匹配 > 标准化后精确匹配 > ILIKE 包含匹配
func resolveUnit(ingredientID, unitInput string, allUnitMap map[string]models.Unit) (unitID, unitName string) {
	norm := normalizeStr(unitInput)

	// 1. 查该食材专属单位（ingredient_unit JOIN units）
	type row struct {
		UnitID      string
		DisplayName string
	}
	var rows []row
	config.DB.Table("ingredient_unit").
		Select("ingredient_unit.unit_id, units.display_name").
		Joins("JOIN units ON units.id = ingredient_unit.unit_id").
		Where("ingredient_unit.ingredient_id = ?", ingredientID).
		Order("ingredient_unit.sort_order ASC").
		Scan(&rows)

	for _, r := range rows {
		if strings.EqualFold(r.DisplayName, unitInput) {
			return r.UnitID, r.DisplayName
		}
	}
	for _, r := range rows {
		if normalizeStr(r.DisplayName) == norm {
			return r.UnitID, r.DisplayName
		}
	}
	for _, r := range rows {
		if strings.Contains(normalizeStr(r.DisplayName), norm) ||
			strings.Contains(norm, normalizeStr(r.DisplayName)) {
			return r.UnitID, r.DisplayName
		}
	}

	// 2. 回退：全局单位表
	if u, ok := allUnitMap[norm]; ok {
		return u.ID, u.DisplayName
	}
	for _, u := range allUnitMap {
		if strings.Contains(normalizeStr(u.DisplayName), norm) ||
			strings.Contains(norm, normalizeStr(u.DisplayName)) {
			return u.ID, u.DisplayName
		}
	}

	return "", unitInput
}

// ResolveIngredients 批量将食材名+单位名解析为数据库 ID
// POST /api/ingredient-master/resolve
//
// 请求体：
//
//	{ "ingredients": [{ "name": "猪五花肉", "unit": "克" }] }
//
// 匹配策略（食材）：精确匹配 → ILIKE 包含匹配（取 sort_order 最优结果）
// 匹配策略（单位）：食材专属单位精确 → 食材专属单位模糊 → 全局单位精确 → 全局单位模糊
func (h *IngredientMasterHandler) ResolveIngredients(c *gin.Context) {
	var req ResolveIngredientsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(models.CodeBadRequest, "参数错误："+err.Error()))
		return
	}

	// 预加载全局单位表，key = normalizeStr(displayName)
	var allUnits []models.Unit
	config.DB.Order("sort_order ASC").Find(&allUnits)
	allUnitMap := make(map[string]models.Unit, len(allUnits))
	for _, u := range allUnits {
		allUnitMap[normalizeStr(u.DisplayName)] = u
	}

	results := make([]ResolveIngredientResult, 0, len(req.Ingredients))

	for _, inp := range req.Ingredients {
		result := ResolveIngredientResult{
			InputName: inp.Name,
			InputUnit: inp.Unit,
		}

		name := strings.TrimSpace(inp.Name)
		if name == "" {
			results = append(results, result)
			continue
		}

		// ---- 食材匹配 ----
		var master models.IngredientMaster

		// 精确匹配
		exactErr := config.DB.Where("name = ?", name).
			Order("sort_order ASC, name ASC").
			First(&master).Error

		if exactErr != nil {
			// ILIKE 包含匹配（取权重最高的第一条）
			config.DB.Where("name ILIKE ?", "%"+name+"%").
				Order("sort_order ASC, name ASC").
				First(&master)
		}

		if master.ID == "" {
			// 食材未找到，整条记录标记为未匹配
			results = append(results, result)
			continue
		}

		result.IngredientID = master.ID
		result.IngredientName = master.Name

		// ---- 单位匹配 ----
		if inp.Unit != "" {
			result.UnitID, result.UnitName = resolveUnit(master.ID, inp.Unit, allUnitMap)
		}

		result.Matched = result.IngredientID != "" && result.UnitID != ""
		results = append(results, result)
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("解析完成", gin.H{
		"resolved": results,
	}))
}

// ============================================================
// 食材自动创建接口（供 workflow 工具使用）
// ============================================================

// EnsureIngredientItem 单条确保存在的请求
type EnsureIngredientItem struct {
	IngredientName string  `json:"ingredientName" binding:"required"` // 食材名称
	UnitName       string  `json:"unitName" binding:"required"`       // 单位展示名，如"根"、"克"
	UnitType       string  `json:"unitType"`                          // "weight" / "volume" / "count" / "unspecified"
	FactorToBase   float64 `json:"factorToBase" binding:"required,gt=0"` // 1 该单位 = 多少克（g）
}

// EnsureIngredientsRequest 批量确保请求体
type EnsureIngredientsRequest struct {
	Items []EnsureIngredientItem `json:"items" binding:"required,min=1"`
}

// EnsuredResult 单条确保结果
type EnsuredResult struct {
	IngredientID   string   `json:"ingredientId"`   // 食材库 ID
	IngredientName string   `json:"ingredientName"` // 食材名称
	UnitID         string   `json:"unitId"`         // 单位 ID
	UnitName       string   `json:"unitName"`       // 单位展示名
	FactorToBase   float64  `json:"factorToBase"`   // 换算比例
	Created        []string `json:"created"`        // 本次新创建的内容，如 ["ingredient","unit","ingredient_unit"]
}

// EnsureIngredients 批量确保食材和单位存在，不存在则自动创建
// POST /api/ingredient-master/ensure
//
// 对每条输入依次执行：
//  1. find-or-create ingredient_master（baseUnitId='g'）
//  2. find-or-create units（按 display_name 查找，找不到则创建）
//  3. find-or-create ingredient_unit（写入 factorToBase）
func (h *IngredientMasterHandler) EnsureIngredients(c *gin.Context) {
	var req EnsureIngredientsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(models.CodeBadRequest, "参数错误："+err.Error()))
		return
	}

	results := make([]EnsuredResult, 0, len(req.Items))

	for _, item := range req.Items {
		result := EnsuredResult{
			IngredientName: item.IngredientName,
			UnitName:       item.UnitName,
			FactorToBase:   item.FactorToBase,
		}
		var created []string

		// ---- 1. find-or-create ingredient_master ----
		var master models.IngredientMaster
		if err := config.DB.Where("name = ?", item.IngredientName).First(&master).Error; err != nil {
			master = models.IngredientMaster{
				Name:       item.IngredientName,
				BaseUnitID: "g",
				SortOrder:  100,
			}
			if err := config.DB.Create(&master).Error; err != nil {
				c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
					models.CodeServerError, "创建食材失败（"+item.IngredientName+"）："+err.Error(),
				))
				return
			}
			created = append(created, "ingredient")
		}
		result.IngredientID = master.ID

		// ---- 2. find-or-create unit ----
		unitType := item.UnitType
		if unitType == "" {
			unitType = models.UnitTypeCount // 从菜谱来的自定义单位默认为计数类型
		}

		var unit models.Unit
		if err := config.DB.Where("display_name = ?", item.UnitName).First(&unit).Error; err != nil {
			// 生成短 ID：取 UUID 前 16 字符，保证在 varchar(20) 内
			unit = models.Unit{
				ID:          uuid.New().String()[:16],
				DisplayName: item.UnitName,
				UnitType:    unitType,
				SortOrder:   200,
			}
			if err := config.DB.Create(&unit).Error; err != nil {
				c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
					models.CodeServerError, "创建单位失败（"+item.UnitName+"）："+err.Error(),
				))
				return
			}
			created = append(created, "unit")
		}
		result.UnitID = unit.ID
		result.UnitName = unit.DisplayName

		// ---- 3. find-or-create ingredient_unit ----
		var ingUnit models.IngredientUnit
		if err := config.DB.Where("ingredient_id = ? AND unit_id = ?", master.ID, unit.ID).
			First(&ingUnit).Error; err != nil {
			ingUnit = models.IngredientUnit{
				IngredientID: master.ID,
				UnitID:       unit.ID,
				FactorToBase: item.FactorToBase,
				SortOrder:    10,
			}
			if err := config.DB.Create(&ingUnit).Error; err != nil {
				c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
					models.CodeServerError, "创建食材单位关联失败："+err.Error(),
				))
				return
			}
			created = append(created, "ingredient_unit")
		}

		if created == nil {
			created = []string{}
		}
		result.Created = created
		results = append(results, result)
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("确保成功", gin.H{
		"ensured": results,
	}))
}
