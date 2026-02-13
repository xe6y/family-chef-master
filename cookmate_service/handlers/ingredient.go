package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// IngredientHandler 食材处理器
type IngredientHandler struct{}

// NewIngredientHandler 创建食材处理器实例
// 返回: 食材处理器
func NewIngredientHandler() *IngredientHandler {
	return &IngredientHandler{}
}

// CreateIngredientRequest 创建食材请求结构（单位统一化：ingredientId + quantity + unitId）
type CreateIngredientRequest struct {
	IngredientID string  `json:"ingredientId"`            // 食材库ID，必填
	Quantity     float64 `json:"quantity"`                // 数量
	UnitID       string  `json:"unitId"`                  // 单位ID，须为该食材的常用单位
	Name         string  `json:"name"`                    // 兼容旧版
	Unit         string  `json:"unit"`                    // 兼容旧版
	Amount       string  `json:"amount"`                  // 兼容旧版
	Storage      string  `json:"storage"`                 // 存储位置
	CategoryID   string  `json:"categoryId"`              // 食材类型分类ID
	Thumbnail    string  `json:"thumbnail"`               // 缩略图URL
	Icon         string  `json:"icon"`                    // 图标
	Note         string  `json:"note"`                    // 备注
	ExpiryDate   string  `json:"expiryDate"`              // 过期日期
	PurchaseDate string  `json:"purchaseDate"`            // 购买日期
}

// GetIngredients 获取食材列表
// @Summary 获取食材列表
// @Description 获取用户的食材库存列表
// @Tags 食材管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param storage query string false "存储位置筛选（room/fridge/freezer）"
// @Param categoryId query string false "分类ID筛选"
// @Param urgent query bool false "是否只显示紧急"
// @Param expiringDays query int false "过期天数筛选"
// @Success 200 {object} models.Response{data=object}
// @Router /api/ingredients [get]
func (h *IngredientHandler) GetIngredients(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 构建查询 - 优先使用 family_id，如果没有则使用 user_id
	query := config.DB.Model(&models.IngredientItem{}).Preload("Category").Preload("Master").Preload("UnitRef")
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	// 存储位置筛选
	if storage := c.Query("storage"); storage != "" {
		query = query.Where("storage = ?", storage)
	}

	// 分类筛选
	if categoryID := c.Query("categoryId"); categoryID != "" {
		query = query.Where("category_id = ?", categoryID)
	}

	// 兼容旧版本的category参数（映射为storage）
	if category := c.Query("category"); category != "" && c.Query("storage") == "" {
		query = query.Where("storage = ?", category)
	}

	// 紧急筛选
	if urgent := c.Query("urgent"); urgent == "true" {
		today := time.Now().Format("2006-01-02")
		query = query.Where("expiry_date <= ?", today)
	}

	// 过期天数筛选
	if expiringDaysStr := c.Query("expiringDays"); expiringDaysStr != "" {
		days, _ := strconv.Atoi(expiringDaysStr)
		targetDate := time.Now().AddDate(0, 0, days).Format("2006-01-02")
		query = query.Where("expiry_date <= ?", targetDate)
	}

	// 获取列表，默认按过期日期排序
	var ingredients []models.IngredientItem
	query.Order("expiry_date ASC").Find(&ingredients)

	// 转换为响应结构
	list := make([]*models.IngredientResponse, len(ingredients))
	for i, item := range ingredients {
		list[i] = item.ToResponse()
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", gin.H{
		"list":  list,
		"total": len(list),
	}))
}

