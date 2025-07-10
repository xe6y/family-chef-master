# 数据库交互使用指南

## 概述

本文档介绍如何在 service 层进行数据库交互操作，包括基本的 CRUD 操作、关联查询、事务处理等。

## 基本操作

### 1. 创建记录

```go
// 创建单个记录
func (s *UserService) CreateUser(user *models.SystemUser) error {
    return database.DB.Create(user).Error
}

// 批量创建
func (s *UserService) CreateUsers(users []models.SystemUser) error {
    return database.DB.Create(&users).Error
}
```

### 2. 查询记录

```go
// 根据ID查询
func (s *UserService) GetUserByID(id int64) (*models.SystemUser, error) {
    var user models.SystemUser
    if err := database.DB.First(&user, id).Error; err != nil {
        return nil, err
    }
    return &user, nil
}

// 条件查询
func (s *UserService) GetUserByOpenID(openID string) (*models.SystemUser, error) {
    var user models.SystemUser
    if err := database.DB.Where("openid = ?", openID).First(&user).Error; err != nil {
        return nil, err
    }
    return &user, nil
}

// 查询多条记录
func (s *UserService) GetUsersByFamilyID(familyID int64) ([]models.SystemUser, error) {
    var users []models.SystemUser
    if err := database.DB.Where("family_id = ?", familyID).Find(&users).Error; err != nil {
        return nil, err
    }
    return users, nil
}
```

### 3. 更新记录

```go
// 更新整个记录
func (s *UserService) UpdateUser(user *models.SystemUser) error {
    return database.DB.Save(user).Error
}

// 部分更新
func (s *UserService) UpdateUserProfile(id int64, nickname, avatar string) error {
    updates := map[string]interface{}{
        "nickname": nickname,
        "avatar":   avatar,
    }
    return database.DB.Model(&models.SystemUser{}).Where("id = ?", id).Updates(updates).Error
}
```

### 4. 删除记录

```go
// 根据ID删除
func (s *UserService) DeleteUser(id int64) error {
    return database.DB.Delete(&models.SystemUser{}, id).Error
}

// 条件删除
func (s *UserService) DeleteUsersByFamilyID(familyID int64) error {
    return database.DB.Where("family_id = ?", familyID).Delete(&models.SystemUser{}).Error
}
```

## 高级查询

### 1. 分页查询

```go
func (s *UserService) ListUsers(page, pageSize int) ([]models.SystemUser, int64, error) {
    var users []models.SystemUser
    var total int64

    // 获取总数
    if err := database.DB.Model(&models.SystemUser{}).Count(&total).Error; err != nil {
        return nil, 0, err
    }

    // 分页查询
    offset := (page - 1) * pageSize
    if err := database.DB.Offset(offset).Limit(pageSize).Find(&users).Error; err != nil {
        return nil, 0, err
    }

    return users, total, nil
}
```

### 2. 关联查询

```go
// 预加载关联数据
func (s *FamilyService) GetFamilyWithMembers(id int64) (*models.SystemFamily, []models.SystemUser, error) {
    var family models.SystemFamily
    var members []models.SystemUser

    // 获取家庭信息
    if err := database.DB.First(&family, id).Error; err != nil {
        return nil, nil, err
    }

    // 获取家庭成员
    if err := database.DB.Where("family_id = ?", id).Find(&members).Error; err != nil {
        return nil, nil, err
    }

    return &family, members, nil
}
```

### 3. 复杂条件查询

```go
func (s *UserService) SearchUsers(keyword string, page, pageSize int) ([]models.SystemUser, int64, error) {
    var users []models.SystemUser
    var total int64

    // 构建查询条件
    query := database.DB.Model(&models.SystemUser{}).Where(
        "nickname LIKE ? OR phone LIKE ?", 
        "%"+keyword+"%", 
        "%"+keyword+"%",
    )

    // 获取总数
    if err := query.Count(&total).Error; err != nil {
        return nil, 0, err
    }

    // 分页查询
    offset := (page - 1) * pageSize
    if err := query.Offset(offset).Limit(pageSize).Find(&users).Error; err != nil {
        return nil, 0, err
    }

    return users, total, nil
}
```

