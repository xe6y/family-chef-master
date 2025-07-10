package models

// GetAllModels 获取所有模型，用于数据库迁移
func GetAllModels() []any {
	return []any{
		&SystemUser{},
		&SystemFamily{},
		&MenuPublic{},
		&MenuFamily{},
		&MenuTutorial{},
		&MenuTag{},
		&MenuTagRelation{},
		&Order{},
		&OrderDetail{},
	}
}
