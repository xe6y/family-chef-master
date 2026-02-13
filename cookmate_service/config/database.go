package config

import (
	"fmt"
	"log"

	. "bitePal_service/models"

	"gorm.io/driver/postgres"
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
		Logger: logger.Default.LogMode(logger.Warn),
	}

	// 构建 PostgreSQL DSN (Data Source Name)
	// 格式: host=localhost user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=Asia/Shanghai",
		cfg.DBHost,
		cfg.DBUser,
		cfg.DBPassword,
		cfg.DBName,
		cfg.DBPort,
	)

	// 连接 PostgreSQL 数据库
	DB, err = gorm.Open(postgres.Open(dsn), gormConfig)
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
		&Unit{},
		&IngredientMaster{},
		&IngredientUnit{},
		&Recipe{},
		&MyRecipe{},
		&PublicRecipe{},
		&UserFavorite{},
		&RecipeCategory{},
		&IngredientCategory{},
		&IngredientItem{},
		&ShoppingList{},
		&MealOrder{},
		&UserStats{},
		&FamilyMember{},
		&Family{},
		&FamilyMemberInfo{},
		&StorageLocation{},
		&UserTag{},
		&MenuCache{},
	)
	if err != nil {
		return err
	}

	// 初始化默认食材分类
	initDefaultCategories()

	// 初始化默认菜谱分类
	initDefaultRecipeCategories()

	// 单位与食材库种子（单位统一化）
	seedUnits()
	seedIngredientMaster()
	seedIngredientUnits()

	// 填充模拟菜谱数据
	seedRecipes()

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

// seedUnits 填充单位表
func seedUnits() {
	units := []Unit{
		{ID: "g", DisplayName: "克", UnitType: UnitTypeWeight, SortOrder: 1},
		{ID: "kg", DisplayName: "千克", UnitType: UnitTypeWeight, SortOrder: 2},
		{ID: "pcs", DisplayName: "个", UnitType: UnitTypeCount, SortOrder: 10},
		{ID: "ml", DisplayName: "毫升", UnitType: UnitTypeVolume, SortOrder: 20},
		{ID: "tbsp", DisplayName: "勺", UnitType: UnitTypeVolume, SortOrder: 21},
		{ID: "suitable", DisplayName: "适量", UnitType: UnitTypeUnspecified, SortOrder: 99},
		{ID: "只", DisplayName: "只", UnitType: UnitTypeCount, SortOrder: 11},
		{ID: "根", DisplayName: "根", UnitType: UnitTypeCount, SortOrder: 12},
		{ID: "片", DisplayName: "片", UnitType: UnitTypeCount, SortOrder: 13},
		{ID: "瓣", DisplayName: "瓣", UnitType: UnitTypeCount, SortOrder: 14},
		{ID: "罐", DisplayName: "罐", UnitType: UnitTypeCount, SortOrder: 15},
		{ID: "碗", DisplayName: "碗", UnitType: UnitTypeCount, SortOrder: 16},
		{ID: "颗", DisplayName: "颗", UnitType: UnitTypeCount, SortOrder: 17},
	}
	for _, u := range units {
		var exist Unit
		if DB.Where("id = ?", u.ID).First(&exist).Error != nil {
			DB.Create(&u)
			log.Printf("创建单位: %s", u.DisplayName)
		}
	}
}

// 食材库种子用固定 ID，供菜谱引用
const (
	seedID鸡胸肉 = "master-jiarou"
	seedID花生米 = "master-huasheng"
	seedID鸡蛋  = "master-jidan"
	seedID番茄  = "master-fanqie"
	seedID葱   = "master-cong"
	seedID盐   = "master-yan"
	seedID糖   = "master-tang"
	seedID油   = "master-you"
	seedID其他  = "master-other"
)

