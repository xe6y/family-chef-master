package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"bitePal_service/utils"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ShoppingHandler 购物清单处理器
type ShoppingHandler struct{}

// NewShoppingHandler 创建购物清单处理器实例
// 返回: 购物清单处理器
func NewShoppingHandler() *ShoppingHandler {
	return &ShoppingHandler{}
}

// CreateShoppingListRequest 创建购物清单请求结构
type CreateShoppingListRequest struct {
	Name  string                `json:"name"`  // 清单名称
	Items []models.ShoppingItem `json:"items"` // 购物项列表
}

// AddShoppingItemRequest 添加购物项请求结构
type AddShoppingItemRequest struct {
	IngredientID   string  `json:"ingredientId" binding:"required"`   // 食材ID
	IngredientName string  `json:"ingredientName" binding:"required"` // 食材名称
	Quantity       float64 `json:"quantity" binding:"required"`       // 数量
	UnitID         string  `json:"unitId" binding:"required"`         // 单位ID
	UnitName       string  `json:"unitName" binding:"required"`       // 单位名称
	Price          float64 `json:"price"`                             // 价格
}

// UpdateShoppingItemRequest 更新购物项请求结构
type UpdateShoppingItemRequest struct {
	IngredientID   *string  `json:"ingredientId"`   // 食材ID
	IngredientName *string  `json:"ingredientName"` // 食材名称
	Quantity       *float64 `json:"quantity"`       // 预计购买数量
	UnitID         *string  `json:"unitId"`         // 单位ID
	UnitName       *string  `json:"unitName"`       // 单位名称
	ActualQuantity *float64 `json:"actualQuantity"` // 实际购买数量
	Price          *float64 `json:"price"`          // 价格
	Checked        *bool    `json:"checked"`        // 是否已购买
}

// GetShoppingLists 获取购物清单列表
// @Summary 获取购物清单列表
// @Description 获取用户的购物清单列表
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(20)
// @Param completed query bool false "是否只显示已完成"
// @Success 200 {object} models.Response{data=models.PagedResponse}
// @Router /api/shopping-lists [get]
func (h *ShoppingHandler) GetShoppingLists(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	pagination := utils.GetPagination(c)

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
	query := config.DB.Model(&models.ShoppingList{})
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	// 完成状态筛选
	if completed := c.Query("completed"); completed == "true" {
		query = query.Where("completed_at IS NOT NULL")
	} else if completed == "false" {
		query = query.Where("completed_at IS NULL")
	}

	// 获取总数
	var total int64
	query.Count(&total)

	// 获取列表
	var lists []models.ShoppingList
	query.Offset(pagination.Offset).Limit(pagination.PageSize).Order("created_at DESC").Find(&lists)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功",
		models.NewPagedResponse(lists, total, pagination.Page, pagination.PageSize)))
}

// GetCurrentShoppingList 获取当前购物清单
// @Summary 获取当前购物清单
// @Description 获取用户当前未完成的购物清单，如果不存在则自动创建
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.Response{data=models.ShoppingList}
// @Router /api/shopping-lists/current [get]
func (h *ShoppingHandler) GetCurrentShoppingList(c *gin.Context) {
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

	// 查询当前购物清单 - 优先使用 family_id，如果没有则使用 user_id
	var list models.ShoppingList
	query := config.DB.Where("completed_at IS NULL")
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}
	result := query.Order("created_at DESC").First(&list)

	if result.Error != nil {
		// 如果没有当前清单，创建一个新的
		list = models.ShoppingList{
			Name:       "购物清单",
			Items:      models.ShoppingItems{},
			TotalPrice: 0,
			UserID:     userID,
			FamilyID:   user.FamilyID, // 自动填充家庭ID
		}
		if err := config.DB.Create(&list).Error; err != nil {
			c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
				models.CodeServerError,
				"创建购物清单失败",
			))
			return
		}
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", list))
}

// CreateShoppingList 创建购物清单
// @Summary 创建购物清单
// @Description 创建新的购物清单
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body CreateShoppingListRequest true "清单信息"
// @Success 200 {object} models.Response{data=models.ShoppingList}
// @Router /api/shopping-lists [post]
func (h *ShoppingHandler) CreateShoppingList(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var req CreateShoppingListRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数格式错误",
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

	// 为每个购物项生成ID
	for i := range req.Items {
		if req.Items[i].ID == "" {
			req.Items[i].ID = uuid.New().String()
		}
	}

	// 默认名称
	if req.Name == "" {
		req.Name = "购物清单"
	}

	list := &models.ShoppingList{
		Name:     req.Name,
		Items:    req.Items,
		UserID:   userID,
		FamilyID: user.FamilyID, // 自动填充家庭ID
	}

	// 计算总价
	list.CalculateTotalPrice()

	if result := config.DB.Create(list); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"创建购物清单失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("创建成功", list))
}

