package main

import (
	"family-chef-backend/config"
	"family-chef-backend/models"
	"family-chef-backend/routes"
)

func main() {
	// Connect to database
	config.ConnectDatabase()

	// Migrate the schema
	config.DB.AutoMigrate(&models.Dish{}, &models.Ingredient{}, &models.Order{}, &models.OrderItem{})

	// Setup router
	r := routes.SetupRouter()

	// Run server
	r.Run(":8080")
}
