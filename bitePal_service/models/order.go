package models

import "gorm.io/gorm"

type Order struct {
	gorm.Model
	TableNumber int         `json:"table_number"`
	Status      string      `json:"status"` // e.g., "pending", "completed", "cancelled"
	TotalPrice  float64     `json:"total_price"`
	Items       []OrderItem `json:"items" gorm:"foreignKey:OrderID"`
}

type OrderItem struct {
	gorm.Model
	OrderID  uint    `json:"order_id"`
	DishID   uint    `json:"dish_id"`
	Dish     Dish    `json:"dish"`
	Quantity int     `json:"quantity"`
	Price    float64 `json:"price"` // Snapshot of price at order time
}
