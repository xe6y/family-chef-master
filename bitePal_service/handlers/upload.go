package handlers

import (
	"bitePal_service/models"
	"bitePal_service/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// UploadHandler 文件上传处理器
type UploadHandler struct{}

// NewUploadHandler 创建文件上传处理器实例
// 返回: 文件上传处理器
func NewUploadHandler() *UploadHandler {
	return &UploadHandler{}
}

// 上传配置常量
const (
	MaxUploadSize = 10 << 20 // 最大上传大小：10MB
)

// 允许的图片类型
var allowedImageTypes = map[string]bool{
	"image/jpeg": true,
	"image/png":  true,
	"image/gif":  true,
	"image/webp": true,
}

// UploadImage 上传图片
// @Summary 上传图片
// @Description 上传图片文件到 MinIO
// @Tags 文件上传
// @Accept multipart/form-data
// @Produce json
// @Security BearerAuth
// @Param file formData file true "图片文件"
// @Success 200 {object} models.Response{data=object}
// @Failure 400 {object} models.Response
// @Router /api/upload/image [post]
func (h *UploadHandler) UploadImage(c *gin.Context) {
	// 获取上传的文件
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请选择要上传的文件",
		))
		return
	}
	defer file.Close()

	// 检查文件大小
	if header.Size > MaxUploadSize {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"文件大小超过限制（最大10MB）",
		))
		return
	}

	// 检查文件类型
	contentType := header.Header.Get("Content-Type")
	if !allowedImageTypes[contentType] {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"不支持的文件类型，仅支持 JPEG、PNG、GIF、WebP 格式",
		))
		return
	}

	// 获取 MinIO 服务实例
	minioService := services.GetMinIOService()
	if minioService == nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"文件存储服务未初始化",
		))
		return
	}

	// 上传文件到 MinIO
	fileURL, err := minioService.UploadFile(file, header, "images")
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"文件上传失败: "+err.Error(),
		))
		return
	}

	// 返回文件 URL
	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("上传成功", gin.H{
		"url": fileURL,
	}))
}

