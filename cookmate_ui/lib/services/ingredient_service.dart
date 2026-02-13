import '../config/api_config.dart';
import '../models/ingredient_item.dart';
import 'http_client.dart';

/// 食材服务
/// 处理食材库存的增删改查
class IngredientService {
  /// HTTP客户端
  final HttpClient _client = HttpClient();

  /// 单例实例
  static final IngredientService _instance = IngredientService._internal();

  /// 工厂构造函数
  factory IngredientService() => _instance;

  /// 私有构造函数
  IngredientService._internal();

  /// 获取食材列表
  /// storage: 存储位置筛选（room/fridge/freezer）
  /// categoryId: 分类ID筛选
  /// urgent: 是否只显示紧急
  /// expiringDays: 过期天数筛选
  /// 返回: 食材列表
  Future<List<IngredientItem>> getIngredients({
    String? storage,
    String? categoryId,
    bool? urgent,
    int? expiringDays,
    String? category, // 兼容旧版本
  }) async {
    final response = await _client.get(
      ApiConfig.ingredients,
      queryParams: {
        if (storage != null) 'storage': storage,
        if (category != null && storage == null) 'category': category,
        if (categoryId != null) 'categoryId': categoryId,
        if (urgent != null) 'urgent': urgent,
        if (expiringDays != null) 'expiringDays': expiringDays,
      },
    );

    if (response.isSuccess && response.data != null) {
      return (response.data['list'] as List? ?? [])
          .map((e) => IngredientItem.fromJson(e))
          .toList();
    }

    return [];
  }

  /// 获取分组的食材列表
  /// storage: 存储位置筛选（room/fridge/freezer）
  /// 返回: 按分类分组的食材列表
  Future<List<IngredientGroup>> getIngredientsGrouped({
    String? storage,
  }) async {
    final response = await _client.get(
      ApiConfig.ingredientsGrouped,
      queryParams: {
        if (storage != null) 'storage': storage,
      },
    );

    if (response.isSuccess && response.data != null) {
      return (response.data['groups'] as List? ?? [])
          .map((e) => IngredientGroup.fromJson(e))
          .toList();
    }

    return [];
  }

  /// 获取即将过期食材
  /// days: 天数（默认3，表示3天内过期）
  /// 返回: 即将过期的食材列表
  Future<List<IngredientItem>> getExpiringIngredients({int days = 3}) async {
    final response = await _client.get(
      ApiConfig.expiringIngredients,
      queryParams: {'days': days},
    );

    if (response.isSuccess && response.data != null) {
      return (response.data['list'] as List? ?? [])
          .map((e) => IngredientItem.fromJson(e))
          .toList();
    }

    return [];
  }

  /// 获取同食材库的所有批次（支持按食材库ID或名称）
  /// ingredientId: 食材库ID（单位统一化）
  /// name: 食材名称（兼容旧版）
  Future<List<IngredientItem>> getIngredientBatches(String name, {String? ingredientId}) async {
    final queryParams = <String, String>{};
    if (ingredientId != null && ingredientId.isNotEmpty) {
      queryParams['ingredientId'] = ingredientId;
    } else {
      queryParams['name'] = name;
    }
    final response = await _client.get(
      ApiConfig.ingredientBatches,
      queryParams: queryParams,
    );

    if (response.isSuccess && response.data != null) {
      return (response.data['list'] as List? ?? [])
          .map((e) => IngredientItem.fromJson(e))
          .toList();
    }

    return [];
  }

  /// 获取食材详情
  /// ingredientId: 食材ID
  /// 返回: 食材详情
  Future<IngredientItem?> getIngredientDetail(String ingredientId) async {
    final response = await _client.get(
      '${ApiConfig.ingredients}/$ingredientId',
    );

    if (response.isSuccess && response.data != null) {
      return IngredientItem.fromJson(response.data);
    }

    return null;
  }

  /// 添加食材（单位统一化：ingredientId + quantity + unitId 必填）
  Future<IngredientItem?> createIngredient({
    required String ingredientId,
    required double quantity,
    required String unitId,
    String? name,
    String? unit,
    String? amount,
    String? storage,
    String? categoryId,
    String? thumbnail,
    String? icon,
    String? note,
    String? expiryDate,
    String? purchaseDate,
    String? category,
  }) async {
    final response = await _client.post(
      ApiConfig.ingredients,
      data: {
        'ingredientId': ingredientId,
        'quantity': quantity,
        'unitId': unitId,
        if (name != null) 'name': name,
        if (unit != null) 'unit': unit,
        if (amount != null) 'amount': amount,
        if (storage != null) 'storage': storage,
        if (category != null && storage == null) 'storage': category,
        if (categoryId != null) 'categoryId': categoryId,
        if (thumbnail != null) 'thumbnail': thumbnail,
        if (icon != null) 'icon': icon,
        if (note != null) 'note': note,
        if (expiryDate != null) 'expiryDate': expiryDate,
        if (purchaseDate != null) 'purchaseDate': purchaseDate,
      },
    );

    if (response.isSuccess && response.data != null) {
      return IngredientItem.fromJson(response.data);
    }

    return null;
  }