// seedIngredientMaster 填充食材库
func seedIngredientMaster() {
	masters := []IngredientMaster{
		{ID: seedID鸡胸肉, Name: "鸡胸肉", CategoryID: "cat_meat", BaseUnitID: "g", CaloriesPer100: 133, ProteinPer100: 31, FatPer100: 1.2, CarbPer100: 0, SortOrder: 1},
		{ID: seedID花生米, Name: "花生米", CategoryID: "cat_other", BaseUnitID: "g", CaloriesPer100: 567, ProteinPer100: 26, FatPer100: 49, CarbPer100: 16, SortOrder: 2},
		{ID: seedID鸡蛋, Name: "鸡蛋", CategoryID: "cat_egg", BaseUnitID: "g", CaloriesPer100: 155, ProteinPer100: 13, FatPer100: 11, CarbPer100: 1.1, SortOrder: 3},
		{ID: seedID番茄, Name: "番茄", CategoryID: "cat_vegetable", BaseUnitID: "g", CaloriesPer100: 18, ProteinPer100: 0.9, FatPer100: 0.2, CarbPer100: 3.9, SortOrder: 4},
		{ID: seedID葱, Name: "葱", CategoryID: "cat_vegetable", BaseUnitID: "g", CaloriesPer100: 32, ProteinPer100: 1.8, FatPer100: 0.1, CarbPer100: 7.3, SortOrder: 5},
		{ID: seedID盐, Name: "盐", CategoryID: "cat_seasoning", BaseUnitID: "g", CaloriesPer100: 0, ProteinPer100: 0, FatPer100: 0, CarbPer100: 0, SortOrder: 6},
		{ID: seedID糖, Name: "糖", CategoryID: "cat_seasoning", BaseUnitID: "g", CaloriesPer100: 387, ProteinPer100: 0, FatPer100: 0, CarbPer100: 100, SortOrder: 7},
		{ID: seedID油, Name: "油", CategoryID: "cat_seasoning", BaseUnitID: "g", CaloriesPer100: 884, ProteinPer100: 0, FatPer100: 100, CarbPer100: 0, SortOrder: 8},
		{ID: seedID其他, Name: "其他", CategoryID: "cat_other", BaseUnitID: "g", CaloriesPer100: 0, ProteinPer100: 0, FatPer100: 0, CarbPer100: 0, SortOrder: 99},
	}
	for _, m := range masters {
		var exist IngredientMaster
		if DB.Where("id = ?", m.ID).First(&exist).Error != nil {
			DB.Create(&m)
			log.Printf("创建食材库: %s", m.Name)
		}
	}
}

// seedIngredientUnits 填充食材-单位换算
func seedIngredientUnits() {
	// 通用：克=1
	ingredientsWithG := []string{seedID鸡胸肉, seedID花生米, seedID鸡蛋, seedID番茄, seedID葱, seedID盐, seedID糖, seedID油}
	for _, ingID := range ingredientsWithG {
		var exist IngredientUnit
		if DB.Where("ingredient_id = ? AND unit_id = ?", ingID, "g").First(&exist).Error != nil {
			DB.Create(&IngredientUnit{IngredientID: ingID, UnitID: "g", FactorToBase: 1, SortOrder: 1})
		}
	}
	// 鸡蛋：个≈50g
	var exist IngredientUnit
	if DB.Where("ingredient_id = ? AND unit_id = ?", seedID鸡蛋, "pcs").First(&exist).Error != nil {
		DB.Create(&IngredientUnit{IngredientID: seedID鸡蛋, UnitID: "pcs", FactorToBase: 50, SortOrder: 2})
	}
	// 番茄：个≈150g
	if DB.Where("ingredient_id = ? AND unit_id = ?", seedID番茄, "pcs").First(&exist).Error != nil {
		DB.Create(&IngredientUnit{IngredientID: seedID番茄, UnitID: "pcs", FactorToBase: 150, SortOrder: 2})
	}
	// 葱：根≈20g
	if DB.Where("ingredient_id = ? AND unit_id = ?", seedID葱, "根").First(&exist).Error != nil {
		DB.Create(&IngredientUnit{IngredientID: seedID葱, UnitID: "根", FactorToBase: 20, SortOrder: 2})
	}
	// 盐/油：适量
	for _, ingID := range []string{seedID盐, seedID油} {
		if DB.Where("ingredient_id = ? AND unit_id = ?", ingID, "suitable").First(&exist).Error != nil {
			DB.Create(&IngredientUnit{IngredientID: ingID, UnitID: "suitable", FactorToBase: 0, SortOrder: 10})
		}
	}
	// 糖：勺≈15g
	if DB.Where("ingredient_id = ? AND unit_id = ?", seedID糖, "tbsp").First(&exist).Error != nil {
		DB.Create(&IngredientUnit{IngredientID: seedID糖, UnitID: "tbsp", FactorToBase: 15, SortOrder: 2})
	}
	if DB.Where("ingredient_id = ? AND unit_id = ?", seedID其他, "suitable").First(&exist).Error != nil {
		DB.Create(&IngredientUnit{IngredientID: seedID其他, UnitID: "suitable", FactorToBase: 0, SortOrder: 1})
	}
}

