# BitePal UI - 项目结构文档

## 项目概述
BitePal（做伴）是一个Flutter移动应用，用于家庭点餐和食谱管理。

## 目录结构

```
lib/
├── config/              # 配置文件（当前为空，可用于API配置等）
├── models/              # 数据模型
│   ├── recipe.dart              # 食谱模型
│   ├── ingredient_item.dart      # 食材模型
│   ├── shopping_item.dart        # 购物清单模型
│   └── chat_message.dart         # 聊天消息模型
├── providers/           # 状态管理（当前为空，可用于Provider/Riverpod等）
├── screens/             # 页面/屏幕
│   ├── home_screen.dart          # 首页
│   ├── recipes_screen.dart       # 食谱列表页
│   ├── meals_screen.dart          # 点餐页面（家庭点餐）
│   ├── recipe_detail_screen.dart  # 食谱详情页
│   ├── ingredients_screen.dart   # 食材管理页
│   ├── shopping_screen.dart       # 购物清单页
│   └── profile_screen.dart        # 个人资料页
├── services/            # 服务层
│   └── mock_data_service.dart     # 模拟数据服务
├── utils/               # 工具类
│   ├── app_theme.dart             # 应用主题配置
│   └── app_constants.dart         # 应用常量定义
├── widgets/             # 可复用组件
│   ├── bottom_nav.dart            # 底部导航栏
│   ├── recipe_card.dart            # 食谱卡片组件
│   ├── edit_item_dialog.dart      # 编辑对话框
│   └── random_meal_dialog.dart    # 随机餐点对话框
└── main.dart            # 应用入口
```

## 核心功能

### 1. 首页 (HomeScreen)
- 显示今日推荐食谱
- 显示即将过期的食材提醒

### 2. 食谱列表 (RecipesScreen)
- 我的食谱
- 在线食谱

### 3. 点餐页面 (MealsScreen) ⭐
- 搜索和筛选功能
- 菜品网格展示
- 添加菜品到点菜单（+按钮）
- 已点菜品标记（绿色徽章）
- 浮动清单按钮查看已点菜品
- 支持口味、食材状态、类型、菜系筛选

### 4. 食谱详情 (RecipeDetailScreen)
- 显示食谱详细信息
- 食材列表
- 制作步骤

### 5. 食材管理 (IngredientsScreen)
- 食材分类管理
- 过期提醒

### 6. 购物清单 (ShoppingScreen)
- 购物清单管理
- 价格统计

## 数据模型

### Recipe（食谱）
- id: 唯一标识
- name: 名称
- image: 图片URL（可选）
- time: 制作时间
- difficulty: 难度
- tags: 标签列表
- tagColors: 标签颜色
- favorite: 是否收藏
- categories: 分类（口味/菜系）
- ingredients: 食材列表（可选）
- steps: 制作步骤（可选）

### IngredientItem（食材）
- id: 唯一标识
- name: 名称
- amount: 数量
- category: 分类（room/fridge/freezer）
- icon: 图标
- expiryDays: 过期天数
- expiryText: 过期文本
- urgent: 是否紧急

### ShoppingItem（购物项）
- id: 唯一标识
- name: 名称
- amount: 数量
- price: 价格
- checked: 是否已勾选

## 关键组件

### RecipeCard（食谱卡片）
- 显示食谱基本信息
- 支持点击查看详情
- 支持添加到点菜单（+按钮）
- 显示已添加状态（绿色徽章）
- 显示口味标签

### 常量管理 (AppConstants)
统一管理：
- 间距常量（spacingXS ~ spacingXXL）
- 卡片相关尺寸
- 按钮尺寸
- 颜色常量
- 文本尺寸
- 动画时长

## 技术栈
- Flutter SDK: ^3.10.3
- Material Design 3
- 支持深色模式

## 代码优化亮点

1. **常量统一管理**: 所有魔法数字和颜色值集中在 `AppConstants` 中
2. **数据服务分离**: 示例数据统一在 `MockDataService` 中管理
3. **模型类增强**: 添加了 `copyWith` 方法支持不可变更新
4. **组件复用**: `RecipeCard` 可在多个页面复用
5. **代码组织**: 清晰的目录结构，职责分离

## 待优化项

1. 添加状态管理（Provider/Riverpod/Bloc）
2. 实现数据持久化（SharedPreferences/Hive）
3. 添加网络请求层（API服务）
4. 完善错误处理
5. 添加单元测试和集成测试
6. 国际化支持（i18n）

