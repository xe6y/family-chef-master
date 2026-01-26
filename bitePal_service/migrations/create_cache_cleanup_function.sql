-- 缓存清理函数
-- 清理过期的菜单缓存（超过3天的数据）

CREATE OR REPLACE FUNCTION clean_expired_menu_cache()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- 删除3天前的缓存数据
  DELETE FROM menu_cache
  WHERE date < CURRENT_DATE - INTERVAL '3 days';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;

  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 添加注释
COMMENT ON FUNCTION clean_expired_menu_cache() IS '清理过期的菜单缓存（超过3天）';