  /// 更新食材
  /// itemId: 库存条目标识（路径参数）
  Future<IngredientItem?> updateIngredient(
    String itemId, {
    String? ingredientId,
    double? quantity,
    String? unitId,
    String? name,
    String? unit,
    String? amount,
    String? storage,
    String? categoryId,
    String? thumbnail,
    String? icon,
    String? note,
    String? expiryDate,
    String? purchaseDate,
    String? category,
  }) async {
    final response = await _client.put(
      '${ApiConfig.ingredients}/$itemId',
      data: {
        if (ingredientId != null) 'ingredientId': ingredientId,
        if (unitId != null) 'unitId': unitId,
        if (name != null) 'name': name,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (amount != null) 'amount': amount,
        if (storage != null) 'storage': storage,
        if (category != null && storage == null) 'storage': category,
        if (categoryId != null) 'categoryId': categoryId,
        if (thumbnail != null) 'thumbnail': thumbnail,
        if (icon != null) 'icon': icon,
        if (note != null) 'note': note,
        if (expiryDate != null) 'expiryDate': expiryDate,
        if (purchaseDate != null) 'purchaseDate': purchaseDate,
      },
    );

    if (response.isSuccess && response.data != null) {
      return IngredientItem.fromJson(response.data);
    }

    return null;
  }

  /// 删除食材
  /// ingredientId: 食材ID
  /// 返回: 是否删除成功
  Future<bool> deleteIngredient(String ingredientId) async {
    final response = await _client.delete(
      '${ApiConfig.ingredients}/$ingredientId',
    );
    return response.isSuccess;
  }
}

/// 食材分类服务
/// 处理食材分类的增删改查
class IngredientCategoryService {
  /// HTTP客户端
  final HttpClient _client = HttpClient();

  /// 单例实例
  static final IngredientCategoryService _instance =
      IngredientCategoryService._internal();

  /// 工厂构造函数
  factory IngredientCategoryService() => _instance;

  /// 私有构造函数
  IngredientCategoryService._internal();

  /// 获取食材分类列表
  /// 返回: 分类列表
  Future<List<IngredientCategory>> getCategories() async {
    final response = await _client.get(ApiConfig.ingredientCategories);

    if (response.isSuccess && response.data != null) {
      return (response.data['list'] as List? ?? [])
          .map((e) => IngredientCategory.fromJson(e))
          .toList();
    }

    return _getDefaultCategories();
  }

  /// 获取分类详情
  /// categoryId: 分类ID
  /// 返回: 分类详情
  Future<IngredientCategory?> getCategoryDetail(String categoryId) async {
    final response = await _client.get(
      '${ApiConfig.ingredientCategories}/$categoryId',
    );

    if (response.isSuccess && response.data != null) {
      return IngredientCategory.fromJson(response.data);
    }

    return null;
  }

  /// 创建分类
  /// name: 分类名称
  /// icon: 分类图标
  /// color: 分类颜色
  /// sortOrder: 排序顺序
  /// 返回: 创建的分类
  Future<IngredientCategory?> createCategory({
    required String name,
    String? icon,
    String? color,
    int? sortOrder,
  }) async {
    final response = await _client.post(
      ApiConfig.ingredientCategories,
      data: {
        'name': name,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        if (sortOrder != null) 'sortOrder': sortOrder,
      },
    );

    if (response.isSuccess && response.data != null) {
      return IngredientCategory.fromJson(response.data);
    }

    return null;
  }

  /// 更新分类
  /// categoryId: 分类ID
  /// 其他参数: 需要更新的字段
  /// 返回: 更新后的分类
  Future<IngredientCategory?> updateCategory(
    String categoryId, {
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
  }) async {
    final response = await _client.put(
      '${ApiConfig.ingredientCategories}/$categoryId',
      data: {
        if (name != null) 'name': name,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        if (sortOrder != null) 'sortOrder': sortOrder,
      },
    );

    if (response.isSuccess && response.data != null) {
      return IngredientCategory.fromJson(response.data);
    }

    return null;
  }

  /// 删除分类
  /// categoryId: 分类ID
  /// 返回: 是否删除成功
  Future<bool> deleteCategory(String categoryId) async {
    final response = await _client.delete(
      '${ApiConfig.ingredientCategories}/$categoryId',
    );
    return response.isSuccess;
  }

  /// 获取默认分类列表（离线时使用）
  List<IngredientCategory> _getDefaultCategories() {
    return [
      IngredientCategory(
        id: 'cat_meat',
        name: '肉类',
        icon: '🥩',
        color: '#E53935',
        sortOrder: 1,
        isSystem: true,
      ),
      IngredientCategory(
        id: 'cat_vegetable',
        name: '蔬菜',
        icon: '🥬',
        color: '#43A047',
        sortOrder: 2,
        isSystem: true,
      ),
      IngredientCategory(
        id: 'cat_fruit',
        name: '水果',
        icon: '🍎',
        color: '#FB8C00',
        sortOrder: 3,
        isSystem: true,
      ),
      IngredientCategory(
        id: 'cat_seafood',
        name: '海鲜',
        icon: '🦐',
        color: '#039BE5',
        sortOrder: 4,
        isSystem: true,
      ),
      IngredientCategory(
        id: 'cat_dairy',
        name: '奶制品',
        icon: '🥛',
        color: '#FDD835',
        sortOrder: 5,
        isSystem: true,
      ),
      IngredientCategory(
        id: 'cat_grain',
        name: '谷物',
        icon: '🌾',
        color: '#8D6E63',
        sortOrder: 6,
        isSystem: true,
      ),
      IngredientCategory(
        id: 'cat_egg',
        name: '蛋类',
        icon: '🥚',
        color: '#FFB74D',
        sortOrder: 7,
        isSystem: true,
      ),
      IngredientCategory(
        id: 'cat_seasoning',
        name: '调味料',
        icon: '🧂',
        color: '#78909C',
        sortOrder: 8,
        isSystem: true,
      ),
      IngredientCategory(
        id: 'cat_other',
        name: '其他',
        icon: '📦',
        color: '#9E9E9E',
        sortOrder: 99,
        isSystem: true,
      ),
    ];
  }
}
