package handlers

import (
	"family-chef-backend/config"
	"family-chef-backend/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

func GetIngredients(c *gin.Context) {
	var ingredients []models.Ingredient
	config.DB.Find(&ingredients)
	c.JSON(http.StatusOK, gin.H{"data": ingredients})
}

func AddIngredient(c *gin.Context) {
	var input models.Ingredient
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ingredient := models.Ingredient{Name: input.Name, Stock: input.Stock, Unit: input.Unit}
	config.DB.Create(&ingredient)

	c.JSON(http.StatusOK, gin.H{"data": ingredient})
}

func UpdateIngredient(c *gin.Context) {
	var ingredient models.Ingredient
	if err := config.DB.Where("id = ?", c.Param("id")).First(&ingredient).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Ingredient not found!"})
		return
	}

	var input models.Ingredient
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	config.DB.Model(&ingredient).Updates(input)

	c.JSON(http.StatusOK, gin.H{"data": ingredient})
}

func DeleteIngredient(c *gin.Context) {
	var ingredient models.Ingredient
	if err := config.DB.Where("id = ?", c.Param("id")).First(&ingredient).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Ingredient not found!"})
		return
	}

	config.DB.Delete(&ingredient)

	c.JSON(http.StatusOK, gin.H{"data": true})
}
