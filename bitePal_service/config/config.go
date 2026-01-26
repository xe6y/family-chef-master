package config

import (
	"os"
)

// 默认配置值
const (
	DefaultServerPort = "8080"           // 默认服务端口
	DefaultJWTSecret  = "bitepal_secret" // 默认JWT密钥（生产环境请修改）
	DefaultJWTExpiry  = 168              // 默认Token有效期（小时），7天

	// 数据库配置默认值
	DefaultDBHost     = "127.0.0.1"   // 默认数据库主机
	DefaultDBPort     = "5432"        // 默认数据库端口（PostgreSQL）
	DefaultDBName     = "zuoban"      // 默认数据库名
	DefaultDBUser     = "zuoban"      // 默认数据库用户名
	DefaultDBPassword = "luohan@0913" // 默认数据库密码

	// MinIO 配置默认值
	DefaultMinIOEndpoint        = "localhost:9000"                           // 默认 MinIO 服务地址
	DefaultMinIOAccessKeyID     = "HZsgrWpbzukFCtWLCVDd"                     // 默认访问密钥 ID
	DefaultMinIOSecretAccessKey = "Siq70i4I73UU4czF6xkqOjFjvh3EXnuwxcRjpqnS" // 默认访问密钥
	DefaultMinIOBucketName      = "zuoban"                                   // 默认存储桶名称
	DefaultMinIOUseSSL          = false                                      // 默认不使用 SSL
)

// Config 应用配置结构
type Config struct {
	ServerPort string // 服务端口
	JWTSecret  string // JWT密钥
	JWTExpiry  int    // JWT有效期（小时）

	// 数据库配置
	DBHost     string // 数据库主机
	DBPort     string // 数据库端口
	DBName     string // 数据库名
	DBUser     string // 数据库用户名
	DBPassword string // 数据库密码

	// MinIO 配置
	MinIOEndpoint        string // MinIO 服务地址
	MinIOAccessKeyID     string // 访问密钥 ID
	MinIOSecretAccessKey string // 访问密钥
	MinIOBucketName      string // 存储桶名称
	MinIOUseSSL          bool   // 是否使用 SSL
}

// LoadConfig 加载配置
// 优先从环境变量读取，否则使用默认值
func LoadConfig() *Config {
	return &Config{
		ServerPort: getEnvOrDefault("SERVER_PORT", DefaultServerPort),
		JWTSecret:  getEnvOrDefault("JWT_SECRET", DefaultJWTSecret),
		JWTExpiry:  DefaultJWTExpiry,

		// 数据库配置
		DBHost:     getEnvOrDefault("DB_HOST", DefaultDBHost),
		DBPort:     getEnvOrDefault("DB_PORT", DefaultDBPort),
		DBName:     getEnvOrDefault("DB_NAME", DefaultDBName),
		DBUser:     getEnvOrDefault("DB_USER", DefaultDBUser),
		DBPassword: getEnvOrDefault("DB_PASSWORD", DefaultDBPassword),

		// MinIO 配置
		MinIOEndpoint:        getEnvOrDefault("MINIO_ENDPOINT", DefaultMinIOEndpoint),
		MinIOAccessKeyID:     getEnvOrDefault("MINIO_ACCESS_KEY_ID", DefaultMinIOAccessKeyID),
		MinIOSecretAccessKey: getEnvOrDefault("MINIO_SECRET_ACCESS_KEY", DefaultMinIOSecretAccessKey),
		MinIOBucketName:      getEnvOrDefault("MINIO_BUCKET_NAME", DefaultMinIOBucketName),
		MinIOUseSSL:          getEnvOrDefault("MINIO_USE_SSL", "false") == "true",
	}
}

// getEnvOrDefault 获取环境变量，如果不存在则返回默认值
// envKey: 环境变量名
// defaultVal: 默认值
// 返回: 环境变量值或默认值
func getEnvOrDefault(envKey, defaultVal string) string {
	if value := os.Getenv(envKey); value != "" {
		return value
	}
	return defaultVal
}

// AppConfig 全局配置实例
var AppConfig *Config

// InitConfig 初始化全局配置
func InitConfig() {
	AppConfig = LoadConfig()
}