// seedRecipes 填充模拟菜谱数据
func seedRecipes() {
	log.Println("开始填充模拟菜谱数据...")

	// 检查是否已有数据
	var count int64
	DB.Model(&PublicRecipe{}).Count(&count)
	if count > 0 {
		log.Println("公开菜谱表已有数据，跳过填充")
		return
	}

	q300 := 300.0
	q50 := 50.0
	q2 := 2.0
	q1 := 1.0
	q3 := 3.0

	// 模拟菜谱数据（单位统一化：ingredientId + quantity + unitId）
	recipes := []PublicRecipe{
		{
			Name:       "宫保鸡丁",
			Image:      "",
			Time:       "30分钟",
			Difficulty: "家常便饭",
			Tags:       StringArray{"下饭菜", "经典川菜", "快手菜"},
			TagColors:  StringArray{"#FF6B6B", "#4ECDC4", "#45B7D1"},
			Categories: StringArray{"川菜", "咸鲜", "午餐", "晚餐"},
			Ingredients: RecipeIngredients{
				{IngredientID: seedID鸡胸肉, Quantity: &q300, UnitID: "g"},
				{IngredientID: seedID花生米, Quantity: &q50, UnitID: "g"},
				{IngredientID: seedID葱, Quantity: &q2, UnitID: "根"},
				{IngredientID: seedID盐, Quantity: nil, UnitID: "suitable"},
				{IngredientID: seedID糖, Quantity: &q1, UnitID: "tbsp"},
				{IngredientID: seedID油, Quantity: nil, UnitID: "suitable"},
			},
			Steps: StringArray{
				"鸡胸肉切丁，用料酒、生抽、盐腌制15分钟",
				"花生米用油炸至金黄，捞出备用",
				"热锅下油，放入干辣椒和花椒爆香",
				"加入鸡丁翻炒至变色",
				"加入葱姜蒜继续翻炒",
				"调入生抽、老抽、糖、醋调味",
				"最后加入花生米翻炒均匀即可",
			},
			Source: "系统默认",
		},
		{
			Name:       "番茄鸡蛋",
			Image:      "",
			Time:       "15分钟",
			Difficulty: "有手就行",
			Tags:       StringArray{"家常菜", "快手菜", "下饭菜"},
			TagColors:  StringArray{"#FF6B6B", "#4ECDC4", "#95E1D3"},
			Categories: StringArray{"家常菜", "清淡", "午餐", "晚餐"},
			Ingredients: RecipeIngredients{
				{IngredientID: seedID鸡蛋, Quantity: &q3, UnitID: "pcs"},
				{IngredientID: seedID番茄, Quantity: &q2, UnitID: "pcs"},
				{IngredientID: seedID葱, Quantity: &q1, UnitID: "根"},
				{IngredientID: seedID盐, Quantity: nil, UnitID: "suitable"},
				{IngredientID: seedID糖, Quantity: &q1, UnitID: "tbsp"},
				{IngredientID: seedID油, Quantity: nil, UnitID: "suitable"},
			},
			Steps: StringArray{
				"鸡蛋打散，加少许盐调味",
				"番茄切块，葱切段",
				"热锅下油，倒入蛋液炒熟盛起",
				"锅中留底油，下番茄块炒出汁水",
				"加入炒好的鸡蛋，调入盐和糖",
				"翻炒均匀，撒上葱花即可",
			},
			Source: "系统默认",
		},
		{
			Name:       "麻婆豆腐",
			Image:      "",
			Time:       "20分钟",
			Difficulty: "家常便饭",
			Tags:       StringArray{"川菜", "下饭菜", "经典"},
			TagColors:  StringArray{"#FF6B6B", "#4ECDC4", "#F38181"},
			Categories: StringArray{"川菜", "辣", "麻", "午餐", "晚餐"},
			Ingredients: RecipeIngredients{
				{IngredientID: seedID其他, Quantity: nil, UnitID: "suitable"},
			},
			Steps: StringArray{
				"豆腐切块，用开水焯一下去除豆腥味",
				"热锅下油，放入牛肉末炒散",
				"加入豆瓣酱炒出红油",
				"放入葱姜蒜爆香",
				"加入适量水，放入豆腐块",
				"调入生抽，小火煮5分钟",
				"用水淀粉勾芡，撒上花椒粉和葱花即可",
			},
			Source: "系统默认",
		},
		{
			Name:       "糖醋里脊",
			Image:      "",
			Time:       "40分钟",
			Difficulty: "餐厅招牌",
			Tags:       StringArray{"经典菜", "酸甜", "下饭菜"},
			TagColors:  StringArray{"#F38181", "#FF6B6B", "#4ECDC4"},
			Categories: StringArray{"家常菜", "甜", "酸", "午餐", "晚餐"},
			Ingredients: RecipeIngredients{
				{IngredientID: seedID鸡蛋, Quantity: &q1, UnitID: "pcs"},
				{IngredientID: seedID糖, Quantity: &q2, UnitID: "tbsp"},
				{IngredientID: seedID盐, Quantity: nil, UnitID: "suitable"},
				{IngredientID: seedID其他, Quantity: nil, UnitID: "suitable"},
			},
			Steps: StringArray{
				"里脊肉切条，用料酒、盐腌制15分钟",
				"鸡蛋打散，加入面粉和淀粉调成糊状",
				"将里脊条裹上蛋糊，下油锅炸至金黄",
				"捞出沥油，再复炸一次使其更酥脆",
				"锅中留底油，下番茄酱炒出红油",
				"加入糖、醋和适量水调成糖醋汁",
				"倒入炸好的里脊条，快速翻炒均匀即可",
			},
			Source: "系统默认",
		},
		{
			Name:       "清蒸鲈鱼",
			Image:      "",
			Time:       "25分钟",
			Difficulty: "家常便饭",
			Tags:       StringArray{"粤菜", "清淡", "健康"},
			TagColors:  StringArray{"#4ECDC4", "#95E1D3", "#AA96DA"},
			Categories: StringArray{"粤菜", "清淡", "午餐", "晚餐"},
			Ingredients: RecipeIngredients{
				{IngredientID: seedID葱, Quantity: &q2, UnitID: "根"},
				{IngredientID: seedID盐, Quantity: nil, UnitID: "suitable"},
				{IngredientID: seedID油, Quantity: nil, UnitID: "suitable"},
				{IngredientID: seedID其他, Quantity: nil, UnitID: "suitable"},
			},
			Steps: StringArray{
				"鲈鱼处理干净，在鱼身两侧划几刀",
				"用料酒和盐腌制10分钟",
				"盘中铺上葱段和姜片，放上鲈鱼",
				"水开后上锅蒸8-10分钟",
				"取出后倒掉盘中多余的水",
				"淋上蒸鱼豉油，撒上葱丝和姜丝",
				"热油浇在鱼身上即可",
			},
			Source: "系统默认",
		},
		{
			Name:       "红烧肉",
			Image:      "",
			Time:       "60分钟",
			Difficulty: "餐厅招牌",
			Tags:       StringArray{"经典菜", "下饭菜", "硬菜"},
			TagColors:  StringArray{"#F38181", "#4ECDC4", "#FF6B6B"},
			Categories: StringArray{"家常菜", "咸鲜", "午餐", "晚餐"},
			Ingredients: RecipeIngredients{
				{IngredientID: seedID葱, Quantity: &q2, UnitID: "根"},
				{IngredientID: seedID其他, Quantity: nil, UnitID: "suitable"},
			},
			Steps: StringArray{
				"五花肉切块，冷水下锅焯水去腥",
				"热锅下少许油，放入冰糖小火炒糖色",
				"糖色变红后下入五花肉翻炒上色",
				"加入葱姜、八角、桂皮爆香",
				"调入生抽、老抽、料酒",
				"加入热水没过肉块，大火烧开转小火",
				"炖煮40分钟至肉软烂，大火收汁即可",
			},
			Source: "系统默认",
		},
		{
			Name:       "蒜蓉西兰花",
			Image:      "",
			Time:       "10分钟",
			Difficulty: "有手就行",
			Tags:       StringArray{"素菜", "快手菜", "健康"},
			TagColors:  StringArray{"#95E1D3", "#4ECDC4", "#AA96DA"},
			Categories: StringArray{"家常菜", "清淡", "午餐", "晚餐"},
			Ingredients: RecipeIngredients{
				{IngredientID: seedID盐, Quantity: nil, UnitID: "suitable"},
				{IngredientID: seedID油, Quantity: nil, UnitID: "suitable"},
				{IngredientID: seedID其他, Quantity: nil, UnitID: "suitable"},
			},
			Steps: StringArray{
				"西兰花掰成小朵，用盐水浸泡10分钟",
				"蒜切末备用",
				"锅中烧水，水开后下西兰花焯水1分钟",
				"捞出过凉水保持翠绿",
				"热锅下油，放入蒜末爆香",
				"下入西兰花快速翻炒",
				"调入盐和蚝油，翻炒均匀即可",
			},
			Source: "系统默认",
		},
		{
			Name:       "水煮鱼",
			Image:      "",
			Time:       "45分钟",
			Difficulty: "硬核挑战",
			Tags:       StringArray{"川菜", "麻辣", "硬菜"},
			TagColors:  StringArray{"#FF6B6B", "#F38181", "#FF6B6B"},
			Categories: StringArray{"川菜", "辣", "麻", "午餐", "晚餐"},
			Ingredients: RecipeIngredients{
				{IngredientID: seedID葱, Quantity: &q3, UnitID: "根"},
				{IngredientID: seedID盐, Quantity: nil, UnitID: "suitable"},
				{IngredientID: seedID鸡蛋, Quantity: &q1, UnitID: "pcs"},
				{IngredientID: seedID其他, Quantity: nil, UnitID: "suitable"},
			},
			Steps: StringArray{
				"草鱼处理干净，片成鱼片",
				"鱼片用料酒、盐、蛋清、淀粉腌制15分钟",
				"豆芽焯水后铺在碗底",
				"热锅下油，放入郫县豆瓣酱炒出红油",
				"加入葱姜蒜爆香，倒入适量水",
				"水开后下入鱼片，煮至变色",
				"将鱼片和汤倒入铺好豆芽的碗中",
				"热锅下油，放入干辣椒和花椒爆香",
				"将热油浇在鱼片上即可",
			},
			Source: "系统默认",
		},
		{
			Name:       "蛋炒饭",
			Image:      "",
			Time:       "10分钟",
			Difficulty: "有手就行",
			Tags:       StringArray{"快手菜", "主食", "经典"},
			TagColors:  StringArray{"#4ECDC4", "#95E1D3", "#F38181"},
			Categories: StringArray{"家常菜", "清淡", "午餐", "晚餐", "夜宵"},
			Ingredients: RecipeIngredients{
				{IngredientID: seedID鸡蛋, Quantity: &q2, UnitID: "pcs"},
				{IngredientID: seedID葱, Quantity: &q1, UnitID: "根"},
				{IngredientID: seedID盐, Quantity: nil, UnitID: "suitable"},
				{IngredientID: seedID油, Quantity: nil, UnitID: "suitable"},
				{IngredientID: seedID其他, Quantity: nil, UnitID: "suitable"},
			},
			Steps: StringArray{
				"鸡蛋打散，加少许盐",
				"热锅下油，倒入蛋液炒熟盛起",
				"锅中留底油，下入米饭炒散",
				"加入炒好的鸡蛋，调入盐和生抽",
				"翻炒均匀，撒上葱花即可",
			},
			Source: "系统默认",
		},
		{
			Name:       "可乐鸡翅",
			Image:      "",
			Time:       "30分钟",
			Difficulty: "家常便饭",
			Tags:       StringArray{"快手菜", "下饭菜", "经典"},
			TagColors:  StringArray{"#4ECDC4", "#FF6B6B", "#F38181"},
			Categories: StringArray{"家常菜", "甜", "午餐", "晚餐"},
			Ingredients: RecipeIngredients{
				{IngredientID: seedID葱, Quantity: &q2, UnitID: "根"},
				{IngredientID: seedID其他, Quantity: nil, UnitID: "suitable"},
			},
			Steps: StringArray{
				"鸡翅洗净，两面划几刀方便入味",
				"用料酒、生抽腌制15分钟",
				"热锅下少许油，将鸡翅煎至两面金黄",
				"加入葱姜爆香",
				"倒入可乐，调入生抽和老抽",
				"大火烧开转小火，炖煮15分钟",
				"大火收汁至浓稠即可",
			},
			Source: "系统默认",
		},
	}

	// 批量插入数据
	for _, recipe := range recipes {
		if err := DB.Create(&recipe).Error; err != nil {
			log.Printf("创建菜谱失败: %s, 错误: %v", recipe.Name, err)
		} else {
			log.Printf("创建菜谱成功: %s", recipe.Name)
		}
	}

	log.Printf("模拟菜谱数据填充完成，共创建 %d 条记录", len(recipes))
}

// GetDB 获取数据库实例
// 返回: 数据库实例
func GetDB() *gorm.DB {
	return DB
}
