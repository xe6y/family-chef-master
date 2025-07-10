package routes

import (
	"family-chef-backend/internal/handler"

	"github.com/gin-gonic/gin"
)

// RegisterRoutes 注册所有路由
func RegisterRoutes(r *gin.Engine) {
	// 创建 handler 实例
	userHandler := handler.NewUserHandler()
	familyHandler := handler.NewFamilyHandler()
	menuHandler := handler.NewMenuHandler()
	orderHandler := handler.NewOrderHandler()

	// API 版本组
	v1 := r.Group("/api/v1")
	{
		// 健康检查
		v1.GET("/health", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"status":  "ok",
				"message": "服务正常运行",
			})
		})

		// 用户相关路由
		userRoutes := v1.Group("/users")
		{
			userRoutes.POST("/", userHandler.CreateUser)                    // 创建用户
			userRoutes.GET("/:id", userHandler.GetUser)                     // 获取用户信息
			userRoutes.GET("/openid", userHandler.GetUserByOpenID)          // 根据OpenID获取用户
			userRoutes.PUT("/:id", userHandler.UpdateUser)                  // 更新用户信息
			userRoutes.PATCH("/:id/profile", userHandler.UpdateUserProfile) // 更新用户基本信息
			userRoutes.GET("/", userHandler.ListUsers)                      // 获取用户列表
			userRoutes.GET("/search", userHandler.SearchUsers)              // 搜索用户
			userRoutes.GET("/stats", userHandler.GetUserStats)              // 获取用户统计
			userRoutes.DELETE("/:id", userHandler.DeleteUser)               // 删除用户
		}

		// 家庭相关路由
		familyRoutes := v1.Group("/families")
		{
			familyRoutes.POST("/", familyHandler.CreateFamily)
			familyRoutes.GET("/:id", familyHandler.GetFamily)
		}

		// 菜谱相关路由
		menuRoutes := v1.Group("/menus")
		{
			menuRoutes.GET("/public", menuHandler.GetPublicMenus)
			menuRoutes.GET("/family", menuHandler.GetFamilyMenus)
		}

		// 订单相关路由
		orderRoutes := v1.Group("/orders")
		{
			orderRoutes.POST("/", orderHandler.CreateOrder)
			orderRoutes.GET("/", orderHandler.GetOrders)
		}
	}
}
