-- 为用户表添加角色字段
ALTER TABLE system_user ADD COLUMN role VARCHAR(50) DEFAULT NULL COMMENT '用户角色：chef(大厨), foodie(美食家)'; 