## 事务处理

### 1. 简单事务

```go
func (s *FamilyService) CreateFamily(family *models.SystemFamily) error {
    return database.DB.Transaction(func(tx *gorm.DB) error {
        // 创建家庭
        if err := tx.Create(family).Error; err != nil {
            return err
        }

        // 将创建者设为家庭管理员
        if family.OwnerID > 0 {
            if err := tx.Model(&models.SystemUser{}).
                Where("id = ?", family.OwnerID).
                Updates(map[string]interface{}{
                    "family_id":   family.ID,
                    "family_role": "admin",
                }).Error; err != nil {
                return err
            }
        }

        return nil
    })
}
```

### 2. 复杂事务

```go
func (s *FamilyService) DeleteFamily(id int64) error {
    return database.DB.Transaction(func(tx *gorm.DB) error {
        // 删除家庭
        if err := tx.Delete(&models.SystemFamily{}, id).Error; err != nil {
            return err
        }

        // 将家庭成员的家庭ID设为0
        if err := tx.Model(&models.SystemUser{}).
            Where("family_id = ?", id).
            Updates(map[string]interface{}{
                "family_id":   0,
                "family_role": "",
            }).Error; err != nil {
            return err
        }

        return nil
    })
}
```

## 统计查询

### 1. 计数统计

```go
func (s *UserService) GetUserStats() (map[string]interface{}, error) {
    var stats map[string]interface{}
    
    // 总用户数
    var totalUsers int64
    if err := database.DB.Model(&models.SystemUser{}).Count(&totalUsers).Error; err != nil {
        return nil, err
    }

    // 今日新增用户数
    var todayUsers int64
    today := time.Now().Format("2006-01-02")
    if err := database.DB.Model(&models.SystemUser{}).
        Where("DATE(create_time) = ?", today).
        Count(&todayUsers).Error; err != nil {
        return nil, err
    }

    stats = map[string]interface{}{
        "total_users": totalUsers,
        "today_users": todayUsers,
    }

    return stats, nil
}
```

## 最佳实践

### 1. 错误处理

```go
func (s *UserService) GetUserByID(id int64) (*models.SystemUser, error) {
    var user models.SystemUser
    if err := database.DB.First(&user, id).Error; err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, errors.New("用户不存在")
        }
        return nil, err
    }
    return &user, nil
}
```

### 2. 数据验证

```go
func (s *UserService) CreateUser(user *models.SystemUser) error {
    // 检查用户是否已存在
    var existingUser models.SystemUser
    if err := database.DB.Where("openid = ?", user.OpenID).First(&existingUser).Error; err == nil {
        return errors.New("用户已存在")
    }

    // 创建新用户
    if err := database.DB.Create(user).Error; err != nil {
        return err
    }
    return nil
}
```

### 3. 性能优化

```go
// 使用索引字段进行查询
func (s *UserService) GetUsersByFamilyID(familyID int64) ([]models.SystemUser, error) {
    var users []models.SystemUser
    if err := database.DB.Where("family_id = ?", familyID).Find(&users).Error; err != nil {
        return nil, err
    }
    return users, nil
}

// 限制查询结果数量
func (s *UserService) GetRecentUsers(limit int) ([]models.SystemUser, error) {
    var users []models.SystemUser
    if err := database.DB.Order("create_time DESC").Limit(limit).Find(&users).Error; err != nil {
        return nil, err
    }
    return users, nil
}
```

## 注意事项

1. **始终检查错误**：每个数据库操作都应该检查返回的错误
2. **使用事务**：涉及多个表操作时，使用事务确保数据一致性
3. **避免 N+1 查询**：使用 Preload 预加载关联数据
4. **合理使用索引**：在经常查询的字段上建立索引
5. **分页查询**：大数据量查询时使用分页
6. **参数化查询**：使用参数化查询防止 SQL 注入 