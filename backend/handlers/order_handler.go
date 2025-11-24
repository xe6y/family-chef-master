package handlers

import (
	"family-chef-backend/config"
	"family-chef-backend/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

type CreateOrderInput struct {
	TableNumber int `json:"table_number" binding:"required"`
	Items       []struct {
		DishID   uint `json:"dish_id" binding:"required"`
		Quantity int  `json:"quantity" binding:"required"`
	} `json:"items" binding:"required"`
}

func CreateOrder(c *gin.Context) {
	var input CreateOrderInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Calculate total price and prepare items
	var totalPrice float64
	var orderItems []models.OrderItem

	for _, item := range input.Items {
		var dish models.Dish
		if err := config.DB.First(&dish, item.DishID).Error; err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Dish not found"})
			return
		}
		price := dish.Price * float64(item.Quantity)
		totalPrice += price
		orderItems = append(orderItems, models.OrderItem{
			DishID:   item.DishID,
			Quantity: item.Quantity,
			Price:    dish.Price,
		})
	}

	order := models.Order{
		TableNumber: input.TableNumber,
		Status:      "pending",
		TotalPrice:  totalPrice,
		Items:       orderItems,
	}

	config.DB.Create(&order)

	c.JSON(http.StatusOK, gin.H{"data": order})
}

func GetOrders(c *gin.Context) {
	var orders []models.Order
	config.DB.Preload("Items").Preload("Items.Dish").Find(&orders)
	c.JSON(http.StatusOK, gin.H{"data": orders})
}
