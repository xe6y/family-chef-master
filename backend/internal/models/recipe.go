package models

import (
	"time"

	"gorm.io/gorm"
)

// Recipe 菜谱模型
type Recipe struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	FamilyID    uint           `json:"family_id" gorm:"not null;comment:家庭ID"`
	UserID      uint           `json:"user_id" gorm:"not null;comment:创建者ID"`
	Name        string         `json:"name" gorm:"size:100;not null;comment:菜谱名称"`
	Description string         `json:"description" gorm:"size:500;comment:菜谱描述"`
	Image       string         `json:"image" gorm:"size:255;comment:菜品图片"`
	Cuisine     string         `json:"cuisine" gorm:"size:50;comment:菜系"`
	Taste       string         `json:"taste" gorm:"size:50;comment:口味"`
	Difficulty  int            `json:"difficulty" gorm:"default:1;comment:难度 1-5"`
	CookingTime int            `json:"cooking_time" gorm:"comment:烹饪时间(分钟)"`
	ServingSize int            `json:"serving_size" gorm:"comment:份量(人数)"`
	Steps       string         `json:"steps" gorm:"type:text;comment:制作步骤"`
	TutorialURL string         `json:"tutorial_url" gorm:"size:255;comment:教程链接"`
	Tags        string         `json:"tags" gorm:"size:500;comment:标签(JSON格式)"`
	IsPrivate   bool           `json:"is_private" gorm:"default:false;comment:是否私家菜"`
	Status      int            `json:"status" gorm:"default:1;comment:状态 0-下架 1-上架"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联关系
	Family      Family             `json:"family" gorm:"foreignKey:FamilyID"`
	User        User               `json:"user" gorm:"foreignKey:UserID"`
	Ingredients []RecipeIngredient `json:"ingredients" gorm:"foreignKey:RecipeID"`
	Orders      []OrderItem        `json:"orders" gorm:"foreignKey:RecipeID"`
	Reviews     []Review           `json:"reviews" gorm:"foreignKey:RecipeID"`
	Memories    []Memory           `json:"memories" gorm:"foreignKey:RecipeID"`
}

// RecipeIngredient 菜谱食材模型
type RecipeIngredient struct {
	ID           uint    `json:"id" gorm:"primaryKey"`
	RecipeID     uint    `json:"recipe_id" gorm:"not null;comment:菜谱ID"`
	IngredientID uint    `json:"ingredient_id" gorm:"not null;comment:食材ID"`
	Amount       float64 `json:"amount" gorm:"comment:用量"`
	Unit         string  `json:"unit" gorm:"size:20;comment:单位"`
	Note         string  `json:"note" gorm:"size:200;comment:备注"`

	// 关联关系
	Recipe     Recipe     `json:"recipe" gorm:"foreignKey:RecipeID"`
	Ingredient Ingredient `json:"ingredient" gorm:"foreignKey:IngredientID"`
}

// ChefSkill 主厨拿手菜模型
type ChefSkill struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	UserID    uint      `json:"user_id" gorm:"not null;comment:用户ID"`
	RecipeID  uint      `json:"recipe_id" gorm:"not null;comment:菜谱ID"`
	Level     int       `json:"level" gorm:"default:1;comment:熟练度 1-5"`
	Note      string    `json:"note" gorm:"size:200;comment:备注"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	// 关联关系
	User   User   `json:"user" gorm:"foreignKey:UserID"`
	Recipe Recipe `json:"recipe" gorm:"foreignKey:RecipeID"`
}

// Ingredient 食材模型
type Ingredient struct {
	ID         uint           `json:"id" gorm:"primaryKey"`
	FamilyID   uint           `json:"family_id" gorm:"not null;comment:家庭ID"`
	Name       string         `json:"name" gorm:"size:100;not null;comment:食材名称"`
	Category   string         `json:"category" gorm:"size:50;comment:分类"`
	Unit       string         `json:"unit" gorm:"size:20;comment:单位"`
	Stock      float64        `json:"stock" gorm:"default:0;comment:库存数量"`
	MinStock   float64        `json:"min_stock" gorm:"default:0;comment:最低库存"`
	Location   string         `json:"location" gorm:"size:100;comment:存放位置"`
	ExpiryDate *time.Time     `json:"expiry_date" gorm:"comment:保质期"`
	Price      float64        `json:"price" gorm:"default:0;comment:单价"`
	Status     int            `json:"status" gorm:"default:1;comment:状态 0-禁用 1-正常"`
	CreatedAt  time.Time      `json:"created_at"`
	UpdatedAt  time.Time      `json:"updated_at"`
	DeletedAt  gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联关系
	Family            Family             `json:"family" gorm:"foreignKey:FamilyID"`
	RecipeIngredients []RecipeIngredient `json:"recipe_ingredients" gorm:"foreignKey:IngredientID"`
	PurchaseItems     []PurchaseItem     `json:"purchase_items" gorm:"foreignKey:IngredientID"`
}

// TableName 指定表名
func (Recipe) TableName() string {
	return "recipes"
}

func (RecipeIngredient) TableName() string {
	return "recipe_ingredients"
}

func (ChefSkill) TableName() string {
	return "chef_skills"
}

func (Ingredient) TableName() string {
	return "ingredients"
}
