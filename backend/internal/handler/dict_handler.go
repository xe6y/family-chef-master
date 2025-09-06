package handler

import (
	"net/http"
	"strconv"

	"family-chef-backend/internal/dto"
	"family-chef-backend/internal/service"

	"github.com/gin-gonic/gin"
)

type DictHandler struct {
	dictService *service.DictService
}

func NewDictHandler() *DictHandler {
	return &DictHandler{
		dictService: service.NewDictService(),
	}
}

// CreateDictType 创建字典类型
func (h *DictHandler) CreateDictType(c *gin.Context) {
	var req dto.SysDictTypeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	if err := h.dictService.CreateDictType(&req); err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "创建字典类型失败: "+err.Error()))
		return
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(gin.H{
		"message": "创建成功",
	}))
}

// GetDictTypeList 获取字典类型列表
func (h *DictHandler) GetDictTypeList(c *gin.Context) {
	var req dto.SysDictTypeListRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	if req.Page <= 0 {
		req.Page = 1
	}
	if req.PageSize <= 0 {
		req.PageSize = 10
	}

	list, total, err := h.dictService.GetDictTypeList(&req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "获取字典类型列表失败: "+err.Error()))
		return
	}

	response := dto.SysDictTypeListResponse{
		List:  list,
		Total: total,
		Page:  req.Page,
		Size:  req.PageSize,
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(response))
}

// GetDictTypeDetail 获取字典类型详情
func (h *DictHandler) GetDictTypeDetail(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "无效的字典类型ID"))
		return
	}

	detail, err := h.dictService.GetDictTypeDetail(id)
	if err != nil {
		c.JSON(http.StatusNotFound, dto.ErrorResponse(404, "字典类型不存在"))
		return
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(detail))
}

// UpdateDictType 更新字典类型
func (h *DictHandler) UpdateDictType(c *gin.Context) {
	var req dto.SysDictTypeUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	if err := h.dictService.UpdateDictType(&req); err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "更新字典类型失败: "+err.Error()))
		return
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(gin.H{
		"message": "更新成功",
	}))
}

// DeleteDictType 删除字典类型
func (h *DictHandler) DeleteDictType(c *gin.Context) {
	var req dto.SysDictTypeDeleteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	if err := h.dictService.DeleteDictType(req.ID); err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "删除字典类型失败: "+err.Error()))
		return
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(gin.H{
		"message": "删除成功",
	}))
}

// CreateDictData 创建字典数据
func (h *DictHandler) CreateDictData(c *gin.Context) {
	var req dto.SysDictDataRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	if err := h.dictService.CreateDictData(&req); err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "创建字典数据失败: "+err.Error()))
		return
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(gin.H{
		"message": "创建成功",
	}))
}

// BatchCreateDictData 批量创建字典数据
func (h *DictHandler) BatchCreateDictData(c *gin.Context) {
	var req dto.SysDictDataBatchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	if err := h.dictService.BatchCreateDictData(&req); err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "批量创建字典数据失败: "+err.Error()))
		return
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(gin.H{
		"message": "批量创建成功",
	}))
}

// GetDictDataList 获取字典数据列表
func (h *DictHandler) GetDictDataList(c *gin.Context) {
	var req dto.SysDictDataListRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	if req.Page <= 0 {
		req.Page = 1
	}
	if req.PageSize <= 0 {
		req.PageSize = 10
	}

	list, total, err := h.dictService.GetDictDataList(&req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "获取字典数据列表失败: "+err.Error()))
		return
	}

	response := dto.SysDictDataListResponse{
		List:  list,
		Total: total,
		Page:  req.Page,
		Size:  req.PageSize,
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(response))
}

// UpdateDictData 更新字典数据
func (h *DictHandler) UpdateDictData(c *gin.Context) {
	var req dto.SysDictDataUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	if err := h.dictService.UpdateDictData(&req); err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "更新字典数据失败: "+err.Error()))
		return
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(gin.H{
		"message": "更新成功",
	}))
}

// DeleteDictData 删除字典数据
func (h *DictHandler) DeleteDictData(c *gin.Context) {
	var req dto.SysDictDataDeleteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "参数错误: "+err.Error()))
		return
	}

	if err := h.dictService.DeleteDictData(req.ID); err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "删除字典数据失败: "+err.Error()))
		return
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(gin.H{
		"message": "删除成功",
	}))
}

// GetDictDataByType 根据字典类型获取字典数据
func (h *DictHandler) GetDictDataByType(c *gin.Context) {
	dictTypeCode := c.Param("dictTypeCode")
	if dictTypeCode == "" {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse(400, "字典类型代码不能为空"))
		return
	}

	data, err := h.dictService.GetDictDataByType(dictTypeCode)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse(500, "获取字典数据失败: "+err.Error()))
		return
	}

	c.JSON(http.StatusOK, dto.SuccessResponse(data))
}
