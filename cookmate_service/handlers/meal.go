package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"bitePal_service/utils"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

// MealHandler 点餐处理器
type MealHandler struct{}

// NewMealHandler 创建点餐处理器实例
// 返回: 点餐处理器
func NewMealHandler() *MealHandler {
	return &MealHandler{}
}

// CreateOrderRequest 创建点餐请求结构
type CreateOrderRequest struct {
	Recipes []models.OrderRecipe `json:"recipes" binding:"required"` // 菜谱列表
}

// GetMealRecipes 获取点餐菜品列表
// @Summary 获取点餐菜品列表
// @Description 获取可点餐的菜品列表（用户的菜谱）
// @Tags 家庭点餐
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(20)
// @Param keyword query string false "搜索关键词"
// @Param tastes query string false "口味筛选"
// @Param status query string false "食材状态筛选"
// @Param mealTypes query string false "餐点类型筛选"
// @Param cuisines query string false "菜系筛选"
// @Success 200 {object} models.Response{data=models.PagedResponse}
// @Router /api/meals/recipes [get]
func (h *MealHandler) GetMealRecipes(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	pagination := utils.GetPagination(c)

	// 构建查询 - 用户自己的菜谱和公开的菜谱
	query := config.DB.Model(&models.Recipe{}).Where("user_id = ? OR is_public = ?", userID, true)

	// 关键词搜索
	if keyword := c.Query("keyword"); keyword != "" {
		query = query.Where("name LIKE ?", "%"+keyword+"%")
	}

	// 口味筛选
	if tastes := c.Query("tastes"); tastes != "" {
		tasteList := strings.Split(tastes, ",")
		for _, taste := range tasteList {
			query = query.Where("categories LIKE ?", "%"+taste+"%")
		}
	}

	// 菜系筛选
	if cuisines := c.Query("cuisines"); cuisines != "" {
		cuisineList := strings.Split(cuisines, ",")
		for _, cuisine := range cuisineList {
			query = query.Where("categories LIKE ?", "%"+cuisine+"%")
		}
	}

	// 获取总数
	var total int64
	query.Count(&total)

	// 获取列表
	var recipes []models.Recipe
	query.Offset(pagination.Offset).Limit(pagination.PageSize).Order("created_at DESC").Find(&recipes)

	// 转换为列表项
	list := make([]*models.RecipeListItem, len(recipes))
	for i, recipe := range recipes {
		list[i] = recipe.ToListItem()
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功",
		models.NewPagedResponse(list, total, pagination.Page, pagination.PageSize)))
}

// CreateMealOrder 创建点餐清单
// @Summary 创建点餐清单
// @Description 从缓存创建点餐订单
// @Tags 家庭点餐
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body CreateOrderRequest true "点餐信息"
// @Success 200 {object} models.Response{data=models.MealOrder}
// @Failure 400 {object} models.Response
// @Router /api/meals/orders [post]
func (h *MealHandler) CreateMealOrder(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.Select("family_id").Where("id = ?", userID).First(&user).Error; err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"用户信息不存在",
		))
		return
	}

	if user.FamilyID == "" {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"用户未加入家庭，请先创建或加入家庭",
		))
		return
	}

	var req CreateOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误：菜谱列表不能为空",
		))
		return
	}

	if len(req.Recipes) == 0 {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请选择至少一道菜品",
		))
		return
	}

	// 创建点餐订单
	order := &models.MealOrder{
		Recipes:  req.Recipes,
		Status:   models.OrderStatusPending,
		UserID:   userID,
		FamilyID: user.FamilyID,
	}

	if result := config.DB.Create(order); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"创建点餐失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("创建成功", order))
}

// ConfirmMealOrder 确认点餐
// @Summary 确认点餐
// @Description 确认指定的点餐清单
// @Tags 家庭点餐
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param orderId path string true "点餐ID"
// @Success 200 {object} models.Response{data=models.MealOrder}
// @Failure 404 {object} models.Response
// @Router /api/meals/orders/{orderId}/confirm [post]
func (h *MealHandler) ConfirmMealOrder(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	orderID := c.Param("orderId")

	var order models.MealOrder
	if result := config.DB.Where("id = ? AND user_id = ?", orderID, userID).First(&order); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"点餐清单不存在",
		))
		return
	}

	// 确认点餐
	order.Confirm()

	if result := config.DB.Model(&order).Update("status", order.Status); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"确认失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("确认成功", gin.H{
		"id":        order.ID,
		"status":    order.Status,
		"updatedAt": order.UpdatedAt,
	}))
}

