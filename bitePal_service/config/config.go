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
	DefaultDBHost     = "127.0.0.1" // 默认数据库主机
	DefaultDBPort     = "3306"      // 默认数据库端口
	DefaultDBName     = "zuoban"    // 默认数据库名
	DefaultDBUser     = "zuoban"    // 默认数据库用户名
	DefaultDBPassword = "develop"   // 默认数据库密码
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

