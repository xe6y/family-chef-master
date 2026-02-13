-- 公共菜谱模拟数据 (PostgreSQL)
-- 清空现有数据（可选）
-- TRUNCATE TABLE public_recipes;

-- 1. 番茄炒蛋
INSERT INTO public_recipes (id, name, time, difficulty, tags, tag_colors, ingredients, steps, created_at, updated_at)
VALUES (
  'recipe-001',
  '番茄炒蛋',
  '15分钟',
  '有手就行',
  '["家常菜", "快手菜", "下饭菜"]'::jsonb,
  '["#B2AC88", "#E67E22", "#E74C3C"]'::jsonb,
  '[{"name":"番茄","amount":"2个"},{"name":"鸡蛋","amount":"3个"},{"name":"葱花","amount":"适量"},{"name":"盐","amount":"适量"},{"name":"糖","amount":"1勺"}]'::jsonb,
  '["番茄洗净切块，鸡蛋打散备用","热锅倒油，倒入蛋液炒至凝固盛出","锅中再倒油，放入番茄翻炒出汁","加入炒好的鸡蛋，加盐和糖调味","翻炒均匀，撒上葱花即可出锅"]'::jsonb,
  NOW(),
  NOW()
);

-- 2. 宫保鸡丁
INSERT INTO public_recipes (id, name, time, difficulty, tags, tag_colors, ingredients, steps, created_at, updated_at)
VALUES (
  'recipe-002',
  '宫保鸡丁',
  '25分钟',
  '家常便饭',
  '["川菜", "下饭菜", "经典菜"]'::jsonb,
  '["#E74C3C", "#E67E22", "#B2AC88"]'::jsonb,
  '[{"name":"鸡胸肉","amount":"300g"},{"name":"花生米","amount":"100g"},{"name":"干辣椒","amount":"10个"},{"name":"花椒","amount":"1勺"},{"name":"葱姜蒜","amount":"适量"}]'::jsonb,
  '["鸡胸肉切丁，加料酒、生抽腌制15分钟","调制宫保汁：生抽、醋、糖、水淀粉混合","热锅凉油，炸花生米至金黄捞出","锅中留底油，爆香干辣椒和花椒","倒入鸡丁快速翻炒至变色","加入葱姜蒜继续翻炒","倒入宫保汁，大火收汁","最后加入花生米翻炒均匀即可"]'::jsonb,
  NOW(),
  NOW()
);

-- 3. 红烧肉
INSERT INTO public_recipes (id, name, time, difficulty, tags, tag_colors, ingredients, steps, created_at, updated_at)
VALUES (
  'recipe-003',
  '红烧肉',
  '90分钟',
  '餐厅招牌',
  '["硬菜", "宴客菜", "经典菜"]'::jsonb,
  '["#E74C3C", "#F39C12", "#B2AC88"]'::jsonb,
  '[{"name":"五花肉","amount":"500g"},{"name":"冰糖","amount":"30g"},{"name":"生抽","amount":"3勺"},{"name":"老抽","amount":"1勺"},{"name":"料酒","amount":"2勺"}]'::jsonb,
  '["五花肉切2cm见方的块，冷水下锅焯水","锅中放少许油，加冰糖小火炒至焦糖色","倒入五花肉快速翻炒上色","加入葱姜、八角、桂皮、香叶爆香","倒入料酒、生抽、老抽翻炒均匀","加开水没过肉块，大火烧开","转小火慢炖60分钟","大火收汁至浓稠即可"]'::jsonb,
  NOW(),
  NOW()
);