// GetMealOrders 获取点餐历史
// @Summary 获取点餐历史
// @Description 获取家庭的点餐历史记录
// @Tags 家庭点餐
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(20)
// @Param status query string false "状态筛选"
// @Success 200 {object} models.Response{data=models.PagedResponse}
// @Router /api/meals/orders [get]
func (h *MealHandler) GetMealOrders(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	pagination := utils.GetPagination(c)

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.Select("family_id").Where("id = ?", userID).First(&user).Error; err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"用户信息不存在",
		))
		return
	}

	if user.FamilyID == "" {
		// 用户未加入家庭，返回空列表
		c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功",
			models.NewPagedResponse([]models.MealOrder{}, 0, pagination.Page, pagination.PageSize)))
		return
	}

	// 构建查询 - 查询家庭的订单
	query := config.DB.Model(&models.MealOrder{}).Where("family_id = ?", user.FamilyID)

	// 状态筛选
	if status := c.Query("status"); status != "" {
		statusList := strings.Split(status, ",")
		query = query.Where("status IN ?", statusList)
	}

	// 获取总数
	var total int64
	query.Count(&total)

	// 获取列表
	var orders []models.MealOrder
	query.Offset(pagination.Offset).Limit(pagination.PageSize).Order("created_at DESC").Find(&orders)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功",
		models.NewPagedResponse(orders, total, pagination.Page, pagination.PageSize)))
}

// GetOrderSummary 获取订单统计信息
// @Summary 获取订单统计信息
// @Description 根据家庭ID查询今日已生成的菜单，并统计所需食材
// @Tags 家庭点餐
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recipeIds query string false "已选菜谱ID列表（逗号分隔，用于统计食材）"
// @Success 200 {object} models.Response
// @Router /api/meals/summary [get]
func (h *MealHandler) GetOrderSummary(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.Select("family_id").Where("id = ?", userID).First(&user).Error; err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"用户信息不存在",
		))
		return
	}

	if user.FamilyID == "" {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"用户未加入家庭",
		))
		return
	}

	// 查询今日已生成的菜单（基于家庭ID）
	today := time.Now().Format("2006-01-02")
	var todayOrders []models.MealOrder
	config.DB.Where("family_id = ? AND DATE(created_at) = ?", user.FamilyID, today).
		Order("created_at DESC").
		Find(&todayOrders)

	// 提取今日菜单中的菜谱ID
	var todayRecipeIds []string
	for _, order := range todayOrders {
		for _, recipe := range order.Recipes {
			todayRecipeIds = append(todayRecipeIds, recipe.RecipeID)
		}
	}

	// 查询今日菜单的菜谱详情
	var todayRecipes []models.Recipe
	if len(todayRecipeIds) > 0 {
		config.DB.Where("id IN ?", todayRecipeIds).Find(&todayRecipes)
	}

	// 处理已选菜谱（如果提供了recipeIds参数）
	var selectedRecipes []models.Recipe
	var ingredients []models.RecipeIngredient
	recipeIdsStr := c.Query("recipeIds")

	if recipeIdsStr != "" {
		recipeIds := strings.Split(recipeIdsStr, ",")

		// 查询已选菜谱详情
		if err := config.DB.Where("id IN ?", recipeIds).Find(&selectedRecipes).Error; err != nil {
			c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
				models.CodeServerError,
				"查询菜谱失败",
			))
			return
		}

		// 统计已选菜品的食材（按 ingredientId+unitId 合并，数量相加）
		type key struct{ IngredientID, UnitID string }
		ingredientMap := make(map[key]*models.RecipeIngredient)
		for _, recipe := range selectedRecipes {
			for _, ing := range recipe.Ingredients {
				k := key{IngredientID: ing.IngredientID, UnitID: ing.UnitID}
				if existing, ok := ingredientMap[k]; ok {
					if ing.Quantity != nil && existing.Quantity != nil {
						q := *existing.Quantity + *ing.Quantity
						existing.Quantity = &q
					}
				} else {
					ingredientMap[k] = &models.RecipeIngredient{
						IngredientID: ing.IngredientID,
						Quantity:     ing.Quantity,
						UnitID:       ing.UnitID,
					}
				}
			}
		}

		// 转换为列表
		ingredients = make([]models.RecipeIngredient, 0, len(ingredientMap))
		for _, ingredient := range ingredientMap {
			ingredients = append(ingredients, *ingredient)
		}
	}

	// 构建响应
	summary := map[string]interface{}{
		"selectedRecipes": selectedRecipes,       // 已选菜品
		"todayRecipes":    todayRecipes,          // 今日已生成的菜单
		"ingredients":     ingredients,           // 所需食材
		"totalCount":      len(selectedRecipes),  // 已选菜品数量
		"hasTodayMenu":    len(todayRecipes) > 0, // 是否已有今日菜单
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", summary))
}