// UpdateShoppingList 更新购物清单
// @Summary 更新购物清单
// @Description 更新指定的购物清单
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param listId path string true "清单ID"
// @Param request body CreateShoppingListRequest true "清单信息"
// @Success 200 {object} models.Response{data=models.ShoppingList}
// @Failure 404 {object} models.Response
// @Router /api/shopping-lists/{listId} [put]
func (h *ShoppingHandler) UpdateShoppingList(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	listID := c.Param("listId")

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 查询购物清单 - 优先使用 family_id，如果没有则使用 user_id
	var list models.ShoppingList
	query := config.DB.Where("id = ?", listID)
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	if result := query.First(&list); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物清单不存在",
		))
		return
	}

	var req CreateShoppingListRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数格式错误",
		))
		return
	}

	// 构建更新数据
	updates := make(map[string]interface{})
	if req.Name != "" {
		updates["name"] = req.Name
	}
	if req.Items != nil {
		// 为每个购物项生成ID
		for i := range req.Items {
			if req.Items[i].ID == "" {
				req.Items[i].ID = uuid.New().String()
			}
		}
		list.Items = req.Items
		list.CalculateTotalPrice()
		updates["items"] = list.Items
		updates["total_price"] = list.TotalPrice
	}

	if len(updates) > 0 {
		if result := config.DB.Model(&list).Updates(updates); result.Error != nil {
			c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
				models.CodeServerError,
				"更新失败",
			))
			return
		}
	}

	// 重新获取清单
	config.DB.First(&list, "id = ?", listID)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("更新成功", list))
}

// AddShoppingItem 添加购物项
// @Summary 添加购物项
// @Description 向购物清单添加购物项
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param listId path string true "清单ID"
// @Param request body AddShoppingItemRequest true "购物项信息"
// @Success 200 {object} models.Response{data=models.ShoppingItem}
// @Failure 404 {object} models.Response
// @Router /api/shopping-lists/{listId}/items [post]
func (h *ShoppingHandler) AddShoppingItem(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	listID := c.Param("listId")

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 查询购物清单 - 优先使用 family_id，如果没有则使用 user_id
	var list models.ShoppingList
	query := config.DB.Where("id = ?", listID)
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	if result := query.First(&list); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物清单不存在",
		))
		return
	}

	var req AddShoppingItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误：食材信息不完整",
		))
		return
	}

	item := models.ShoppingItem{
		ID:             uuid.New().String(),
		IngredientID:   req.IngredientID,
		IngredientName: req.IngredientName,
		Quantity:       req.Quantity,
		UnitID:         req.UnitID,
		UnitName:       req.UnitName,
		Price:          req.Price,
		Checked:        false,
	}

	list.AddItem(item)

	// 更新清单 (使用Save确保所有字段包括Items都被更新)
	if err := config.DB.Save(&list).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"添加失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("添加成功", item))
}

// UpdateShoppingItem 更新购物项
// @Summary 更新购物项
// @Description 更新购物清单中的购物项
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param listId path string true "清单ID"
// @Param itemId path string true "购物项ID"
// @Param request body UpdateShoppingItemRequest true "购物项信息"
// @Success 200 {object} models.Response{data=models.ShoppingItem}
// @Failure 404 {object} models.Response
// @Router /api/shopping-lists/{listId}/items/{itemId} [put]
func (h *ShoppingHandler) UpdateShoppingItem(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	listID := c.Param("listId")
	itemID := c.Param("itemId")

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 查询购物清单 - 优先使用 family_id，如果没有则使用 user_id
	var list models.ShoppingList
	query := config.DB.Where("id = ?", listID)
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	if result := query.First(&list); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物清单不存在",
		))
		return
	}

	var req UpdateShoppingItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数格式错误",
		))
		return
	}

	// 查找并更新购物项
	var foundItem *models.ShoppingItem
	for i, item := range list.Items {
		if item.ID == itemID {
			if req.IngredientID != nil {
				list.Items[i].IngredientID = *req.IngredientID
			}
			if req.IngredientName != nil {
				list.Items[i].IngredientName = *req.IngredientName
			}
			if req.Quantity != nil {
				list.Items[i].Quantity = *req.Quantity
			}
			if req.UnitID != nil {
				list.Items[i].UnitID = *req.UnitID
			}
			if req.UnitName != nil {
				list.Items[i].UnitName = *req.UnitName
			}
			if req.ActualQuantity != nil {
				list.Items[i].ActualQuantity = req.ActualQuantity
			}
			if req.Price != nil {
				list.Items[i].Price = *req.Price
			}
			if req.Checked != nil {
				list.Items[i].Checked = *req.Checked
			}
			foundItem = &list.Items[i]
			break
		}
	}

	if foundItem == nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物项不存在",
		))
		return
	}

	// 重新计算总价
	list.CalculateTotalPrice()

	// 更新清单
	config.DB.Model(&list).Updates(map[string]interface{}{
		"items":       list.Items,
		"total_price": list.TotalPrice,
	})

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("更新成功", foundItem))
}