// GetIngredientsGrouped 获取分组的食材列表
// @Summary 获取分组的食材列表
// @Description 获取按食材分类分组的库存列表
// @Tags 食材管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param storage query string false "存储位置筛选（room/fridge/freezer）"
// @Success 200 {object} models.Response{data=object}
// @Router /api/ingredients/grouped [get]
func (h *IngredientHandler) GetIngredientsGrouped(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	storage := c.Query("storage")

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 获取所有可用分类（系统分类 + 用户/家庭自定义分类）
	var categories []models.IngredientCategory
	categoryQuery := config.DB.Where("is_system = ?", true)
	if user.FamilyID != "" {
		categoryQuery = categoryQuery.Or("family_id = ?", user.FamilyID)
	} else {
		categoryQuery = categoryQuery.Or("user_id = ?", userID)
	}
	categoryQuery.Order("sort_order ASC").Find(&categories)

	// 为每个分类获取食材
	groups := make([]*models.IngredientGroupResponse, 0)
	for _, cat := range categories {
		var ingredients []models.IngredientItem
		query := config.DB.Model(&models.IngredientItem{}).
			Preload("Category").Preload("Master").Preload("UnitRef").
			Where("category_id = ?", cat.ID)

		// 使用 family_id 或 user_id 过滤
		if user.FamilyID != "" {
			query = query.Where("family_id = ?", user.FamilyID)
		} else {
			query = query.Where("user_id = ?", userID)
		}

		// 存储位置筛选
		if storage != "" {
			query = query.Where("storage = ?", storage)
		}

		query.Order("expiry_date ASC").Find(&ingredients)

		if len(ingredients) > 0 {
			list := make([]*models.IngredientResponse, len(ingredients))
			for i, item := range ingredients {
				list[i] = item.ToResponse()
			}

			groups = append(groups, &models.IngredientGroupResponse{
				Category:    cat.ToCategoryResp(),
				Ingredients: list,
				Count:       len(list),
			})
		}
	}

	// 获取未分类的食材
	var uncategorized []models.IngredientItem
	uncatQuery := config.DB.Model(&models.IngredientItem{}).
		Preload("Category").Preload("Master").Preload("UnitRef").
		Where("user_id = ?", userID).
		Where("category_id = '' OR category_id IS NULL")

	// 应用存储位置筛选
	if storage != "" {
		uncatQuery = uncatQuery.Where("storage = ?", storage)
	}

	uncatQuery.Order("expiry_date ASC").Find(&uncategorized)

	if len(uncategorized) > 0 {
		list := make([]*models.IngredientResponse, len(uncategorized))
		for i, item := range uncategorized {
			list[i] = item.ToResponse()
		}

		groups = append(groups, &models.IngredientGroupResponse{
			Category: &models.IngredientCategoryResp{
				ID:        "uncategorized",
				Name:      "未分类",
				Icon:      "📦",
				Color:     "#9E9E9E",
				SortOrder: 100,
				IsSystem:  true,
			},
			Ingredients: list,
			Count:       len(list),
		})
	}

	// 计算总数
	totalCount := 0
	for _, group := range groups {
		totalCount += group.Count
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", gin.H{
		"groups": groups,
		"total":  totalCount,
	}))
}

// GetExpiringIngredients 获取即将过期食材
// @Summary 获取即将过期食材
// @Description 获取指定天数内即将过期的食材
// @Tags 食材管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param days query int false "天数（默认3）"
// @Success 200 {object} models.Response{data=object}
// @Router /api/ingredients/expiring [get]
func (h *IngredientHandler) GetExpiringIngredients(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 获取天数参数，默认3天
	days, _ := strconv.Atoi(c.DefaultQuery("days", "3"))

	// 计算目标日期
	targetDate := time.Now().AddDate(0, 0, days)

	// 查询即将过期的食材
	var ingredients []models.IngredientItem
	query := config.DB.Preload("Category").Preload("Master").Preload("UnitRef")
	if user.FamilyID != "" {
		query = query.Where("family_id = ? AND expiry_date <= ?", user.FamilyID, targetDate)
	} else {
		query = query.Where("user_id = ? AND expiry_date <= ?", userID, targetDate)
	}
	query.
		Order("expiry_date ASC").
		Find(&ingredients)

	// 转换为响应结构
	list := make([]*models.IngredientResponse, len(ingredients))
	for i, item := range ingredients {
		list[i] = item.ToResponse()
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", gin.H{
		"list":  list,
		"total": len(list),
	}))
}

// GetIngredientDetail 获取食材详情
// @Summary 获取食材详情
// @Description 获取指定食材的详细信息
// @Tags 食材管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param ingredientId path string true "食材ID"
// @Success 200 {object} models.Response{data=models.IngredientResponse}
// @Failure 404 {object} models.Response
// @Router /api/ingredients/{ingredientId} [get]
func (h *IngredientHandler) GetIngredientDetail(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	ingredientID := c.Param("ingredientId")

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	var ingredient models.IngredientItem
	query := config.DB.Preload("Category").Preload("Master").Preload("UnitRef").Where("id = ?", ingredientID)
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	if result := query.First(&ingredient); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"食材不存在",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", ingredient.ToResponse()))
}

