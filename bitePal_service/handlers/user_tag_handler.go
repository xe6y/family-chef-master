package handlers

import (
	"bitePal_service/controllers"

	"github.com/gin-gonic/gin"
)

// UserTagHandler 用户标签处理器
type UserTagHandler struct {
	controller *controllers.UserTagController
}

// NewUserTagHandler 创建用户标签处理器
func NewUserTagHandler() *UserTagHandler {
	return &UserTagHandler{
		controller: controllers.NewUserTagController(),
	}
}

// GetUserTags 获取用户常用标签
func (h *UserTagHandler) GetUserTags(ctx *gin.Context) {
	h.controller.GetUserTags(ctx)
}
