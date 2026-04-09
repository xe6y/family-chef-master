/// API配置文件
/// 包含后端服务器地址等配置信息
library;

class ApiConfig {
  /// 开发环境API地址
  static const String devBaseUrl = 'http://localhost:8080/api';

  /// 测试环境API地址
  static const String testBaseUrl = 'https://api-test.bitepal.com/api';

  /// 生产环境API地址
  static const String prodBaseUrl = 'https://api.bitepal.com/api';

  /// 当前使用的API地址（根据环境切换）
  static const String baseUrl = devBaseUrl;

  // ==================== 菜谱提取器服务 ====================

  /// 提取器服务开发环境地址（workflow/src/api.py，uvicorn 启动于 8100）
  static const String extractorDevUrl = 'http://localhost:8100';

  /// 提取器服务地址（当前使用）
  static const String extractorBaseUrl = extractorDevUrl;

  /// 请求超时时间（秒）
  static const int connectTimeout = 30;

  /// 响应超时时间（秒）
  static const int receiveTimeout = 30;

  // ==================== 认证接口 ====================
  /// 登录接口
  static const String login = '/auth/login';

  /// 注册接口
  static const String register = '/auth/register';

  // ==================== 用户接口 ====================
  /// 获取/更新用户信息
  static const String userInfo = '/user/info';

  /// 获取用户统计数据
  static const String userStats = '/user/stats';

  /// 获取/更新家庭成员偏好
  static const String userPreferences = '/user/preferences';

  // ==================== 菜谱接口 ====================
  /// 我的菜谱列表
  static const String myRecipes = '/recipes/my';

  /// 网络菜谱列表
  static const String publicRecipes = '/recipes/public';

  /// 菜谱详情/创建/更新/删除
  static const String recipes = '/recipes';

  /// 随机推荐菜品
  static const String randomRecipe = '/recipes/random';

  /// 检查链接是否已有对应的公开菜谱
  static const String publicRecipeCheckUrl = '/recipes/public/check-url';

  // ==================== 点餐接口 ====================
  /// 点餐基础路径
  static const String meals = '/meals';

  /// 点餐菜品列表
  static const String mealRecipes = '/meals/recipes';

  /// 点餐订单
  static const String mealOrders = '/meals/orders';

  // ==================== 食材分类接口 ====================
  /// 食材分类列表
  static const String ingredientCategories = '/ingredient-categories';

  // ==================== 单位与食材库（单位统一化） ====================
  /// 单位列表
  static const String units = '/units';

  /// 食材库列表/搜索
  static const String ingredientMaster = '/ingredient-master';

  // ==================== 食材接口 ====================
  /// 食材列表
  static const String ingredients = '/ingredients';

  /// 分组食材列表
  static const String ingredientsGrouped = '/ingredients/grouped';

  /// 即将过期食材
  static const String expiringIngredients = '/ingredients/expiring';

  /// 同名食材批次
  static const String ingredientBatches = '/ingredients/batches';

  // ==================== 存储位置接口 ====================
  /// 存储位置列表
  static const String storageLocations = '/storage-locations';

  /// 存储位置排序
  static const String storageLocationsReorder = '/storage-locations/reorder';

  // ==================== 购物清单接口 ====================
  /// 购物清单列表
  static const String shoppingLists = '/shopping-lists';

  /// 当前购物清单
  static const String currentShoppingList = '/shopping-lists/current';

  /// 购物清单历史
  static const String shoppingHistory = '/shopping-lists/history';

  /// 购物清单历史商品项
  static const String shoppingHistoryItems = '/shopping-lists/history/items';

  // ==================== 文件上传接口 ====================
  /// 图片上传
  static const String uploadImage = '/upload/image';

  // ==================== 家庭管理接口 ====================
  /// 家庭信息
  static const String family = '/family';

  /// 加入家庭
  static const String familyJoin = '/family/join';

  /// 退出家庭
  static const String familyLeave = '/family/leave';

  /// 刷新邀请码
  static const String familyInviteCode = '/family/invite-code';

  /// 家庭成员
  static const String familyMembers = '/family/members';

  // ==================== 菜谱分类接口 ====================
  /// 菜谱分类列表
  static const String recipeCategories = '/categories';

  // ==================== 用户标签接口 ====================
  /// 用户常用标签
  static const String userTags = '/user-tags';

  // ==================== 菜单缓存接口 ====================
  /// 菜单缓存（家庭共享菜单）
  static const String menuCache = '/menu-cache';
}
