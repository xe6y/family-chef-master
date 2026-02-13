package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// StorageLocationHandler 存储位置处理器
type StorageLocationHandler struct{}

// NewStorageLocationHandler 创建存储位置处理器实例
// 返回: 存储位置处理器
func NewStorageLocationHandler() *StorageLocationHandler {
	return &StorageLocationHandler{}
}

// GetStorageLocations 获取存储位置列表
// @Summary 获取存储位置列表
// @Description 获取用户自定义和系统的存储位置列表
// @Tags 存储位置
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.Response{data=object}
// @Router /api/storage-locations [get]
func (h *StorageLocationHandler) GetStorageLocations(c *gin.Context) {
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

	// 查询存储位置 - 优先使用 family_id，如果没有则使用 user_id
	var locations []models.StorageLocation
	query := config.DB
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}
	query.Order("sort_order ASC").Find(&locations)

	// 如果用户没有数据，初始化默认数据
	if len(locations) == 0 {
		defaultLocations := models.GetDefaultStorageLocations()
		newLocations := make([]models.StorageLocation, 0)
		
		tx := config.DB.Begin()
		for _, loc := range defaultLocations {
			// 保持原有ID（如room, fridge）如果可能，但为了避免ID冲突（如果是UUID主键），
			// 系统默认ID是字符串 "room", "fridge" 等。
			// 如果多个用户都用 "room" 作为主键，是不行的。
			// 所以必须生成新ID，或者 StorageLocation 的主键不是 ID 而是 (UserID, ID)。
			// GORM 默认 ID 是主键。
			// 
			// 策略调整：
			// 我们使用生成的 UUID 作为 ID。
			// Name 使用默认的。
			// 前端需要通过 Name 或 ID 来匹配。
			// 旧数据 IngredientItem.Storage 存的是 "room" / "fridge"。
			// 如果我们生成了新 ID，旧数据关联会断吗？
			// IngredientItem.Storage 是字符串。
			// 如果我们希望旧数据 "room" 显示为 "常温"，
			// 我们需要确保有一个 Location 的 ID 是 "room" 吗？不能，因为 ID 全局唯一。
			// 
			// 解决方案：
			// IngredientItem.Storage 存储的是 Location ID。
			// 旧数据 "room", "fridge" 是硬编码的字符串。
			// 我们在初始化时，创建 Location：
			// Name: "常温", ID: uuid(), UserID: uid.
			// 
			// 问题：旧的 IngredientItem 存的是 "room"。
			// 我们需要迁移旧数据吗？
			// 或者，我们在前端做映射？
			// 
			// 更好的方案：
			// 1. 保留 "room", "fridge", "freezer" 作为保留 ID (不推荐，因为多用户)。
			// 2. 迁移旧数据：找到所有 storage="room" 的 ingredients，更新为 storage=NewRoomUUID。
			// 
			// 让我们在初始化时做数据迁移。
			
			newLoc := models.StorageLocation{
				Name:      loc.Name,
				SortOrder: loc.SortOrder,
				IsSystem:  false,
				UserID:    userID,
				FamilyID:  user.FamilyID, // 自动填充家庭ID
			}
			// ID 会自动生成 UUID
			
			if err := tx.Create(&newLoc).Error; err != nil {
				tx.Rollback()
				c.JSON(http.StatusInternalServerError, models.NewErrorResponse(models.CodeServerError, "初始化数据失败"))
				return
			}
			
			newLocations = append(newLocations, newLoc)
			
			// 迁移旧数据
			// 将该用户所有 storage = 旧ID 的食材更新为 storage = 新UUID
			tx.Model(&models.IngredientItem{}).
				Where("user_id = ? AND storage = ?", userID, loc.ID).
				Update("storage", newLoc.ID)
		}
		tx.Commit()
		
		c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", gin.H{
			"list": newLocations,
		}))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", gin.H{
		"list": locations,
	}))
}

