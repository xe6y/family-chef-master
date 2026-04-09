package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// 审核状态常量
const (
	ReviewStatusPending  = "pending"  // 待审核
	ReviewStatusApproved = "approved" // 已通过
	ReviewStatusRejected = "rejected" // 已拒绝
)

// PublicRecipe 公开菜谱模型（探索发现）
type PublicRecipe struct {
	ID              string            `json:"id" gorm:"type:varchar(36);primaryKey"`                         // 菜谱ID
	Name            string            `json:"name" gorm:"type:varchar(100);not null;index"`                  // 菜谱名称
	Image           string            `json:"image" gorm:"type:varchar(500)"`                                // 图片URL
	Time            string            `json:"time" gorm:"type:varchar(50)"`                                  // 制作时间
	Difficulty      string            `json:"difficulty" gorm:"type:varchar(50)"`                            // 难度
	DifficultyColor string            `json:"difficultyColor" gorm:"-"`                                      // 难度颜色（不存储）
	Tags            StringArray       `json:"tags" gorm:"type:jsonb"`                                        // 标签数组
	TagColors       StringArray       `json:"tagColors" gorm:"type:jsonb"`                                   // 标签颜色数组
	Categories      StringArray       `json:"categories" gorm:"type:jsonb"`                                  // 分类数组
	Ingredients     RecipeIngredients `json:"ingredients" gorm:"type:jsonb"`                                 // 食材列表
	Steps           StringArray       `json:"steps" gorm:"type:jsonb"`                                       // 制作步骤
	CreatorID       string            `json:"creatorId" gorm:"type:varchar(36);index"`                       // 创建者ID
	Source          string            `json:"source" gorm:"type:varchar(100)"`                               // 来源类型（user_created / web_import）
	SourceURL       string            `json:"sourceUrl" gorm:"type:varchar(1000)"`                           // 原始网页/视频 URL（从链接导入时记录）
	ReviewStatus    string            `json:"reviewStatus" gorm:"type:varchar(20);default:'pending';index"`  // 审核状态：pending / approved / rejected
	CreatedAt       time.Time         `json:"createdAt"`                                                     // 创建时间
	UpdatedAt       time.Time         `json:"updatedAt"`                                                     // 更新时间
	DeletedAt       gorm.DeletedAt    `json:"-" gorm:"index"`                                                // 软删除时间
}

// TableName 指定表名
func (PublicRecipe) TableName() string {
	return "public_recipes"
}

// BeforeCreate 创建前钩子，自动生成ID
func (r *PublicRecipe) BeforeCreate(tx *gorm.DB) error {
	if r.ID == "" {
		r.ID = uuid.New().String()
	}
	if r.ReviewStatus == "" {
		r.ReviewStatus = ReviewStatusPending
	}
	return nil
}

// ToListItem 转换为列表项
func (r *PublicRecipe) ToListItem() *RecipeListItem {
	return &RecipeListItem{
		ID:              r.ID,
		Name:            r.Name,
		Image:           r.Image,
		Time:            r.Time,
		Difficulty:      r.Difficulty,
		DifficultyColor: r.DifficultyColor,
		Tags:            r.Tags,
		TagColors:       r.TagColors,
		Categories:      r.Categories,
	}
}
