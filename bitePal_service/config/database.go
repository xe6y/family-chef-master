package config

import (
	"fmt"
	"log"

	. "bitePal_service/models"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// DB 全局数据库实例
var DB *gorm.DB

// InitDB 初始化数据库连接
// cfg: 应用配置
// 返回: 错误信息
func InitDB(cfg *Config) error {
	var err error

	// 配置GORM日志
	gormConfig := &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	}

	// 构建 MariaDB/MySQL DSN (Data Source Name)
	// 格式: username:password@tcp(host:port)/dbname?charset=utf8mb4&parseTime=True&loc=Local
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		cfg.DBUser,
		cfg.DBPassword,
		cfg.DBHost,
		cfg.DBPort,
		cfg.DBName,
	)

	// 连接 MariaDB 数据库
	DB, err = gorm.Open(mysql.Open(dsn), gormConfig)
	if err != nil {
		log.Printf("数据库连接失败: %v", err)
		return err
	}

	log.Printf("数据库连接成功: %s@%s:%s/%s", cfg.DBUser, cfg.DBHost, cfg.DBPort, cfg.DBName)

	// 自动迁移数据库表结构
	if err := autoMigrate(); err != nil {
		log.Printf("数据库迁移失败: %v", err)
		return err
	}

	return nil
}

// autoMigrate 自动迁移数据库表
// 返回: 错误信息
func autoMigrate() error {
	// 导入models包中的所有模型进行迁移
	err := DB.AutoMigrate(
		&User{},
		&Recipe{},
		&UserFavorite{},
		&RecipeCategory{},
		&IngredientCategory{},
		&IngredientItem{},
		&ShoppingList{},
		&TodayMenu{},
		&MealOrder{},
		&UserStats{},
		&FamilyMember{},
		&Family{},
		&FamilyMemberInfo{},
		&StorageLocation{},
	)
	if err != nil {
		return err
	}

	// 初始化默认食材分类
	initDefaultCategories()

	// 初始化默认菜谱分类
	initDefaultRecipeCategories()

	return nil
}

// initDefaultCategories 初始化默认食材分类
func initDefaultCategories() {
	defaultCategories := GetDefaultCategories()
	for _, cat := range defaultCategories {
		// 检查是否已存在，不存在则创建
		var existing IngredientCategory
		if result := DB.Where("id = ?", cat.ID).First(&existing); result.Error != nil {
			DB.Create(cat)
			log.Printf("创建默认食材分类: %s", cat.Name)
		}
	}
}

// initDefaultRecipeCategories 初始化默认菜谱分类
func initDefaultRecipeCategories() {
	log.Println("初始化默认菜谱分类...")

	defaultCategories := []RecipeCategory{
		// 口味分类
		{ID: "taste-001", Type: CategoryTypeTaste, Name: "清淡", Color: "#E8F5E9", SortOrder: 1, IsActive: true},
		{ID: "taste-002", Type: CategoryTypeTaste, Name: "咸鲜", Color: "#FFF3E0", SortOrder: 2, IsActive: true},
		{ID: "taste-003", Type: CategoryTypeTaste, Name: "酸", Color: "#FFF9C4", SortOrder: 3, IsActive: true},
		{ID: "taste-004", Type: CategoryTypeTaste, Name: "甜", Color: "#FCE4EC", SortOrder: 4, IsActive: true},
		{ID: "taste-005", Type: CategoryTypeTaste, Name: "麻", Color: "#FFEBEE", SortOrder: 5, IsActive: true},
		{ID: "taste-006", Type: CategoryTypeTaste, Name: "辣", Color: "#FFCDD2", SortOrder: 6, IsActive: true},

		// 菜系分类
		{ID: "cuisine-001", Type: CategoryTypeCuisine, Name: "家常菜", Color: "#E3F2FD", SortOrder: 1, IsActive: true},
		{ID: "cuisine-002", Type: CategoryTypeCuisine, Name: "川菜", Color: "#FFEBEE", SortOrder: 2, IsActive: true},
		{ID: "cuisine-003", Type: CategoryTypeCuisine, Name: "粤菜", Color: "#E8F5E9", SortOrder: 3, IsActive: true},
		{ID: "cuisine-004", Type: CategoryTypeCuisine, Name: "浙菜", Color: "#F3E5F5", SortOrder: 4, IsActive: true},
		{ID: "cuisine-005", Type: CategoryTypeCuisine, Name: "湘菜", Color: "#FFF3E0", SortOrder: 5, IsActive: true},
		{ID: "cuisine-006", Type: CategoryTypeCuisine, Name: "鲁菜", Color: "#E0F2F1", SortOrder: 6, IsActive: true},

		// 难度分类（通常固定）
		{ID: "difficulty-001", Type: CategoryTypeDifficulty, Name: "有手就行", Color: "#E8F5E9", SortOrder: 1, IsActive: true},
		{ID: "difficulty-002", Type: CategoryTypeDifficulty, Name: "家常便饭", Color: "#E3F2FD", SortOrder: 2, IsActive: true},
		{ID: "difficulty-003", Type: CategoryTypeDifficulty, Name: "餐厅招牌", Color: "#FFFDE7", SortOrder: 3, IsActive: true},
		{ID: "difficulty-004", Type: CategoryTypeDifficulty, Name: "硬核挑战", Color: "#FFF3E0", SortOrder: 4, IsActive: true},
		{ID: "difficulty-005", Type: CategoryTypeDifficulty, Name: "专业厨师", Color: "#FFEBEE", SortOrder: 5, IsActive: true},

		// 餐点类型分类
		{ID: "meal-001", Type: CategoryTypeMealType, Name: "早餐", Color: "#FFF9C4", SortOrder: 1, IsActive: true},
		{ID: "meal-002", Type: CategoryTypeMealType, Name: "午餐", Color: "#FFECB3", SortOrder: 2, IsActive: true},
		{ID: "meal-003", Type: CategoryTypeMealType, Name: "晚餐", Color: "#FFE0B2", SortOrder: 3, IsActive: true},
		{ID: "meal-004", Type: CategoryTypeMealType, Name: "夜宵", Color: "#E1BEE7", SortOrder: 4, IsActive: true},
	}

	for _, cat := range defaultCategories {
		// 检查是否已存在，不存在则创建
		var existing RecipeCategory
		if result := DB.Where("id = ?", cat.ID).First(&existing); result.Error != nil {
			DB.Create(&cat)
			log.Printf("创建默认菜谱分类: %s - %s", cat.Type, cat.Name)
		}
	}
}

// GetDB 获取数据库实例
// 返回: 数据库实例
func GetDB() *gorm.DB {
	return DB
}
