package main

import (
	"fmt"
	"log"
	"os"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

func main() {
	// 获取数据库配置（使用默认值）
	dbHost := getEnv("DB_HOST", "127.0.0.1")
	dbPort := getEnv("DB_PORT", "3306")
	dbName := getEnv("DB_NAME", "zuoban")
	dbUser := getEnv("DB_USER", "zuoban")
	dbPassword := getEnv("DB_PASSWORD", "develop")

	// 构建 DSN
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		dbUser, dbPassword, dbHost, dbPort, dbName)

	// 连接数据库
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("连接数据库失败: %v", err)
	}

	log.Println("开始执行数据库迁移...")

	// 执行 SQL 修改字段长度
	sql := "ALTER TABLE `ingredient_items` MODIFY COLUMN `storage` VARCHAR(36)"
	if err := db.Exec(sql).Error; err != nil {
		log.Fatalf("执行迁移失败: %v", err)
	}

	log.Println("✅ 数据库迁移成功！storage 字段已从 VARCHAR(20) 修改为 VARCHAR(36)")
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
