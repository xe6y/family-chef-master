package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// UserTagHandler 用户标签处理器
type UserTagHandler struct{}

// NewUserTagHandler 创建用户标签处理器
func NewUserTagHandler() *UserTagHandler {
	return &UserTagHandler{}
}

// GetUserTags 获取用户常用标签
func (h *UserTagHandler) GetUserTags(ctx *gin.Context) {
	userID := middleware.GetUserIDFromContext(ctx)
	if userID == "" {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	var tags []*models.UserTag
	err := config.DB.Where("user_id = ?", userID).
		Order("use_count DESC, created_at DESC").
		Find(&tags).Error

	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "获取标签失败"})
		return
	}

	// 转换为响应格式
	response := make([]*map[string]interface{}, len(tags))
	for i, tag := range tags {
		response[i] = &map[string]interface{}{
			"id":       tag.ID,
			"name":     tag.Name,
			"color":    tag.Color,
			"useCount": tag.UseCount,
		}
	}

	ctx.JSON(http.StatusOK, response)
}