// GetIngredientBatches 获取同食材库的所有批次（按 ingredient_id 或 name 兼容）
// @Summary 获取同食材的所有批次
// @Description 按食材库ID或名称获取该食材的所有库存批次
// @Tags 食材管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param ingredientId query string false "食材库ID"
// @Param name query string false "食材名称（兼容旧版）"
// @Success 200 {object} models.Response{data=object}
// @Router /api/ingredients/batches [get]
func (h *IngredientHandler) GetIngredientBatches(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	ingredientID := c.Query("ingredientId")
	name := c.Query("name")

	if ingredientID == "" && name == "" {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请提供食材库ID(ingredientId)或食材名称(name)",
		))
		return
	}

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	var ingredients []models.IngredientItem
	query := config.DB.Preload("Category").Preload("Master").Preload("UnitRef")
	if ingredientID != "" {
		query = query.Where("ingredient_id = ?", ingredientID)
	} else {
		query = query.Where("name = ?", name)
	}
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}
	query.Order("expiry_date ASC").Find(&ingredients)

	// 转换为响应结构
	list := make([]*models.IngredientResponse, len(ingredients))
	for i, item := range ingredients {
		list[i] = item.ToResponse()
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", gin.H{
		"list":  list,
		"total": len(list),
	}))
}

// CreateIngredient 添加食材
// @Summary 添加食材
// @Description 添加新的食材到库存
// @Tags 食材管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body CreateIngredientRequest true "食材信息"
// @Success 200 {object} models.Response{data=models.IngredientResponse}
// @Failure 400 {object} models.Response
// @Router /api/ingredients [post]
func (h *IngredientHandler) CreateIngredient(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var req CreateIngredientRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误",
		))
		return
	}
	// 单位统一化：必须提供食材库ID与单位ID
	if req.IngredientID == "" {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请选择食材（ingredientId不能为空）",
		))
		return
	}
	if req.UnitID == "" {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请选择单位（unitId不能为空）",
		))
		return
	}
	// 校验单位属于该食材的常用单位
	var iu models.IngredientUnit
	if err := config.DB.Where("ingredient_id = ? AND unit_id = ?", req.IngredientID, req.UnitID).First(&iu).Error; err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"所选单位不属于该食材的常用单位",
		))
		return
	}

	// 解析过期日期
	var expiryDate time.Time
	if req.ExpiryDate != "" {
		var err error
		expiryDate, err = time.Parse("2006-01-02", req.ExpiryDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, models.NewErrorResponse(
				models.CodeBadRequest,
				"过期日期格式错误，应为：YYYY-MM-DD",
			))
			return
		}
	} else {
		// 默认7天后过期
		expiryDate = time.Now().AddDate(0, 0, 7)
	}

	// 解析购买日期
	var purchaseDate time.Time
	if req.PurchaseDate != "" {
		var err error
		purchaseDate, err = time.Parse("2006-01-02", req.PurchaseDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, models.NewErrorResponse(
				models.CodeBadRequest,
				"购买日期格式错误，应为：YYYY-MM-DD",
			))
			return
		}
	} else {
		purchaseDate = time.Now()
	}

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 默认存储位置
	if req.Storage == "" {
		req.Storage = models.StorageFridge
	}

	// 默认分类：从食材库带出或使用“其他”
	categoryID := req.CategoryID
	if categoryID == "" {
		var master models.IngredientMaster
		if config.DB.First(&master, "id = ?", req.IngredientID).Error == nil && master.CategoryID != "" {
			categoryID = master.CategoryID
		} else {
			categoryID = "cat_other"
		}
	}

	ingredient := &models.IngredientItem{
		IngredientID:  req.IngredientID,
		Quantity:     req.Quantity,
		UnitID:       req.UnitID,
		Name:         req.Name, // 兼容旧版，新数据以 Master 为准
		Unit:         req.Unit,
		Amount:       req.Amount,
		Storage:      req.Storage,
		CategoryID:   categoryID,
		Thumbnail:    req.Thumbnail,
		Icon:         req.Icon,
		Note:         req.Note,
		ExpiryDate:   expiryDate,
		PurchaseDate: purchaseDate,
		UserID:       userID,
		FamilyID:     user.FamilyID,
	}

	if result := config.DB.Create(ingredient); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"添加食材失败",
		))
		return
	}

	// 重新加载关联数据
	config.DB.Preload("Category").Preload("Master").Preload("UnitRef").First(ingredient, "id = ?", ingredient.ID)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("添加成功", ingredient.ToResponse()))
}

