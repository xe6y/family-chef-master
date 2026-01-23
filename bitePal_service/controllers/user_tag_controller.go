package controllers

import (
	"bitePal_service/middleware"
	"bitePal_service/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// UserTagController 用户标签控制器
type UserTagController struct {
	service *services.UserTagService
}

// NewUserTagController 创建用户标签控制器
func NewUserTagController() *UserTagController {
	return &UserTagController{
		service: &services.UserTagService{},
	}
}

// GetUserTags 获取用户常用标签
func (c *UserTagController) GetUserTags(ctx *gin.Context) {
	userID := middleware.GetUserIDFromContext(ctx)
	if userID == "" {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	tags, err := c.service.GetUserTags(userID)
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
