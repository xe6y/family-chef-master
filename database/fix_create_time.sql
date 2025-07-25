-- 修复create_time字段的无效日期
UPDATE system_user SET create_time = NOW() WHERE create_time = '0000-00-00 00:00:00' OR create_time IS NULL;

-- 确保create_time字段有默认值
ALTER TABLE system_user MODIFY COLUMN create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP; 