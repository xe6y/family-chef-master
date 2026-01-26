-- 迁移脚本：修改 ingredient_items 表的 storage 字段长度
-- 从 varchar(20) 改为 varchar(36) 以支持 UUID 格式的存储位置 ID
-- 执行日期：2026-01-26

-- 修改 storage 字段长度
ALTER TABLE `ingredient_items` MODIFY COLUMN `storage` VARCHAR(36);

-- 验证修改
DESCRIBE `ingredient_items`;
