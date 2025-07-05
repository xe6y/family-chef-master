package models

import (
	"time"

	"gorm.io/gorm"
)

// Order 订单模型
type Order struct {
	ID           uint           `json:"id" gorm:"primaryKey"`
	FamilyID     uint           `json:"family_id" gorm:"not null;comment:家庭ID"`
	UserID       uint           `json:"user_id" gorm:"not null;comment:下单用户ID"`
	ChefID       *uint          `json:"chef_id" gorm:"comment:指定厨师ID"`
	OrderNo      string         `json:"order_no" gorm:"size:50;uniqueIndex;comment:订单号"`
	Type         int            `json:"type" gorm:"default:1;comment:订单类型 1-普通点餐 2-宴请点餐"`
	Status       int            `json:"status" gorm:"default:0;comment:订单状态 0-待确认 1-已确认 2-制作中 3-已完成 4-已取消"`
	TotalAmount  float64        `json:"total_amount" gorm:"default:0;comment:总金额"`
	Remark       string         `json:"remark" gorm:"size:500;comment:备注"`
	ExpectedTime *time.Time     `json:"expected_time" gorm:"comment:期望完成时间"`
	CompletedAt  *time.Time     `json:"completed_at" gorm:"comment:完成时间"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联关系
	Family  Family      `json:"family" gorm:"foreignKey:FamilyID"`
	User    User        `json:"user" gorm:"foreignKey:UserID"`
	Chef    *User       `json:"chef" gorm:"foreignKey:ChefID"`
	Items   []OrderItem `json:"items" gorm:"foreignKey:OrderID"`
	Reviews []Review    `json:"reviews" gorm:"foreignKey:OrderID"`
}

// OrderItem 订单项模型
type OrderItem struct {
	ID       uint    `json:"id" gorm:"primaryKey"`
	OrderID  uint    `json:"order_id" gorm:"not null;comment:订单ID"`
	RecipeID uint    `json:"recipe_id" gorm:"not null;comment:菜谱ID"`
	Quantity int     `json:"quantity" gorm:"default:1;comment:数量"`
	Price    float64 `json:"price" gorm:"default:0;comment:单价"`
	Amount   float64 `json:"amount" gorm:"default:0;comment:小计"`
	Remark   string  `json:"remark" gorm:"size:200;comment:备注"`

	// 关联关系
	Order  Order  `json:"order" gorm:"foreignKey:OrderID"`
	Recipe Recipe `json:"recipe" gorm:"foreignKey:RecipeID"`
}

// Review 评价模型
type Review struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	OrderID   uint      `json:"order_id" gorm:"not null;comment:订单ID"`
	RecipeID  uint      `json:"recipe_id" gorm:"not null;comment:菜谱ID"`
	UserID    uint      `json:"user_id" gorm:"not null;comment:评价用户ID"`
	Rating    int       `json:"rating" gorm:"not null;comment:评分 1-5"`
	Content   string    `json:"content" gorm:"size:500;comment:评价内容"`
	Images    string    `json:"images" gorm:"size:1000;comment:图片URLs(JSON格式)"`
	IsBest    bool      `json:"is_best" gorm:"default:false;comment:是否今日最佳"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	// 关联关系
	Order  Order  `json:"order" gorm:"foreignKey:OrderID"`
	Recipe Recipe `json:"recipe" gorm:"foreignKey:RecipeID"`
	User   User   `json:"user" gorm:"foreignKey:UserID"`
}

// Memory 家宴回忆模型
type Memory struct {
	ID           uint           `json:"id" gorm:"primaryKey"`
	FamilyID     uint           `json:"family_id" gorm:"not null;comment:家庭ID"`
	RecipeID     *uint          `json:"recipe_id" gorm:"comment:菜谱ID"`
	Title        string         `json:"title" gorm:"size:100;not null;comment:回忆标题"`
	Description  string         `json:"description" gorm:"size:1000;comment:回忆描述"`
	Images       string         `json:"images" gorm:"size:2000;comment:图片URLs(JSON格式)"`
	EventDate    time.Time      `json:"event_date" gorm:"comment:事件日期"`
	Participants string         `json:"participants" gorm:"size:500;comment:参与者"`
	Tags         string         `json:"tags" gorm:"size:500;comment:标签(JSON格式)"`
	ShareCode    string         `json:"share_code" gorm:"size:50;uniqueIndex;comment:分享码"`
	Status       int            `json:"status" gorm:"default:1;comment:状态 0-私密 1-公开"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联关系
	Family Family  `json:"family" gorm:"foreignKey:FamilyID"`
	Recipe *Recipe `json:"recipe" gorm:"foreignKey:RecipeID"`
}

// PurchaseItem 采购清单项模型
type PurchaseItem struct {
	ID           uint       `json:"id" gorm:"primaryKey"`
	IngredientID uint       `json:"ingredient_id" gorm:"not null;comment:食材ID"`
	Quantity     float64    `json:"quantity" gorm:"not null;comment:采购数量"`
	Unit         string     `json:"unit" gorm:"size:20;comment:单位"`
	Price        float64    `json:"price" gorm:"default:0;comment:单价"`
	Amount       float64    `json:"amount" gorm:"default:0;comment:小计"`
	IsPurchased  bool       `json:"is_purchased" gorm:"default:false;comment:是否已购买"`
	PurchasedAt  *time.Time `json:"purchased_at" gorm:"comment:购买时间"`
	Remark       string     `json:"remark" gorm:"size:200;comment:备注"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`

	// 关联关系
	Ingredient Ingredient `json:"ingredient" gorm:"foreignKey:IngredientID"`
}

// TableName 指定表名
func (Order) TableName() string {
	return "orders"
}

func (OrderItem) TableName() string {
	return "order_items"
}

func (Review) TableName() string {
	return "reviews"
}

func (Memory) TableName() string {
	return "memories"
}

func (PurchaseItem) TableName() string {
	return "purchase_items"
}