// DeleteShoppingItem 删除购物项
// @Summary 删除购物项
// @Description 从购物清单删除购物项
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param listId path string true "清单ID"
// @Param itemId path string true "购物项ID"
// @Success 200 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/shopping-lists/{listId}/items/{itemId} [delete]
func (h *ShoppingHandler) DeleteShoppingItem(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	listID := c.Param("listId")
	itemID := c.Param("itemId")

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 查询购物清单 - 优先使用 family_id，如果没有则使用 user_id
	var list models.ShoppingList
	query := config.DB.Where("id = ?", listID)
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	if result := query.First(&list); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物清单不存在",
		))
		return
	}

	if !list.RemoveItem(itemID) {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物项不存在",
		))
		return
	}

	// 更新清单
	config.DB.Model(&list).Updates(map[string]interface{}{
		"items":       list.Items,
		"total_price": list.TotalPrice,
	})

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("删除成功", nil))
}

// CompleteShoppingList 完成购物清单
// @Summary 完成购物清单
// @Description 结算当前购物清单：将已勾选的商品生成历史订单，未勾选的商品保留在当前清单
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param listId path string true "清单ID"
// @Success 200 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/shopping-lists/{listId}/complete [post]
func (h *ShoppingHandler) CompleteShoppingList(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	listID := c.Param("listId")

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 查询购物清单 - 优先使用 family_id，如果没有则使用 user_id
	var currentList models.ShoppingList
	query := config.DB.Where("id = ?", listID)
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	if result := query.First(&currentList); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物清单不存在",
		))
		return
	}

	// 1. 筛选出已购买（已勾选）和未购买的商品
	var purchasedItems models.ShoppingItems
	var remainingItems models.ShoppingItems

	for _, item := range currentList.Items {
		if item.Checked {
			purchasedItems = append(purchasedItems, item)
		} else {
			remainingItems = append(remainingItems, item)
		}
	}

	if len(purchasedItems) == 0 {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"没有已勾选的商品，无法结算",
		))
		return
	}

	// 2. 创建历史订单（只包含已购买商品）
	historyList := models.ShoppingList{
		ID:          uuid.New().String(),
		Name:        currentList.Name + " (已完成)",
		Items:       purchasedItems,
		UserID:      userID,
		FamilyID:    user.FamilyID, // 自动填充家庭ID
		CompletedAt: func() *time.Time { t := time.Now(); return &t }(),
	}
	historyList.CalculateTotalPrice()

	// 开启事务
	tx := config.DB.Begin()

	// 保存历史订单
	if err := tx.Create(&historyList).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"创建历史订单失败",
		))
		return
	}

	// 3. 更新当前清单（只保留未购买商品）
	currentList.Items = remainingItems
	currentList.CalculateTotalPrice()

	if err := tx.Model(&currentList).Updates(map[string]interface{}{
		"items":       currentList.Items,
		"total_price": currentList.TotalPrice,
	}).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"更新当前清单失败",
		))
		return
	}

	tx.Commit()

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("结算成功", gin.H{
		"historyId":   historyList.ID,
		"completedAt": historyList.CompletedAt,
		"totalSpent":  historyList.TotalPrice,
	}))
}

// ShareShoppingList 分享购物清单
// @Summary 分享购物清单
// @Description 生成购物清单的分享链接
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param listId path string true "清单ID"
// @Success 200 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/shopping-lists/{listId}/share [post]
func (h *ShoppingHandler) ShareShoppingList(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	listID := c.Param("listId")

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 查询购物清单 - 优先使用 family_id，如果没有则使用 user_id
	var list models.ShoppingList
	query := config.DB.Where("id = ?", listID)
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	if result := query.First(&list); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物清单不存在",
		))
		return
	}

	// 生成分享码
	shareCode := uuid.New().String()[:8]

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("分享成功", gin.H{
		"shareUrl":  "https://bitepal.com/share/" + shareCode,
		"shareCode": shareCode,
	}))
}

