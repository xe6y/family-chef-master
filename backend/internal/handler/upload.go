package handler

import (
	"fmt"
	"net/http"
	"path/filepath"
	"time"

	"family-chef-backend/internal/config"
	"family-chef-backend/internal/dto"

	"github.com/gin-gonic/gin"
)

// UploadHandler 文件上传处理器
type UploadHandler struct{}

// NewUploadHandler 创建上传处理器
func NewUploadHandler() *UploadHandler {
	return &UploadHandler{}
}

// UploadFile 上传文件
func (h *UploadHandler) UploadFile(c *gin.Context) {
	// 获取上传的文件
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "获取文件失败: "+err.Error()))
		return
	}

	// 检查文件大小
	if file.Size > config.GlobalConfig.Upload.MaxSize {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "文件大小超过限制"))
		return
	}

	// 检查文件类型
	ext := filepath.Ext(file.Filename)
	isAllowed := false
	for _, allowedType := range config.GlobalConfig.Upload.AllowedTypes {
		if "."+allowedType == ext {
			isAllowed = true
			break
		}
	}
	if !isAllowed {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "不支持的文件类型"))
		return
	}

	// 生成文件名
	filename := fmt.Sprintf("%d_%s", time.Now().UnixNano(), file.Filename)
	filepath := fmt.Sprintf("%s/%s", config.GlobalConfig.Upload.UploadPath, filename)

	// 保存文件
	if err := c.SaveUploadedFile(file, filepath); err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "保存文件失败: "+err.Error()))
		return
	}

	// 返回文件URL
	fileURL := fmt.Sprintf("/uploads/%s", filename)
	c.JSON(http.StatusOK, dto.SuccessResponse(map[string]string{
		"url": fileURL,
	}))
}
