package service

import (
	"errors"

	"family-chef-backend/internal/dto"
	"family-chef-backend/internal/models"
	"family-chef-backend/internal/repository"

	"gorm.io/gorm"
)

type DictService struct {
	dictRepo *repository.DictRepository
}

func NewDictService() *DictService {
	return &DictService{
		dictRepo: repository.NewDictRepository(),
	}
}

// CreateDictType 创建字典类型
func (s *DictService) CreateDictType(req *dto.SysDictTypeRequest) error {
	dictType := &models.SysDictType{
		Name: req.Name,
		Code: req.Code,
		Sort: req.Sort,
	}
	return s.dictRepo.CreateDictType(dictType)
}

// GetDictTypeList 获取字典类型列表
func (s *DictService) GetDictTypeList(req *dto.SysDictTypeListRequest) ([]dto.SysDictTypeResponse, int64, error) {
	dictTypes, total, err := s.dictRepo.GetDictTypeList(req.Page, req.PageSize, req.Keyword)
	if err != nil {
		return nil, 0, err
	}

	var responses []dto.SysDictTypeResponse
	for _, dictType := range dictTypes {
		responses = append(responses, s.convertDictTypeToResponse(dictType))
	}

	return responses, total, nil
}

// GetDictTypeDetail 获取字典类型详情
func (s *DictService) GetDictTypeDetail(id int64) (*dto.SysDictTypeDetailResponse, error) {
	dictType, err := s.dictRepo.GetDictTypeByID(id)
	if err != nil {
		return nil, err
	}

	dictDatas, err := s.dictRepo.GetDictDataByType(dictType.Code)
	if err != nil {
		return nil, err
	}

	response := &dto.SysDictTypeDetailResponse{
		Type:  s.convertDictTypeToResponse(*dictType),
		Datas: s.convertDictDatasToResponses(dictDatas),
	}

	return response, nil
}

// UpdateDictType 更新字典类型
func (s *DictService) UpdateDictType(req *dto.SysDictTypeUpdateRequest) error {
	dictType, err := s.dictRepo.GetDictTypeByID(req.ID)
	if err != nil {
		return errors.New("字典类型不存在")
	}

	dictType.Name = req.Name
	dictType.Code = req.Code
	dictType.Sort = req.Sort

	return s.dictRepo.UpdateDictType(dictType)
}

// DeleteDictType 删除字典类型
func (s *DictService) DeleteDictType(id int64) error {
	return s.dictRepo.DeleteDictType(id)
}

// CreateDictData 创建字典数据
func (s *DictService) CreateDictData(req *dto.SysDictDataRequest) error {
	dictData := &models.SysDictData{
		SysDictTypeCode: req.DictTypeCode,
		Name:            req.Name,
		Value:           req.Value,
		Sort:            req.Sort,
		ValueEx1:        req.ValueEx1,
		ValueEx2:        req.ValueEx2,
	}
	return s.dictRepo.CreateDictData(dictData)
}

// BatchCreateDictData 批量创建字典数据
func (s *DictService) BatchCreateDictData(req *dto.SysDictDataBatchRequest) error {
	var dictDatas []*models.SysDictData
	for _, data := range req.Datas {
		dictData := &models.SysDictData{
			SysDictTypeCode: data.DictTypeCode,
			Name:            data.Name,
			Value:           data.Value,
			Sort:            data.Sort,
			ValueEx1:        data.ValueEx1,
			ValueEx2:        data.ValueEx2,
		}
		dictDatas = append(dictDatas, dictData)
	}
	return s.dictRepo.BatchCreateDictData(dictDatas)
}

// GetDictDataList 获取字典数据列表
func (s *DictService) GetDictDataList(req *dto.SysDictDataListRequest) ([]dto.SysDictDataResponse, int64, error) {
	dictDatas, total, err := s.dictRepo.GetDictDataList(req.DictTypeCode, req.Page, req.PageSize, req.Keyword)
	if err != nil {
		return nil, 0, err
	}

	var responses []dto.SysDictDataResponse
	for _, dictData := range dictDatas {
		responses = append(responses, s.convertDictDataToResponse(dictData))
	}

	return responses, total, nil
}

// UpdateDictData 更新字典数据
func (s *DictService) UpdateDictData(req *dto.SysDictDataUpdateRequest) error {
	dictData, err := s.dictRepo.GetDictDataByID(req.ID)
	if err != nil {
		return errors.New("字典数据不存在")
	}

	dictData.Name = req.Name
	dictData.Value = req.Value
	dictData.Sort = req.Sort
	dictData.ValueEx1 = req.ValueEx1
	dictData.ValueEx2 = req.ValueEx2

	return s.dictRepo.UpdateDictData(dictData)
}

// DeleteDictData 删除字典数据
func (s *DictService) DeleteDictData(id int64) error {
	return s.dictRepo.DeleteDictData(id)
}

// GetDictDataByType 根据字典类型获取字典数据
func (s *DictService) GetDictDataByType(dictTypeCode string) ([]dto.SysDictDataResponse, error) {
	dictDatas, err := s.dictRepo.GetDictDataByType(dictTypeCode)
	if err != nil {
		return nil, err
	}

	return s.convertDictDatasToResponses(dictDatas), nil
}

// 辅助方法：转换字典类型为响应对象
func (s *DictService) convertDictTypeToResponse(dictType models.SysDictType) dto.SysDictTypeResponse {
	return dto.SysDictTypeResponse{
		ID:            dictType.ID,
		Name:          dictType.Name,
		Code:          dictType.Code,
		Sort:          dictType.Sort,
		CreatedAt:     dictType.CreatedAt,
		UpdatedAt:     dictType.UpdatedAt,
		CreatedBy:     dictType.CreatedBy,
		UpdatedBy:     dictType.UpdatedBy,
		CreatedByName: "", // 可以根据需要查询用户名称
		UpdatedByName: "", // 可以根据需要查询用户名称
	}
}

// 辅助方法：转换字典数据为响应对象
func (s *DictService) convertDictDataToResponse(dictData models.SysDictData) dto.SysDictDataResponse {
	return dto.SysDictDataResponse{
		ID:              dictData.ID,
		SysDictTypeCode: dictData.SysDictTypeCode,
		Name:            dictData.Name,
		Value:           dictData.Value,
		ValueEx1:        dictData.ValueEx1,
		ValueEx2:        dictData.ValueEx2,
		Sort:            dictData.Sort,
		CreatedAt:       dictData.CreatedAt,
		UpdatedAt:       dictData.UpdatedAt,
		CreatedBy:       dictData.CreatedBy,
		UpdatedBy:       dictData.UpdatedBy,
		CreatedByName:   "", // 可以根据需要查询用户名称
		UpdatedByName:   "", // 可以根据需要查询用户名称
	}
}

// 辅助方法：批量转换字典数据为响应对象
func (s *DictService) convertDictDatasToResponses(dictDatas []models.SysDictData) []dto.SysDictDataResponse {
	var responses []dto.SysDictDataResponse
	for _, dictData := range dictDatas {
		responses = append(responses, s.convertDictDataToResponse(dictData))
	}
	return responses
}
