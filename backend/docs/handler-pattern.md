# Handler 模式说明

## 概述

在 Gin 框架中，我们使用结构体模式来组织 handler，这样可以更好地管理依赖注入和代码结构。

## Handler 结构

### 1. Handler 结构体

```go
// UserHandler 用户处理器
type UserHandler struct {
    userService *service.UserService
}
```

### 2. 构造函数

```go
// NewUserHandler 创建用户处理器
func NewUserHandler() *UserHandler {
    return &UserHandler{
        userService: service.NewUserService(),
    }
}
```

## 为什么需要 NewUserHandler()？

### 1. **依赖注入**
- Handler 需要依赖 Service 层
- 通过构造函数注入依赖，而不是在函数内部创建

### 2. **代码组织**
- 将相关的 handler 方法组织在一个结构体中
- 便于管理和维护

### 3. **测试友好**
- 可以轻松 mock 依赖进行单元测试
- 便于依赖注入和替换

### 4. **路由注册**
- 在路由注册时创建 handler 实例
- 将实例方法绑定到路由

## 使用方式

### 1. 路由注册

```go
func RegisterRoutes(r *gin.Engine) {
    // 创建 handler 实例
    userHandler := handler.NewUserHandler()
    
    // 注册路由，绑定到实例方法
    userRoutes := r.Group("/users")
    {
        userRoutes.POST("/", userHandler.CreateUser)
        userRoutes.GET("/:id", userHandler.GetUser)
    }
}
```

### 2. Handler 方法

```go
// CreateUser 创建用户
func (h *UserHandler) CreateUser(c *gin.Context) {
    // 使用注入的 service
    if err := h.userService.CreateUser(&user); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    // ...
}
```

## 优势

### 1. **依赖管理**
- 清晰的依赖关系
- 避免循环依赖
- 便于单元测试

### 2. **代码复用**
- Service 层可以被多个 Handler 复用
- 避免重复代码

### 3. **类型安全**
- 编译时检查依赖关系
- 减少运行时错误

### 4. **可扩展性**
- 易于添加新的依赖
- 便于功能扩展

## 对比函数式 Handler

### 函数式 Handler（不推荐）
```go
func CreateUser(c *gin.Context) {
    // 在函数内部创建 service
    userService := service.NewUserService()
    // 直接处理业务逻辑
    // ...
}
```

### 结构体 Handler（推荐）
```go
type UserHandler struct {
    userService *service.UserService
}

func (h *UserHandler) CreateUser(c *gin.Context) {
    // 使用注入的 service
    h.userService.CreateUser(&user)
}
```

## 最佳实践

### 1. **单一职责**
- 每个 Handler 只处理一个业务模块
- 保持结构体简洁

### 2. **依赖注入**
- 通过构造函数注入所有依赖
- 避免在方法内部创建依赖

### 3. **错误处理**
- 在 Handler 层处理 HTTP 相关错误
- 在 Service 层处理业务逻辑错误

### 4. **参数验证**
- 在 Handler 层进行参数验证
- 返回合适的 HTTP 状态码

### 5. **响应格式**
- 统一响应格式
- 包含状态码、消息和数据 