// GetShoppingListDetail 获取购物清单详情
// @Summary 获取购物清单详情
// @Description 获取指定购物清单的完整详情
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param listId path string true "清单ID"
// @Success 200 {object} models.Response{data=models.ShoppingList}
// @Failure 404 {object} models.Response
// @Router /api/shopping-lists/{listId} [get]
func (h *ShoppingHandler) GetShoppingListDetail(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	listID := c.Param("listId")

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 查询购物清单 - 优先使用 family_id，如果没有则使用 user_id
	var list models.ShoppingList
	query := config.DB.Where("id = ?", listID)
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	if result := query.First(&list); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物清单不存在",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", list))
}

// GetShoppingHistory 获取购物订单历史
// @Summary 获取购物订单历史
// @Description 获取已完成的购物清单历史
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(20)
// @Param startDate query string false "开始日期"
// @Param endDate query string false "结束日期"
// @Success 200 {object} models.Response{data=models.PagedResponse}
// @Router /api/shopping-lists/history [get]
func (h *ShoppingHandler) GetShoppingHistory(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	pagination := utils.GetPagination(c)

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 构建查询 - 只查询已完成的清单，优先使用 family_id
	query := config.DB.Model(&models.ShoppingList{}).Where("completed_at IS NOT NULL")
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	// 日期筛选
	if startDate := c.Query("startDate"); startDate != "" {
		query = query.Where("completed_at >= ?", startDate)
	}
	if endDate := c.Query("endDate"); endDate != "" {
		query = query.Where("completed_at <= ?", endDate+" 23:59:59")
	}

	// 获取总数
	var total int64
	query.Count(&total)

	// 获取列表
	var lists []models.ShoppingList
	query.Offset(pagination.Offset).Limit(pagination.PageSize).Order("completed_at DESC").Find(&lists)

	// 转换为历史项
	historyList := make([]*models.ShoppingListHistoryItem, len(lists))
	for i, list := range lists {
		historyList[i] = list.ToHistoryItem()
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功",
		models.NewPagedResponse(historyList, total, pagination.Page, pagination.PageSize)))
}

// GetShoppingHistoryItems 获取购物订单历史商品项
// @Summary 获取购物订单历史商品项
// @Description 获取所有已完成购物清单中的商品项，用于添加到食材
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(20)
// @Param search query string false "搜索关键词"
// @Success 200 {object} models.Response{data=models.PagedResponse}
// @Router /api/shopping-lists/history/items [get]
func (h *ShoppingHandler) GetShoppingHistoryItems(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	pagination := utils.GetPagination(c)
	search := c.Query("search")

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 1. 获取所有已完成的清单 - 优先使用 family_id
	var lists []models.ShoppingList
	query := config.DB.Model(&models.ShoppingList{}).Where("completed_at IS NOT NULL")
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}
	
	// 这里我们实际上需要获取Items里的内容。由于Items是JSON字段，无法直接在SQL中高效查询/搜索JSON数组内容(取决于DB类型，MySQL 5.7+支持但GORM处理略繁琐)。
	// 为了简化，我们先获取最近的100个已完成清单，然后在内存中提取和去重。
	// 如果数据量巨大，这会有性能问题，但对于个人购物清单应用，数据量通常可控。
	
	// 获取最近的50个已完成清单（通常足够覆盖常用食材）
	query.Order("completed_at DESC").Limit(50).Find(&lists)

	// 2. 提取所有商品项并去重
	itemMap := make(map[string]models.ShoppingItem)
	var allItems []models.ShoppingItem

	for _, list := range lists {
		for _, item := range list.Items {
			// 简单的去重逻辑：按食材名称去重
			if search != "" && !utils.ContainsIgnoreCase(item.IngredientName, search) {
				continue
			}

			// 如果已经存在，跳过（保留最近的记录，因为我们是按时间倒序遍历清单的）
			if _, exists := itemMap[item.IngredientName]; !exists {
				itemMap[item.IngredientName] = item
				allItems = append(allItems, item)
			}
		}
	}

	// 3. 分页处理内存切片
	total := int64(len(allItems))
	start := (pagination.Page - 1) * pagination.PageSize
	end := start + pagination.PageSize

	if start > int(total) {
		start = int(total)
	}
	if end > int(total) {
		end = int(total)
	}

	pagedItems := allItems[start:end]

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功",
		models.NewPagedResponse(pagedItems, total, pagination.Page, pagination.PageSize)))
}