// UpdateIngredient 更新食材
// @Summary 更新食材
// @Description 更新指定的食材信息
// @Tags 食材管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param ingredientId path string true "食材ID"
// @Param request body CreateIngredientRequest true "食材信息"
// @Success 200 {object} models.Response{data=models.IngredientResponse}
// @Failure 404 {object} models.Response
// @Router /api/ingredients/{ingredientId} [put]
func (h *IngredientHandler) UpdateIngredient(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	ingredientID := c.Param("ingredientId")

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 查询食材 - 优先使用 family_id，如果没有则使用 user_id
	var ingredient models.IngredientItem
	query := config.DB.Where("id = ?", ingredientID)
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	if result := query.First(&ingredient); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"食材不存在",
		))
		return
	}

	var req CreateIngredientRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数格式错误",
		))
		return
	}

	// 若提供了单位统一化字段，校验单位属于该食材
	if req.IngredientID != "" && req.UnitID != "" {
		var iu models.IngredientUnit
		if err := config.DB.Where("ingredient_id = ? AND unit_id = ?", req.IngredientID, req.UnitID).First(&iu).Error; err != nil {
			c.JSON(http.StatusBadRequest, models.NewErrorResponse(
				models.CodeBadRequest,
				"所选单位不属于该食材的常用单位",
			))
			return
		}
	}

	// 构建更新数据
	updates := make(map[string]interface{})
	if req.IngredientID != "" {
		updates["ingredient_id"] = req.IngredientID
	}
	if req.UnitID != "" {
		updates["unit_id"] = req.UnitID
	}
	if req.Name != "" {
		updates["name"] = req.Name
	}
	if req.Quantity >= 0 {
		updates["quantity"] = req.Quantity
	}
	if req.Unit != "" {
		updates["unit"] = req.Unit
	}
	if req.Amount != "" {
		updates["amount"] = req.Amount
	}
	if req.Storage != "" {
		updates["storage"] = req.Storage
	}
	if req.CategoryID != "" {
		updates["category_id"] = req.CategoryID
	}
	if req.Thumbnail != "" {
		updates["thumbnail"] = req.Thumbnail
	}
	if req.Icon != "" {
		updates["icon"] = req.Icon
	}
	if req.Note != "" {
		updates["note"] = req.Note
	}
	if req.ExpiryDate != "" {
		expiryDate, err := time.Parse("2006-01-02", req.ExpiryDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, models.NewErrorResponse(
				models.CodeBadRequest,
				"过期日期格式错误，应为：YYYY-MM-DD",
			))
			return
		}
		updates["expiry_date"] = expiryDate
	}
	if req.PurchaseDate != "" {
		purchaseDate, err := time.Parse("2006-01-02", req.PurchaseDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, models.NewErrorResponse(
				models.CodeBadRequest,
				"购买日期格式错误，应为：YYYY-MM-DD",
			))
			return
		}
		updates["purchase_date"] = purchaseDate
	}

	if len(updates) > 0 {
		if result := config.DB.Model(&ingredient).Updates(updates); result.Error != nil {
			c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
				models.CodeServerError,
				"更新失败",
			))
			return
		}
	}

	// 重新获取食材信息
	config.DB.Preload("Category").Preload("Master").Preload("UnitRef").First(&ingredient, "id = ?", ingredientID)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("更新成功", ingredient.ToResponse()))
}

// DeleteIngredient 删除食材
// @Summary 删除食材
// @Description 删除指定的食材
// @Tags 食材管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param ingredientId path string true "食材ID"
// @Success 200 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/ingredients/{ingredientId} [delete]
func (h *IngredientHandler) DeleteIngredient(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	ingredientID := c.Param("ingredientId")

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 查询食材 - 优先使用 family_id，如果没有则使用 user_id
	var ingredient models.IngredientItem
	query := config.DB.Where("id = ?", ingredientID)
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	if result := query.First(&ingredient); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"食材不存在",
		))
		return
	}

	if result := config.DB.Delete(&ingredient); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"删除失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("删除成功", nil))
}
