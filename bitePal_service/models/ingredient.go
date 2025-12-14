package models

import "gorm.io/gorm"

type Ingredient struct {
	gorm.Model
	Name  string  `json:"name"`
	Stock float64 `json:"stock"`
	Unit  string  `json:"unit"`
}
