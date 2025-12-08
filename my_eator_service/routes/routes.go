package routes

import (
	"family-chef-backend/handlers"

	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()

	// Menu Routes
	r.GET("/menu", handlers.GetMenu)
	r.POST("/menu", handlers.CreateDish)
	r.PUT("/menu/:id", handlers.UpdateDish)
	r.DELETE("/menu/:id", handlers.DeleteDish)

	// Ingredient Routes
	r.GET("/ingredients", handlers.GetIngredients)
	r.POST("/ingredients", handlers.AddIngredient)
	r.PUT("/ingredients/:id", handlers.UpdateIngredient)
	r.DELETE("/ingredients/:id", handlers.DeleteIngredient)

	// Order Routes
	r.POST("/orders", handlers.CreateOrder)
	r.GET("/orders", handlers.GetOrders)

	return r
}
