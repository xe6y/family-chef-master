package config

import (
	"log"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDatabase() {
	database, err := gorm.Open(sqlite.Open("family_chef.db"), &gorm.Config{})

	if err != nil {
		log.Fatal("Failed to connect to database!", err)
	}

	DB = database
}
