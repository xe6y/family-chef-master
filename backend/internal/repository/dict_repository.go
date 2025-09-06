package repository

import (
	"errors"

	"family-chef-backend/internal/database"
	"family-chef-backend/internal/models"

	"gorm.io/gorm"
)

type DictRepository struct{}

func NewDictRepository() *DictRepository {
	return &DictRepository{}
}

// CreateDictType 创建字典类型
func (r *DictRepository) CreateDictType(dictType *models.SysDictType) error {
	// 检查字典类型代码是否已存在
	var existingType models.SysDictType
	if err := database.DB.Where("code = ?", dictType.Code).First(&existingType).Error; err == nil {
		return errors.New("字典类型代码已存在")
	}
	return database.DB.Create(dictType).Error
}

// GetDictTypeByID 根据ID获取字典类型
func (r *DictRepository) GetDictTypeByID(id int64) (*models.SysDictType, error) {
	var dictType models.SysDictType
	if err := database.DB.First(&dictType, id).Error; err != nil {
		return nil, err
	}
	return &dictType, nil
}

// GetDictTypeByCode 根据代码获取字典类型
func (r *DictRepository) GetDictTypeByCode(code string) (*models.SysDictType, error) {
	var dictType models.SysDictType
	if err := database.DB.Where("code = ?", code).First(&dictType).Error; err != nil {
		return nil, err
	}
	return &dictType, nil
}

// GetDictTypeList 获取字典类型列表
func (r *DictRepository) GetDictTypeList(page, pageSize int, keyword string) ([]models.SysDictType, int64, error) {
	var dictTypes []models.SysDictType
	var total int64

	query := database.DB.Model(&models.SysDictType{})
	if keyword != "" {
		query = query.Where("name LIKE ? OR code LIKE ?", "%"+keyword+"%", "%"+keyword+"%")
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	if err := query.Offset(offset).Limit(pageSize).Order("sort ASC, id DESC").Find(&dictTypes).Error; err != nil {
		return nil, 0, err
	}

	return dictTypes, total, nil
}

// UpdateDictType 更新字典类型
func (r *DictRepository) UpdateDictType(dictType *models.SysDictType) error {
	// 检查字典类型代码是否已存在（排除当前记录）
	var existingType models.SysDictType
	if err := database.DB.Where("code = ? AND id != ?", dictType.Code, dictType.ID).First(&existingType).Error; err == nil {
		return errors.New("字典类型代码已存在")
	}
	return database.DB.Save(dictType).Error
}

// DeleteDictType 删除字典类型
func (r *DictRepository) DeleteDictType(id int64) error {
	return database.DB.Transaction(func(tx *gorm.DB) error {
		// 删除字典类型
		if err := tx.Delete(&models.SysDictType{}, id).Error; err != nil {
			return err
		}
		// 删除相关字典数据
		return tx.Where("dict_type = (SELECT code FROM sys_dict_type WHERE id = ?)", id).Delete(&models.SysDictData{}).Error
	})
}

// CreateDictData 创建字典数据
func (r *DictRepository) CreateDictData(dictData *models.SysDictData) error {
	// 检查字典类型是否存在
	var dictType models.SysDictType
	if err := database.DB.Where("code = ?", dictData.SysDictTypeCode).First(&dictType).Error; err != nil {
		return errors.New("字典类型不存在")
	}
	return database.DB.Create(dictData).Error
}

// GetDictDataByID 根据ID获取字典数据
func (r *DictRepository) GetDictDataByID(id int64) (*models.SysDictData, error) {
	var dictData models.SysDictData
	if err := database.DB.First(&dictData, id).Error; err != nil {
		return nil, err
	}
	return &dictData, nil
}

// GetDictDataList 获取字典数据列表
func (r *DictRepository) GetDictDataList(dictTypeCode string, page, pageSize int, keyword string) ([]models.SysDictData, int64, error) {
	var dictDatas []models.SysDictData
	var total int64

	query := database.DB.Model(&models.SysDictData{}).Where("dict_type = ?", dictTypeCode)
	if keyword != "" {
		query = query.Where("name LIKE ? OR code LIKE ?", "%"+keyword+"%", "%"+keyword+"%")
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	if err := query.Offset(offset).Limit(pageSize).Order("sort ASC, id DESC").Find(&dictDatas).Error; err != nil {
		return nil, 0, err
	}

	return dictDatas, total, nil
}

// GetDictDataByType 根据字典类型获取所有字典数据
func (r *DictRepository) GetDictDataByType(dictTypeCode string) ([]models.SysDictData, error) {
	var dictDatas []models.SysDictData
	if err := database.DB.Where("dict_type = ?", dictTypeCode).Order("sort ASC, id DESC").Find(&dictDatas).Error; err != nil {
		return nil, err
	}
	return dictDatas, nil
}

// UpdateDictData 更新字典数据
func (r *DictRepository) UpdateDictData(dictData *models.SysDictData) error {
	return database.DB.Save(dictData).Error
}

// DeleteDictData 删除字典数据
func (r *DictRepository) DeleteDictData(id int64) error {
	return database.DB.Delete(&models.SysDictData{}, id).Error
}

// BatchCreateDictData 批量创建字典数据
func (r *DictRepository) BatchCreateDictData(dictDatas []*models.SysDictData) error {
	return database.DB.Transaction(func(tx *gorm.DB) error {
		for _, dictData := range dictDatas {
			// 检查字典类型是否存在
			var dictType models.SysDictType
			if err := tx.Where("code = ?", dictData.SysDictTypeCode).First(&dictType).Error; err != nil {
				return errors.New("字典类型不存在: " + dictData.SysDictTypeCode)
			}
			if err := tx.Create(dictData).Error; err != nil {
				return err
			}
		}
		return nil
	})
}
