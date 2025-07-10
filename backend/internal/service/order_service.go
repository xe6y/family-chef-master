package service

import (
	"family-chef-backend/internal/database"
	"family-chef-backend/internal/models"
)

// OrderService 订单服务
type OrderService struct{}

// NewOrderService 创建订单服务实例
func NewOrderService() *OrderService {
	return &OrderService{}
}

// CreateOrder 创建订单
func (s *OrderService) CreateOrder(order *models.Order) error {
	return database.DB.Create(order).Error
}

// GetOrders 获取订单列表
func (s *OrderService) GetOrders(familyID int64, page, pageSize int) ([]models.Order, int64, error) {
	var orders []models.Order
	var total int64

	// 获取总数
	if err := database.DB.Model(&models.Order{}).Where("family_id = ?", familyID).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := database.DB.Where("family_id = ?", familyID).
		Order("create_time DESC").
		Offset(offset).Limit(pageSize).Find(&orders).Error; err != nil {
		return nil, 0, err
	}

	return orders, total, nil
}
