package main

import (
	"bitePal_service/config"
	"bitePal_service/routes"
	"bitePal_service/services"
	"log"
)

// main 程序入口
func main() {
	// 初始化全局配置
	config.InitConfig()
	cfg := config.AppConfig

	// 初始化数据库
	if err := config.InitDB(cfg); err != nil {
		log.Fatalf("数据库初始化失败: %v", err)
	}

	// 初始化 MinIO 服务
	minioConfig := services.MinIOConfig{
		Endpoint:        cfg.MinIOEndpoint,
		AccessKeyID:     cfg.MinIOAccessKeyID,
		SecretAccessKey: cfg.MinIOSecretAccessKey,
		BucketName:      cfg.MinIOBucketName,
		UseSSL:          cfg.MinIOUseSSL,
	}
	if err := services.InitMinIO(minioConfig); err != nil {
		log.Fatalf("MinIO 初始化失败: %v", err)
	}

	// 设置路由
	router := routes.SetupRouter()

	// 启动服务器
	log.Printf("服务器启动在 %s 端口", cfg.ServerPort)
	if err := router.Run(":" + cfg.ServerPort); err != nil {
		log.Fatalf("服务器启动失败: %v", err)
	}
}
