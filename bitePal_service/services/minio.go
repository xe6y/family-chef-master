package services

import (
	"context"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"path/filepath"
	"time"

	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// MinIOService MinIO 对象存储服务
type MinIOService struct {
	client     *minio.Client
	bucketName string
	endpoint   string
}

// MinIOConfig MinIO 配置
type MinIOConfig struct {
	Endpoint        string // MinIO 服务地址（例如：localhost:9000）
	AccessKeyID     string // 访问密钥 ID
	SecretAccessKey string // 访问密钥
	BucketName      string // 存储桶名称
	UseSSL          bool   // 是否使用 SSL
}

var minioService *MinIOService

// InitMinIO 初始化 MinIO 服务
func InitMinIO(config MinIOConfig) error {
	// 创建 MinIO 客户端
	client, err := minio.New(config.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(config.AccessKeyID, config.SecretAccessKey, ""),
		Secure: config.UseSSL,
	})
	if err != nil {
		return fmt.Errorf("创建 MinIO 客户端失败: %w", err)
	}

	// 检查存储桶是否存在，不存在则创建
	ctx := context.Background()
	exists, err := client.BucketExists(ctx, config.BucketName)
	if err != nil {
		return fmt.Errorf("检查存储桶失败: %w", err)
	}

	if !exists {
		err = client.MakeBucket(ctx, config.BucketName, minio.MakeBucketOptions{})
		if err != nil {
			return fmt.Errorf("创建存储桶失败: %w", err)
		}
		log.Printf("存储桶 %s 创建成功", config.BucketName)
	}

	// 设置存储桶为公开读取（可选）
	policy := fmt.Sprintf(`{
		"Version": "2012-10-17",
		"Statement": [
			{
				"Effect": "Allow",
				"Principal": {"AWS": ["*"]},
				"Action": ["s3:GetObject"],
				"Resource": ["arn:aws:s3:::%s/*"]
			}
		]
	}`, config.BucketName)

	err = client.SetBucketPolicy(ctx, config.BucketName, policy)
	if err != nil {
		log.Printf("设置存储桶策略失败: %v", err)
	}

	minioService = &MinIOService{
		client:     client,
		bucketName: config.BucketName,
		endpoint:   config.Endpoint,
	}

	log.Printf("MinIO 服务初始化成功，存储桶: %s", config.BucketName)
	return nil
}

// GetMinIOService 获取 MinIO 服务实例
func GetMinIOService() *MinIOService {
	return minioService
}

// UploadFile 上传文件到 MinIO
// file: 文件内容
// header: 文件头信息
// folder: 存储文件夹（例如：images、avatars）
// 返回: 文件 URL 和错误
func (s *MinIOService) UploadFile(file multipart.File, header *multipart.FileHeader, folder string) (string, error) {
	ctx := context.Background()

	// 生成唯一文件名
	ext := filepath.Ext(header.Filename)
	filename := fmt.Sprintf("%s/%s_%s%s", folder, time.Now().Format("20060102"), uuid.New().String(), ext)

	// 获取文件大小
	fileSize := header.Size

	// 获取文件类型
	contentType := header.Header.Get("Content-Type")

	// 上传文件
	_, err := s.client.PutObject(ctx, s.bucketName, filename, file, fileSize, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return "", fmt.Errorf("上传文件失败: %w", err)
	}

	// 构建文件 URL
	fileURL := fmt.Sprintf("http://%s/%s/%s", s.endpoint, s.bucketName, filename)

	return fileURL, nil
}

// UploadFileFromReader 从 io.Reader 上传文件
// reader: 文件读取器
// filename: 文件名
// size: 文件大小
// contentType: 文件类型
// folder: 存储文件夹
// 返回: 文件 URL 和错误
func (s *MinIOService) UploadFileFromReader(reader io.Reader, filename string, size int64, contentType, folder string) (string, error) {
	ctx := context.Background()

	// 生成唯一文件名
	ext := filepath.Ext(filename)
	objectName := fmt.Sprintf("%s/%s_%s%s", folder, time.Now().Format("20060102"), uuid.New().String(), ext)

	// 上传文件
	_, err := s.client.PutObject(ctx, s.bucketName, objectName, reader, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return "", fmt.Errorf("上传文件失败: %w", err)
	}

	// 构建文件 URL
	fileURL := fmt.Sprintf("http://%s/%s/%s", s.endpoint, s.bucketName, objectName)

	return fileURL, nil
}

// DeleteFile 删除文件
// fileURL: 文件 URL
// 返回: 错误
func (s *MinIOService) DeleteFile(fileURL string) error {
	ctx := context.Background()

	// 从 URL 中提取对象名称
	// 例如：http://localhost:9000/bitepal/images/20260126_xxx.jpg -> images/20260126_xxx.jpg
	objectName := extractObjectName(fileURL, s.endpoint, s.bucketName)
	if objectName == "" {
		return fmt.Errorf("无效的文件 URL")
	}

	// 删除对象
	err := s.client.RemoveObject(ctx, s.bucketName, objectName, minio.RemoveObjectOptions{})
	if err != nil {
		return fmt.Errorf("删除文件失败: %w", err)
	}

	return nil
}

// extractObjectName 从 URL 中提取对象名称
func extractObjectName(fileURL, endpoint, bucketName string) string {
	prefix := fmt.Sprintf("http://%s/%s/", endpoint, bucketName)
	if len(fileURL) > len(prefix) && fileURL[:len(prefix)] == prefix {
		return fileURL[len(prefix):]
	}
	return ""
}