// CreateStorageLocation 创建存储位置
// @Summary 创建存储位置
// @Description 创建新的存储位置
// @Tags 存储位置
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body object true "位置信息"
// @Success 200 {object} models.Response{data=models.StorageLocation}
// @Router /api/storage-locations [post]
func (h *StorageLocationHandler) CreateStorageLocation(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var req struct {
		Name      string `json:"name" binding:"required"`
		SortOrder int    `json:"sortOrder"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误",
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

	location := &models.StorageLocation{
		Name:      req.Name,
		SortOrder: req.SortOrder,
		IsSystem:  false,
		UserID:    userID,
		FamilyID:  user.FamilyID, // 自动填充家庭ID
	}

	if result := config.DB.Create(location); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"创建失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("创建成功", location))
}

// UpdateStorageLocation 更新存储位置
// @Summary 更新存储位置
// @Description 更新指定的存储位置
// @Tags 存储位置
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param locationId path string true "位置ID"
// @Param request body object true "位置信息"
// @Success 200 {object} models.Response{data=models.StorageLocation}
// @Router /api/storage-locations/{locationId} [put]
func (h *StorageLocationHandler) UpdateStorageLocation(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	locationID := c.Param("locationId")

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 查询存储位置 - 优先使用 family_id，如果没有则使用 user_id
	var location models.StorageLocation
	query := config.DB.Where("id = ?", locationID)
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	if result := query.First(&location); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"位置不存在或无权修改",
		))
		return
	}

	var req struct {
		Name      string `json:"name"`
		SortOrder *int   `json:"sortOrder"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误",
		))
		return
	}

	updates := make(map[string]interface{})
	if req.Name != "" {
		updates["name"] = req.Name
	}
	if req.SortOrder != nil {
		updates["sort_order"] = *req.SortOrder
	}

	if len(updates) > 0 {
		config.DB.Model(&location).Updates(updates)
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("更新成功", location))
}

// DeleteStorageLocation 删除存储位置
// @Summary 删除存储位置
// @Description 删除指定的存储位置
// @Tags 存储位置
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param locationId path string true "位置ID"
// @Success 200 {object} models.Response
// @Router /api/storage-locations/{locationId} [delete]
func (h *StorageLocationHandler) DeleteStorageLocation(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	locationID := c.Param("locationId")

	// 获取用户的家庭ID
	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"获取用户信息失败",
		))
		return
	}

	// 查询存储位置 - 优先使用 family_id，如果没有则使用 user_id
	var location models.StorageLocation
	query := config.DB.Where("id = ?", locationID)
	if user.FamilyID != "" {
		query = query.Where("family_id = ?", user.FamilyID)
	} else {
		query = query.Where("user_id = ?", userID)
	}

	if result := query.First(&location); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"位置不存在或无权删除",
		))
		return
	}

	// 检查是否有关联的食材
	var count int64
	config.DB.Model(&models.IngredientItem{}).Where("storage = ?", locationID).Count(&count)
	if count > 0 {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"该位置下还有食材，无法删除",
		))
		return
	}

	config.DB.Delete(&location)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("删除成功", nil))
}

// ReorderStorageLocations 重新排序存储位置
// @Summary 重新排序存储位置
// @Description 批量更新存储位置的顺序
// @Tags 存储位置
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body object true "排序信息 {ids: [id1, id2...]}"
// @Success 200 {object} models.Response
// @Router /api/storage-locations/reorder [post]
func (h *StorageLocationHandler) ReorderStorageLocations(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var req struct {
		IDs []string `json:"ids" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误",
		))
		return
	}

	tx := config.DB.Begin()

	for i, id := range req.IDs {
		// 更新用户自定义的位置
		tx.Model(&models.StorageLocation{}).
			Where("id = ? AND user_id = ?", id, userID).
			Update("sort_order", i+1)
	}
	
	tx.Commit()

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("排序更新成功", nil))
}
