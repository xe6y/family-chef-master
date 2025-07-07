

USE family_chef;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    open_id VARCHAR(100) NOT NULL UNIQUE COMMENT '微信OpenID',
    union_id VARCHAR(100) NULL COMMENT '微信UnionID',
    nickname VARCHAR(50) NULL COMMENT '昵称',
    avatar VARCHAR(255) NULL COMMENT '头像URL',
    gender TINYINT DEFAULT 0 COMMENT '性别 0-未知 1-男 2-女',
    phone VARCHAR(20) NULL COMMENT '手机号',
    email VARCHAR(100) NULL COMMENT '邮箱',
    status TINYINT DEFAULT 1 COMMENT '状态 0-禁用 1-正常',
    last_login TIMESTAMP NULL COMMENT '最后登录时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_open_id (open_id),
    INDEX idx_union_id (union_id),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 家庭表
CREATE TABLE IF NOT EXISTS families (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT '家庭名称',
    description VARCHAR(500) NULL COMMENT '家庭描述',
    avatar VARCHAR(255) NULL COMMENT '家庭头像',
    owner_id BIGINT UNSIGNED NOT NULL COMMENT '一家之主ID',
    invite_code VARCHAR(20) NOT NULL UNIQUE COMMENT '邀请码',
    status TINYINT DEFAULT 1 COMMENT '状态 0-解散 1-正常',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_owner_id (owner_id),
    INDEX idx_invite_code (invite_code),
    INDEX idx_deleted_at (deleted_at),
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='家庭表';

-- 家庭成员表
CREATE TABLE IF NOT EXISTS family_members (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    family_id BIGINT UNSIGNED NOT NULL COMMENT '家庭ID',
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    role VARCHAR(20) DEFAULT 'member' COMMENT '角色 owner-一家之主 chef-主厨 foodie-美食家 cleaner-洗碗工 member-普通成员',
    nickname VARCHAR(50) NULL COMMENT '家庭内昵称',
    status TINYINT DEFAULT 1 COMMENT '状态 0-待审核 1-正常 2-禁用',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_family_id (family_id),
    INDEX idx_user_id (user_id),
    INDEX idx_role (role),
    UNIQUE KEY uk_family_user (family_id, user_id),
    FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='家庭成员表';

-- 邀请表
CREATE TABLE IF NOT EXISTS invitations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    family_id BIGINT UNSIGNED NOT NULL COMMENT '家庭ID',
    inviter_id BIGINT UNSIGNED NOT NULL COMMENT '邀请人ID',
    invitee_id BIGINT UNSIGNED NULL COMMENT '被邀请人ID',
    code VARCHAR(20) NOT NULL UNIQUE COMMENT '邀请码',
    type TINYINT DEFAULT 1 COMMENT '类型 1-家庭成员 2-临时客人',
    status TINYINT DEFAULT 0 COMMENT '状态 0-待接受 1-已接受 2-已拒绝 3-已过期',
    expire_at TIMESTAMP NULL COMMENT '过期时间',
    accepted_at TIMESTAMP NULL COMMENT '接受时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_family_id (family_id),
    INDEX idx_inviter_id (inviter_id),
    INDEX idx_invitee_id (invitee_id),
    INDEX idx_code (code),
    INDEX idx_status (status),
    FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE CASCADE,
    FOREIGN KEY (inviter_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (invitee_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='邀请表';

-- 食材表
CREATE TABLE IF NOT EXISTS ingredients (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    family_id BIGINT UNSIGNED NOT NULL COMMENT '家庭ID',
    name VARCHAR(100) NOT NULL COMMENT '食材名称',
    category VARCHAR(50) NULL COMMENT '分类',
    unit VARCHAR(20) NULL COMMENT '单位',
    stock DECIMAL(10,2) DEFAULT 0 COMMENT '库存数量',
    min_stock DECIMAL(10,2) DEFAULT 0 COMMENT '最低库存',
    location VARCHAR(100) NULL COMMENT '存放位置',
    expiry_date TIMESTAMP NULL COMMENT '保质期',
    price DECIMAL(10,2) DEFAULT 0 COMMENT '单价',
    status TINYINT DEFAULT 1 COMMENT '状态 0-禁用 1-正常',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_family_id (family_id),
    INDEX idx_category (category),
    INDEX idx_name (name),
    INDEX idx_deleted_at (deleted_at),
    FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='食材表';

-- 菜谱表
CREATE TABLE IF NOT EXISTS recipes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    family_id BIGINT UNSIGNED NOT NULL COMMENT '家庭ID',
    user_id BIGINT UNSIGNED NOT NULL COMMENT '创建者ID',
    name VARCHAR(100) NOT NULL COMMENT '菜谱名称',
    description VARCHAR(500) NULL COMMENT '菜谱描述',
    image VARCHAR(255) NULL COMMENT '菜品图片',
    cuisine VARCHAR(50) NULL COMMENT '菜系',
    taste VARCHAR(50) NULL COMMENT '口味',
    difficulty TINYINT DEFAULT 1 COMMENT '难度 1-5',
    cooking_time INT NULL COMMENT '烹饪时间(分钟)',
    serving_size INT NULL COMMENT '份量(人数)',
    steps TEXT NULL COMMENT '制作步骤',
    tutorial_url VARCHAR(255) NULL COMMENT '教程链接',
    tags VARCHAR(500) NULL COMMENT '标签(JSON格式)',
    is_private BOOLEAN DEFAULT FALSE COMMENT '是否私家菜',
    status TINYINT DEFAULT 1 COMMENT '状态 0-下架 1-上架',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_family_id (family_id),
    INDEX idx_user_id (user_id),
    INDEX idx_cuisine (cuisine),
    INDEX idx_taste (taste),
    INDEX idx_difficulty (difficulty),
    INDEX idx_status (status),
    INDEX idx_deleted_at (deleted_at),
    FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='菜谱表';

-- 菜谱食材表
CREATE TABLE IF NOT EXISTS recipe_ingredients (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    recipe_id BIGINT UNSIGNED NOT NULL COMMENT '菜谱ID',
    ingredient_id BIGINT UNSIGNED NOT NULL COMMENT '食材ID',
    amount DECIMAL(10,2) NULL COMMENT '用量',
    unit VARCHAR(20) NULL COMMENT '单位',
    note VARCHAR(200) NULL COMMENT '备注',
    INDEX idx_recipe_id (recipe_id),
    INDEX idx_ingredient_id (ingredient_id),
    UNIQUE KEY uk_recipe_ingredient (recipe_id, ingredient_id),
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='菜谱食材表';

-- 主厨拿手菜表
CREATE TABLE IF NOT EXISTS chef_skills (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    recipe_id BIGINT UNSIGNED NOT NULL COMMENT '菜谱ID',
    level TINYINT DEFAULT 1 COMMENT '熟练度 1-5',
    note VARCHAR(200) NULL COMMENT '备注',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_recipe_id (recipe_id),
    UNIQUE KEY uk_user_recipe (user_id, recipe_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='主厨拿手菜表';

-- 订单表
CREATE TABLE IF NOT EXISTS orders (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    family_id BIGINT UNSIGNED NOT NULL COMMENT '家庭ID',
    user_id BIGINT UNSIGNED NOT NULL COMMENT '下单用户ID',
    chef_id BIGINT UNSIGNED NULL COMMENT '指定厨师ID',
    order_no VARCHAR(50) NOT NULL UNIQUE COMMENT '订单号',
    type TINYINT DEFAULT 1 COMMENT '订单类型 1-普通点餐 2-宴请点餐',
    status TINYINT DEFAULT 0 COMMENT '订单状态 0-待确认 1-已确认 2-制作中 3-已完成 4-已取消',
    total_amount DECIMAL(10,2) DEFAULT 0 COMMENT '总金额',
    remark VARCHAR(500) NULL COMMENT '备注',
    expected_time TIMESTAMP NULL COMMENT '期望完成时间',
    completed_at TIMESTAMP NULL COMMENT '完成时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_family_id (family_id),
    INDEX idx_user_id (user_id),
    INDEX idx_chef_id (chef_id),
    INDEX idx_order_no (order_no),
    INDEX idx_status (status),
    INDEX idx_deleted_at (deleted_at),
    FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (chef_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单表';

-- 订单项表
CREATE TABLE IF NOT EXISTS order_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL COMMENT '订单ID',
    recipe_id BIGINT UNSIGNED NOT NULL COMMENT '菜谱ID',
    quantity INT DEFAULT 1 COMMENT '数量',
    price DECIMAL(10,2) DEFAULT 0 COMMENT '单价',
    amount DECIMAL(10,2) DEFAULT 0 COMMENT '小计',
    remark VARCHAR(200) NULL COMMENT '备注',
    INDEX idx_order_id (order_id),
    INDEX idx_recipe_id (recipe_id),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单项表';

-- 评价表
CREATE TABLE IF NOT EXISTS reviews (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL COMMENT '订单ID',
    recipe_id BIGINT UNSIGNED NOT NULL COMMENT '菜谱ID',
    user_id BIGINT UNSIGNED NOT NULL COMMENT '评价用户ID',
    rating TINYINT NOT NULL COMMENT '评分 1-5',
    content VARCHAR(500) NULL COMMENT '评价内容',
    images VARCHAR(1000) NULL COMMENT '图片URLs(JSON格式)',
    is_best BOOLEAN DEFAULT FALSE COMMENT '是否今日最佳',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_order_id (order_id),
    INDEX idx_recipe_id (recipe_id),
    INDEX idx_user_id (user_id),
    INDEX idx_rating (rating),
    INDEX idx_is_best (is_best),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评价表';

-- 家宴回忆表
CREATE TABLE IF NOT EXISTS memories (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    family_id BIGINT UNSIGNED NOT NULL COMMENT '家庭ID',
    recipe_id BIGINT UNSIGNED NULL COMMENT '菜谱ID',
    title VARCHAR(100) NOT NULL COMMENT '回忆标题',
    description VARCHAR(1000) NULL COMMENT '回忆描述',
    images VARCHAR(2000) NULL COMMENT '图片URLs(JSON格式)',
    event_date TIMESTAMP NOT NULL COMMENT '事件日期',
    participants VARCHAR(500) NULL COMMENT '参与者',
    tags VARCHAR(500) NULL COMMENT '标签(JSON格式)',
    share_code VARCHAR(50) NOT NULL UNIQUE COMMENT '分享码',
    status TINYINT DEFAULT 1 COMMENT '状态 0-私密 1-公开',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_family_id (family_id),
    INDEX idx_recipe_id (recipe_id),
    INDEX idx_event_date (event_date),
    INDEX idx_share_code (share_code),
    INDEX idx_deleted_at (deleted_at),
    FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='家宴回忆表';

-- 采购清单项表
CREATE TABLE IF NOT EXISTS purchase_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ingredient_id BIGINT UNSIGNED NOT NULL COMMENT '食材ID',
    quantity DECIMAL(10,2) NOT NULL COMMENT '采购数量',
    unit VARCHAR(20) NULL COMMENT '单位',
    price DECIMAL(10,2) DEFAULT 0 COMMENT '单价',
    amount DECIMAL(10,2) DEFAULT 0 COMMENT '小计',
    is_purchased BOOLEAN DEFAULT FALSE COMMENT '是否已购买',
    purchased_at TIMESTAMP NULL COMMENT '购买时间',
    remark VARCHAR(200) NULL COMMENT '备注',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_ingredient_id (ingredient_id),
    INDEX idx_is_purchased (is_purchased),
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='采购清单项表';

-- 插入初始数据
INSERT INTO users (open_id, nickname, avatar, status) VALUES 
('system_admin', '系统管理员', '', 1);

-- 创建索引优化查询性能
CREATE INDEX idx_families_status ON families(status);
CREATE INDEX idx_recipes_cuisine_taste ON recipes(cuisine, taste);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_reviews_created_at ON reviews(created_at);
CREATE INDEX idx_memories_event_date ON memories(event_date);
CREATE INDEX idx_ingredients_expiry_date ON ingredients(expiry_date); 