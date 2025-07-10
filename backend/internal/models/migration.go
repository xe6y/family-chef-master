package models

import (
	"log"

	"gorm.io/gorm"
)

// AutoMigrate 自动迁移所有表结构
func AutoMigrate(db *gorm.DB) error {
	log.Println("开始数据库迁移...")

	models := GetAllModels()

	for _, model := range models {
		if err := db.AutoMigrate(model); err != nil {
			log.Printf("迁移模型失败: %v", err)
			return err
		}
	}

	log.Println("数据库迁移完成")
	return nil
}

// CreateTables 手动创建表（如果需要更精细的控制）
func CreateTables(db *gorm.DB) error {
	log.Println("开始创建数据库表...")

	// 按依赖顺序创建表
	tables := []interface{}{
		&SystemUser{},      // 用户表
		&SystemFamily{},    // 家庭表
		&MenuPublic{},      // 公共菜谱表
		&MenuFamily{},      // 家庭菜谱表
		&MenuTutorial{},    // 菜谱教程表
		&MenuTag{},         // 菜谱标签表
		&MenuTagRelation{}, // 菜谱标签关联表
		&Order{},           // 点餐表
		&OrderDetail{},     // 点餐明细表
	}

	for _, table := range tables {
		if err := db.AutoMigrate(table); err != nil {
			log.Printf("创建表失败: %v", err)
			return err
		}
	}

	log.Println("数据库表创建完成")
	return nil
}
