-- 菜单缓存表（UNLOGGED TABLE）
-- 用于多人协同编辑菜单，提高性能，数据不持久化到 WAL
-- 注意：UNLOGGED TABLE 在数据库崩溃时会丢失数据，适合临时缓存

-- 创建菜单缓存表
CREATE UNLOGGED TABLE IF NOT EXISTS menu_cache (
  id VARCHAR(50) PRIMARY KEY,                    -- 缓存ID（格式：family_id:date）
  family_id VARCHAR(50) NOT NULL,                -- 家庭ID
  date DATE NOT NULL,                            -- 日期
  recipe_id VARCHAR(50) NOT NULL,                -- 菜谱ID
  recipe_name VARCHAR(200) NOT NULL,             -- 菜谱名称（冗余，减少查询）
  source VARCHAR(20) NOT NULL,                   -- 来源（my/online）
  selected_by JSONB DEFAULT '[]'::jsonb,         -- 选择者列表 [{id, name, avatar}]
  is_checked BOOLEAN DEFAULT true,               -- 是否勾选
  added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- 添加时间
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- 更新时间
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_menu_cache_family_date
  ON menu_cache(family_id, date);

CREATE INDEX IF NOT EXISTS idx_menu_cache_recipe
  ON menu_cache(recipe_id);

CREATE INDEX IF NOT EXISTS idx_menu_cache_updated
  ON menu_cache(updated_at);

-- 添加注释
COMMENT ON TABLE menu_cache IS '菜单缓存表（UNLOGGED），用于多人协同编辑';
COMMENT ON COLUMN menu_cache.id IS '缓存ID，格式：family_id:date:recipe_id';
COMMENT ON COLUMN menu_cache.family_id IS '家庭ID';
COMMENT ON COLUMN menu_cache.date IS '日期';
COMMENT ON COLUMN menu_cache.recipe_id IS '菜谱ID';
COMMENT ON COLUMN menu_cache.recipe_name IS '菜谱名称（冗余字段）';
COMMENT ON COLUMN menu_cache.source IS '来源：my（我的私房）或 online（网络菜谱）';
COMMENT ON COLUMN menu_cache.selected_by IS '选择者列表，JSON数组';
COMMENT ON COLUMN menu_cache.is_checked IS '是否勾选（用于确认点餐）';
COMMENT ON COLUMN menu_cache.added_at IS '添加时间';
COMMENT ON COLUMN menu_cache.updated_at IS '更新时间';
