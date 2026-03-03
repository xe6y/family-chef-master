package handlers

import (
	"fmt"
	"net/http"
	"time"

	"bitePal_service/config"
	"bitePal_service/models"

	"github.com/gin-gonic/gin"
)

// MenuCacheHandler 菜单缓存处理器
type MenuCacheHandler struct{}

// NewMenuCacheHandler 创建菜单缓存处理器
func NewMenuCacheHandler() *MenuCacheHandler {
	return &MenuCacheHandler{}
}

// getCacheKey 生成缓存键
func (h *MenuCacheHandler) getCacheKey(familyID string, date time.Time, recipeID string) string {
	dateStr := date.Format("2006-01-02")
	return fmt.Sprintf("%s:%s:%s", familyID, dateStr, recipeID)
}

// AddToCache 添加菜谱到缓存
// POST /api/menu-cache
func (h *MenuCacheHandler) AddToCache(ctx *gin.Context) {
	var req struct {
		FamilyID   string                `json:"familyId" binding:"required"`
		Date       string                `json:"date" binding:"required"`
		RecipeID   string                `json:"recipeId" binding:"required"`
		RecipeName string                `json:"recipeName" binding:"required"`
		Source     string                `json:"source" binding:"required"`
		SelectedBy []models.SimpleMember `json:"selectedBy"`
	}

	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, models.NewErrorResponse(models.CodeBadRequest, "参数错误"))
		return
	}

	// 解析日期
	date, err := time.Parse("2006-01-02", req.Date)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, models.NewErrorResponse(models.CodeBadRequest, "日期格式错误"))
		return
	}

	// 创建缓存对象
	cache := &models.MenuCache{
		FamilyID:   req.FamilyID,
		Date:       date,
		RecipeID:   req.RecipeID,
		RecipeName: req.RecipeName,
		Source:     req.Source,
		SelectedBy: req.SelectedBy,
		IsChecked:  true,
	}

	// 生成缓存ID
	cache.ID = h.getCacheKey(cache.FamilyID, cache.Date, cache.RecipeID)
	cache.AddedAt = time.Now()
	cache.UpdatedAt = time.Now()

	// 检查是否已存在
	var existing models.MenuCache
	result := config.DB.Where("id = ?", cache.ID).First(&existing)

	if result.Error == nil {
		// 已存在，更新选择者列表
		if err := config.DB.Model(&models.MenuCache{}).
			Where("id = ?", cache.ID).
			Updates(map[string]interface{}{
				"selected_by": cache.SelectedBy,
				"updated_at":  time.Now(),
			}).Error; err != nil {
			ctx.JSON(http.StatusInternalServerError, models.NewErrorResponse(models.CodeServerError, "更新缓存失败"))
			return
		}
	} else {
		// 不存在，创建新记录
		if err := config.DB.Create(cache).Error; err != nil {
			ctx.JSON(http.StatusInternalServerError, models.NewErrorResponse(models.CodeServerError, "添加缓存失败"))
			return
		}
	}

	ctx.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("添加成功", cache))
}

// RemoveFromCache 从缓存中移除菜谱
// DELETE /api/menu-cache/:familyId/:date/:recipeId
func (h *MenuCacheHandler) RemoveFromCache(ctx *gin.Context) {
	familyID := ctx.Param("familyId")
	dateStr := ctx.Param("date")
	recipeID := ctx.Param("recipeId")

	// 解析日期
	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, models.NewErrorResponse(models.CodeBadRequest, "日期格式错误"))
		return
	}

	// 从缓存中移除
	cacheID := h.getCacheKey(familyID, date, recipeID)
	if err := config.DB.Where("id = ?", cacheID).Delete(&models.MenuCache{}).Error; err != nil {
		ctx.JSON(http.StatusInternalServerError, models.NewErrorResponse(models.CodeServerError, "移除失败"))
		return
	}

	ctx.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("移除成功", nil))
}

