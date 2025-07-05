package models

import (
	"time"

	"gorm.io/gorm"
)

// Family 家庭模型
type Family struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Name        string         `json:"name" gorm:"size:100;not null;comment:家庭名称"`
	Description string         `json:"description" gorm:"size:500;comment:家庭描述"`
	Avatar      string         `json:"avatar" gorm:"size:255;comment:家庭头像"`
	OwnerID     uint           `json:"owner_id" gorm:"not null;comment:一家之主ID"`
	InviteCode  string         `json:"invite_code" gorm:"size:20;uniqueIndex;comment:邀请码"`
	Status      int            `json:"status" gorm:"default:1;comment:状态 0-解散 1-正常"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at" gorm:"index"`

	// 关联关系
	Owner       User           `json:"owner" gorm:"foreignKey:OwnerID"`
	Members     []FamilyMember `json:"members" gorm:"foreignKey:FamilyID"`
	Recipes     []Recipe       `json:"recipes" gorm:"foreignKey:FamilyID"`
	Orders      []Order        `json:"orders" gorm:"foreignKey:FamilyID"`
	Ingredients []Ingredient   `json:"ingredients" gorm:"foreignKey:FamilyID"`
	Memories    []Memory       `json:"memories" gorm:"foreignKey:FamilyID"`
	Invitations []Invitation   `json:"invitations" gorm:"foreignKey:FamilyID"`
}

// FamilyMember 家庭成员模型
type FamilyMember struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	FamilyID  uint      `json:"family_id" gorm:"not null;comment:家庭ID"`
	UserID    uint      `json:"user_id" gorm:"not null;comment:用户ID"`
	Role      string    `json:"role" gorm:"size:20;default:'member';comment:角色 owner-一家之主 chef-主厨 foodie-美食家 cleaner-洗碗工 member-普通成员"`
	Nickname  string    `json:"nickname" gorm:"size:50;comment:家庭内昵称"`
	Status    int       `json:"status" gorm:"default:1;comment:状态 0-待审核 1-正常 2-禁用"`
	JoinedAt  time.Time `json:"joined_at" gorm:"comment:加入时间"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	// 关联关系
	Family Family `json:"family" gorm:"foreignKey:FamilyID"`
	User   User   `json:"user" gorm:"foreignKey:UserID"`
}

// Invitation 邀请模型
type Invitation struct {
	ID         uint      `json:"id" gorm:"primaryKey"`
	FamilyID   uint      `json:"family_id" gorm:"not null;comment:家庭ID"`
	InviterID  uint      `json:"inviter_id" gorm:"not null;comment:邀请人ID"`
	InviteeID  uint      `json:"invitee_id" gorm:"comment:被邀请人ID"`
	Code       string    `json:"code" gorm:"size:20;uniqueIndex;comment:邀请码"`
	Type       int       `json:"type" gorm:"default:1;comment:类型 1-家庭成员 2-临时客人"`
	Status     int       `json:"status" gorm:"default:0;comment:状态 0-待接受 1-已接受 2-已拒绝 3-已过期"`
	ExpireAt   time.Time `json:"expire_at" gorm:"comment:过期时间"`
	AcceptedAt time.Time `json:"accepted_at" gorm:"comment:接受时间"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`

	// 关联关系
	Family  Family `json:"family" gorm:"foreignKey:FamilyID"`
	Inviter User   `json:"inviter" gorm:"foreignKey:InviterID"`
	Invitee User   `json:"invitee" gorm:"foreignKey:InviteeID"`
}

// TableName 指定表名
func (Family) TableName() string {
	return "families"
}

func (FamilyMember) TableName() string {
	return "family_members"
}

func (Invitation) TableName() string {
	return "invitations"
}
