package handlers

import (
	"family-chef-backend/config"
	"family-chef-backend/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

func GetMenu(c *gin.Context) {
	var dishes []models.Dish
	config.DB.Find(&dishes)
	c.JSON(http.StatusOK, gin.H{"data": dishes})
}

func CreateDish(c *gin.Context) {
	var input models.Dish
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	dish := models.Dish{Name: input.Name, Description: input.Description, Price: input.Price, ImageURL: input.ImageURL}
	config.DB.Create(&dish)

	c.JSON(http.StatusOK, gin.H{"data": dish})
}

func UpdateDish(c *gin.Context) {
	var dish models.Dish
	if err := config.DB.Where("id = ?", c.Param("id")).First(&dish).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dish not found!"})
		return
	}

	var input models.Dish
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	config.DB.Model(&dish).Updates(input)

	c.JSON(http.StatusOK, gin.H{"data": dish})
}

func DeleteDish(c *gin.Context) {
	var dish models.Dish
	if err := config.DB.Where("id = ?", c.Param("id")).First(&dish).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dish not found!"})
		return
	}

	config.DB.Delete(&dish)

	c.JSON(http.StatusOK, gin.H{"data": true})
}
