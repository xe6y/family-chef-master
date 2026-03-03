import '../config/api_config.dart';
import '../models/recipe.dart';
import '../models/user.dart';
import 'http_client.dart';

/// 菜单缓存项
class MenuCacheItem {
  final String id;
  final String familyId;
  final DateTime date;
  final String recipeId;
  final String recipeName;
  final String source; // "my" 或 "online"
  final List<FamilyMember> selectedBy;
  final bool isChecked;
  final DateTime addedAt;
  final DateTime updatedAt;

  MenuCacheItem({
    required this.id,
    required this.familyId,
    required this.date,
    required this.recipeId,
    required this.recipeName,
    required this.source,
    required this.selectedBy,
    required this.isChecked,
    required this.addedAt,
    required this.updatedAt,
  });

  factory MenuCacheItem.fromJson(Map<String, dynamic> json) {
    return MenuCacheItem(
      id: json['id'] ?? '',
      familyId: json['familyId'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      recipeId: json['recipeId'] ?? '',
      recipeName: json['recipeName'] ?? '',
      source: json['source'] ?? 'my',
      selectedBy: (json['selectedBy'] as List? ?? [])
          .map((e) => FamilyMember.fromJson(e))
          .toList(),
      isChecked: json['isChecked'] ?? true,
      addedAt: DateTime.parse(
        json['addedAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'date': date.toIso8601String().split('T')[0],
      'recipeId': recipeId,
      'recipeName': recipeName,
      'source': source,
      'selectedBy': selectedBy.map((e) => e.toJson()).toList(),
      'isChecked': isChecked,
      'addedAt': addedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 转换为 Recipe 对象（用于显示）
  Recipe toRecipe() {
    return Recipe(
      id: recipeId,
      name: recipeName,
      time: '',
      difficulty: '',
      tags: [],
      tagColors: [],
      categories: [],
      ingredients: [],
      steps: [],
      favorite: false,
      isPublic: source == 'online',
    );
  }
}

/// 菜单缓存服务
/// 处理家庭共享菜单的缓存功能
class MenuCacheService {
  /// HTTP客户端
  final HttpClient _client = HttpClient();

  /// 单例实例
  static final MenuCacheService _instance = MenuCacheService._internal();

  /// 工厂构造函数
  factory MenuCacheService() => _instance;

  /// 私有构造函数
  MenuCacheService._internal();

  /// 获取今日菜单缓存
  /// familyId: 家庭ID
  /// date: 日期（默认今天）
  /// 返回: 今日菜单列表
  Future<List<MenuCacheItem>> getTodayMenu(
    String familyId, {
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = targetDate.toIso8601String().split('T')[0];

    final response = await _client.get(
      '${ApiConfig.menuCache}/$familyId/$dateStr',
    );

    if (response.isSuccess && response.data != null) {
      final list = response.data as List? ?? [];
      return list.map((e) => MenuCacheItem.fromJson(e)).toList();
    }

    return [];
  }

  /// 添加菜谱到今日菜单
  /// familyId: 家庭ID
  /// recipeId: 菜谱ID
  /// recipeName: 菜谱名称
  /// source: 来源（"my" 或 "online"）
  /// selectedBy: 选择者列表
  /// 返回: 添加的菜单项
  Future<MenuCacheItem?> addToTodayMenu({
    required String familyId,
    required String recipeId,
    required String recipeName,
    required String source,
    List<FamilyMember>? selectedBy,
  }) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _client.post(
      ApiConfig.menuCache,
      data: {
        'familyId': familyId,
        'date': today,
        'recipeId': recipeId,
        'recipeName': recipeName,
        'source': source,
        'selectedBy': selectedBy?.map((e) => e.toJson()).toList() ?? [],
      },
    );

    if (response.isSuccess && response.data != null) {
      return MenuCacheItem.fromJson(response.data);
    }

    return null;
  }

  /// 从今日菜单移除菜谱
  /// familyId: 家庭ID
  /// recipeId: 菜谱ID
  /// date: 日期（默认今天）
  /// 返回: 是否移除成功
  Future<bool> removeFromTodayMenu(
    String familyId,
    String recipeId, {
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = targetDate.toIso8601String().split('T')[0];

    final response = await _client.delete(
      '${ApiConfig.menuCache}/$familyId/$dateStr/$recipeId',
    );

    return response.isSuccess;
  }

  /// 切换菜谱的勾选状态
  /// cacheId: 缓存ID
  /// 返回: 是否切换成功
  Future<bool> toggleChecked(String cacheId) async {
    final response = await _client.put(
      '${ApiConfig.menuCache}/$cacheId/toggle',
    );

    return response.isSuccess;
  }

  /// 清空今日菜单
  /// familyId: 家庭ID
  /// date: 日期（默认今天）
  /// 返回: 是否清空成功
  Future<bool> clearTodayMenu(String familyId, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = targetDate.toIso8601String().split('T')[0];

    final response = await _client.delete(
      '${ApiConfig.menuCache}/$familyId/$dateStr',
    );

    return response.isSuccess;
  }

  /// 归档旧菜单（定时任务调用）
  /// 返回: 是否归档成功
  Future<bool> archiveOldMenus() async {
    final response = await _client.post(
      '${ApiConfig.menuCache}/archive',
    );

    return response.isSuccess;
  }
}
