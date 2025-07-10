# 数据库索引优化策略

## 索引过多的问题

### 1. **性能影响**
- **写入性能下降**：每次插入/更新/删除都需要维护索引
- **存储空间增加**：索引占用额外的磁盘空间
- **内存占用增加**：索引需要加载到内存中

### 2. **维护成本**
- 索引需要定期维护和优化
- 过多的索引会增加数据库管理复杂度

## 优化后的索引策略

### 1. **SystemUser 表**
```go
type SystemUser struct {
    ID         int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
    OpenID     string    `gorm:"type:varchar(255);uniqueIndex;column:openid"` // 唯一索引，登录必需
    Nickname   string    `gorm:"type:varchar(255);column:nickname"`           // 移除索引，搜索频率不高
    Avatar     string    `gorm:"type:varchar(255);column:avatar"`
    Phone      string    `gorm:"type:varchar(20);column:phone"`              // 移除索引，搜索频率不高
    FamilyID   int64     `gorm:"index;column:family_id"`                     // 保留，查询家庭成员必需
    FamilyRole string    `gorm:"type:varchar(50);column:family_role"`
    CreateTime time.Time `gorm:"autoCreateTime;column:create_time"`          // 移除索引，统计查询频率不高
}
```

### 2. **SystemFamily 表**
```go
type SystemFamily struct {
    ID         int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
    Name       string    `gorm:"type:varchar(255);column:name"`              // 移除索引，搜索频率不高
    InviteCode string    `gorm:"type:varchar(255);uniqueIndex;column:invite_code"` // 保留，邀请码唯一性必需
    OwnerID    int64     `gorm:"index;column:owner_id"`                      // 保留，查询用户创建的家庭
    CreateTime time.Time `gorm:"autoCreateTime;column:create_time"`          // 移除索引，统计查询频率不高
}
```

### 3. **MenuPublic 表**
```go
type MenuPublic struct {
    ID         int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
    Name       string    `gorm:"type:varchar(255);column:name"`              // 移除索引，搜索频率不高
    Image      string    `gorm:"type:varchar(255);column:image"`
    Tags       string    `gorm:"type:text;column:tags"`
    Steps      string    `gorm:"type:text;column:steps"`
    CreateTime time.Time `gorm:"autoCreateTime;column:create_time"`          // 移除索引，统计查询频率不高
}
```

### 4. **MenuFamily 表**
```go
type MenuFamily struct {
    ID           int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
    FamilyID     int64     `gorm:"index;column:family_id"`                   // 保留，查询家庭菜谱必需
    OriginMenuID int64     `gorm:"index;column:origin_menu_id"`              // 保留，关联查询必需
    Name         string    `gorm:"type:varchar(255);column:name"`            // 移除索引，搜索频率不高
    Image        string    `gorm:"type:varchar(255);column:image"`
    Steps        string    `gorm:"type:text;column:steps"`
    CreateBy     int64     `gorm:"index;column:create_by"`                   // 保留，查询用户创建的菜谱
    CreateTime   time.Time `gorm:"autoCreateTime;column:create_time"`        // 移除索引，统计查询频率不高
}
```

### 5. **Order 表**
```go
type Order struct {
    ID         int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
    FamilyID   int64     `gorm:"index;column:family_id"`                     // 保留，查询家庭订单必需
    MenuType   string    `gorm:"type:varchar(50);column:menu_type"`          // 移除索引，按类型查询频率不高
    CreateTime time.Time `gorm:"autoCreateTime;index;column:create_time"`    // 保留，订单时间查询重要
}
```

### 6. **OrderDetail 表**
```go
type OrderDetail struct {
    ID         int64     `gorm:"primaryKey;autoIncrement;not null;unique;column:id"`
    OrderID    int64     `gorm:"index;column:order_id"`                      // 保留，查询订单明细必需
    MenuSource string    `gorm:"type:varchar(50);column:menu_source"`        // 移除索引，按来源查询频率不高
    MenuID     int64     `gorm:"index;column:menu_id"`                       // 保留，关联菜谱查询
    MenuName   string    `gorm:"type:varchar(255);column:menu_name"`         // 移除索引，搜索频率不高
    Image      string    `gorm:"type:varchar(255);column:image"`
    CreateBy   int64     `gorm:"index;column:create_by"`                     // 保留，查询用户点餐记录
    CreateTime time.Time `gorm:"autoCreateTime;column:create_time"`          // 移除索引，统计查询频率不高
    Status     int8      `gorm:"type:tinyint;column:status"`                 // 移除索引，按状态查询频率不高
    Sort       int8      `gorm:"type:tinyint;column:sort"`
    Remark     string    `gorm:"type:text;column:remark"`
}
```

## 索引原则

### 1. **必需索引**
- **主键索引**：自动创建
- **唯一索引**：保证数据唯一性（OpenID、InviteCode、TagName）
- **外键索引**：关联查询必需（FamilyID、OrderID、MenuID等）

### 2. **高频查询索引**
- **用户登录**：OpenID
- **家庭相关查询**：FamilyID
- **订单时间查询**：CreateTime（Order表）

### 3. **避免的索引**
- **搜索频率不高的字段**：Name、Phone、Nickname等
- **统计查询字段**：CreateTime（非核心业务表）
- **枚举值字段**：Status、MenuType等（除非查询频率很高）

## 性能优化建议

### 1. **监控查询性能**
- 使用 `EXPLAIN` 分析查询计划
- 监控慢查询日志
- 根据实际使用情况调整索引

### 2. **复合索引考虑**
- 如果经常按 FamilyID + CreateTime 查询，考虑复合索引
- 如果经常按 OrderID + Status 查询，考虑复合索引

### 3. **定期维护**
- 定期分析索引使用情况
- 删除未使用的索引
- 优化索引顺序 