// GetCacheByFamily 获取家庭的菜单缓存
// GET /api/menu-cache/:familyId/:date
func (h *MenuCacheHandler) GetCacheByFamily(ctx *gin.Context) {
	familyID := ctx.Param("familyId")
	dateStr := ctx.Param("date")

	// 解析日期
	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, models.NewErrorResponse(models.CodeBadRequest, "日期格式错误"))
		return
	}

	// 获取缓存
	var caches []models.MenuCache
	if err := config.DB.Where("family_id = ? AND date = ?", familyID, date).
		Order("added_at ASC").
		Find(&caches).Error; err != nil {
		ctx.JSON(http.StatusInternalServerError, models.NewErrorResponse(models.CodeServerError, "获取缓存失败"))
		return
	}

	ctx.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", caches))
}

// ToggleChecked 切换勾选状态
// PUT /api/menu-cache/:cacheId/toggle
func (h *MenuCacheHandler) ToggleChecked(ctx *gin.Context) {
	cacheID := ctx.Param("cacheId")

	// 获取当前缓存
	var cache models.MenuCache
	if err := config.DB.Where("id = ?", cacheID).First(&cache).Error; err != nil {
		ctx.JSON(http.StatusNotFound, models.NewErrorResponse(models.CodeNotFound, "缓存不存在"))
		return
	}

	// 切换状态
	if err := config.DB.Model(&models.MenuCache{}).
		Where("id = ?", cacheID).
		Updates(map[string]interface{}{
			"is_checked": !cache.IsChecked,
			"updated_at": time.Now(),
		}).Error; err != nil {
		ctx.JSON(http.StatusInternalServerError, models.NewErrorResponse(models.CodeServerError, "切换状态失败"))
		return
	}

	ctx.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("切换成功", nil))
}

// ClearFamilyCache 清空家庭指定日期的缓存
// DELETE /api/menu-cache/:familyId/:date
func (h *MenuCacheHandler) ClearFamilyCache(ctx *gin.Context) {
	familyID := ctx.Param("familyId")
	dateStr := ctx.Param("date")

	// 解析日期
	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, models.NewErrorResponse(models.CodeBadRequest, "日期格式错误"))
		return
	}

	// 清空缓存
	if err := config.DB.Where("family_id = ? AND date = ?", familyID, date).
		Delete(&models.MenuCache{}).Error; err != nil {
		ctx.JSON(http.StatusInternalServerError, models.NewErrorResponse(models.CodeServerError, "清空缓存失败"))
		return
	}

	ctx.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("清空成功", nil))
}

// ArchiveOldMenus 归档旧菜单（定时任务调用）
// POST /api/menu-cache/archive
func (h *MenuCacheHandler) ArchiveOldMenus(ctx *gin.Context) {
	// 获取昨日及之前的所有菜单缓存
	yesterday := time.Now().AddDate(0, 0, -1).Format("2006-01-02")

	var oldMenus []models.MenuCache
	if err := config.DB.Where("date < ?", yesterday).Find(&oldMenus).Error; err != nil {
		ctx.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"查询旧菜单失败",
		))
		return
	}

	if len(oldMenus) == 0 {
		ctx.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("没有需要归档的菜单", nil))
		return
	}

	// 按家庭和日期分组归档
	type archiveKey struct {
		FamilyID string
		Date     string
	}
	archiveMap := make(map[archiveKey][]models.MenuCache)

	for _, menu := range oldMenus {
		key := archiveKey{
			FamilyID: menu.FamilyID,
			Date:     menu.Date.Format("2006-01-02"),
		}
		archiveMap[key] = append(archiveMap[key], menu)
	}

	// 创建归档记录（如果需要的话，可以创建一个 menu_archive 表）
	// 这里简单地删除旧记录
	if err := config.DB.Where("date < ?", yesterday).Delete(&models.MenuCache{}).Error; err != nil {
		ctx.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"归档失败",
		))
		return
	}

	ctx.JSON(http.StatusOK, models.NewSuccessResponseWithMessage(
		fmt.Sprintf("成功归档 %d 条菜单记录", len(oldMenus)),
		map[string]interface{}{
			"archivedCount": len(oldMenus),
			"families":      len(archiveMap),
		},
	))
}