// CheckTodayMenuIngredients 检查今日菜单的食材需求
// @Summary 检查今日菜单的食材需求
// @Description 检查今日菜单所需食材与库存的对比
// @Tags 家庭点餐
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.Response
// @Router /api/meals/ingredient-check [get]
func (h *MealHandler) CheckTodayMenuIngredients(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.Select("family_id").Where("id = ?", userID).First(&user).Error; err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"用户信息不存在",
		))
		return
	}

	if user.FamilyID == "" {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"用户未加入家庭",
		))
		return
	}

	// 查询今日菜单（今日订单）
	today := time.Now().Format("2006-01-02")
	var todayOrders []models.MealOrder
	config.DB.Where("family_id = ? AND DATE(created_at) = ?", user.FamilyID, today).
		Order("created_at DESC").
		Find(&todayOrders)

	if len(todayOrders) == 0 {
		// 没有今日菜单
		c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", map[string]interface{}{
			"allSufficient": true,
			"requirements":  []interface{}{},
		}))
		return
	}

	// 提取今日菜单中的菜谱ID
	var recipeIds []string
	for _, order := range todayOrders {
		for _, recipe := range order.Recipes {
			recipeIds = append(recipeIds, recipe.RecipeID)
		}
	}

	// 查询菜谱详情
	var recipes []models.Recipe
	if err := config.DB.Where("id IN ?", recipeIds).Find(&recipes).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"查询菜谱失败",
		))
		return
	}

	// 统计所需食材（按 ingredientId 合并，数量相加）
	type IngredientRequirement struct {
		IngredientID   string  `json:"ingredientId"`
		IngredientName string  `json:"ingredientName"`
		RequiredAmount float64 `json:"requiredAmount"`
		AvailableAmount float64 `json:"availableAmount"`
		Unit           string  `json:"unit"`
		IsSufficient   bool    `json:"isSufficient"`
	}

	ingredientMap := make(map[string]*IngredientRequirement)

	for _, recipe := range recipes {
		for _, ing := range recipe.Ingredients {
			if ing.IngredientID == "" {
				continue
			}

			if _, ok := ingredientMap[ing.IngredientID]; !ok {
				ingredientMap[ing.IngredientID] = &IngredientRequirement{
					IngredientID:   ing.IngredientID,
					IngredientName: ing.IngredientID, // 临时使用ID，后面会查询名称
					RequiredAmount: 0,
					AvailableAmount: 0,
					Unit:           ing.UnitID,
					IsSufficient:   false,
				}
			}

			if ing.Quantity != nil {
				ingredientMap[ing.IngredientID].RequiredAmount += *ing.Quantity
			}
		}
	}

	// 查询库存食材
	var ingredientIds []string
	for id := range ingredientMap {
		ingredientIds = append(ingredientIds, id)
	}

	var ingredients []models.IngredientItem
	if len(ingredientIds) > 0 {
		config.DB.Where("user_id = ? AND ingredient_id IN ?", userID, ingredientIds).
			Find(&ingredients)
	}

	// 统计库存数量
	for _, ing := range ingredients {
		if req, ok := ingredientMap[ing.IngredientID]; ok {
			req.IngredientName = ing.Name
			req.AvailableAmount += ing.Quantity
		}
	}

	// 判断是否充足
	allSufficient := true
	requirements := make([]IngredientRequirement, 0, len(ingredientMap))
	for _, req := range ingredientMap {
		req.IsSufficient = req.AvailableAmount >= req.RequiredAmount
		if !req.IsSufficient {
			allSufficient = false
		}
		requirements = append(requirements, *req)
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", map[string]interface{}{
		"allSufficient": allSufficient,
		"requirements":  requirements,
	}))
}
