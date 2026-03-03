import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../models/recipe_selection.dart';
import '../models/user.dart';
import '../models/meal_order.dart';
import 'meal_service.dart';
import 'recipe_service.dart';
import 'menu_cache_service.dart';
import 'auth_service.dart';

/// 全局状态管理器
/// 使用单例模式管理已点菜品状态，支持多页面同步和家庭共享
class TodayMenuState extends ChangeNotifier {
  /// 单例实例
  static final TodayMenuState _instance = TodayMenuState._internal();

  /// 工厂构造函数
  factory TodayMenuState() => _instance;

  /// 私有构造函数
  TodayMenuState._internal();

  /// 点餐服务
  final MealService _mealService = MealService();

  /// 菜谱服务
  final RecipeService _recipeService = RecipeService();

  /// 菜单缓存服务
  final MenuCacheService _menuCacheService = MenuCacheService();

  /// 认证服务
  final AuthService _authService = AuthService();

  /// 今日菜单中的菜谱数据（展示用）
  final List<Recipe> _menuRecipes = [];

  /// 已点的菜品列表（用于点餐页面）- 旧版本，保持兼容
  final List<Recipe> _selectedMeals = [];

  /// 菜谱选择记录（新版本，支持多人选择）
  final Map<String, RecipeSelection> _selections = {};

  /// 今日菜单缓存项（从缓存加载）
  final List<MenuCacheItem> _todayMenuCache = [];

  /// 当前用户/成员信息
  FamilyMember? _currentMember;

  /// 当前用户信息
  User? _currentUser;

  /// 是否正在加载
  bool _isLoading = false;

  /// 获取已点菜品列表（旧版本，保持兼容）
  List<Recipe> get selectedMeals => List.unmodifiable(_selectedMeals);

  /// 获取菜谱选择记录列表（新版本）
  List<RecipeSelection> get selections => _selections.values.toList();

  /// 获取今日菜单中的菜谱（展示用）
  List<Recipe> get menuRecipes => List.unmodifiable(_menuRecipes);

  /// 获取今日菜单缓存项
  List<MenuCacheItem> get todayMenuCache => List.unmodifiable(_todayMenuCache);

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 获取当前成员
  FamilyMember? get currentMember => _currentMember;

  /// 检查菜谱是否已点
  /// recipeId: 菜谱ID
  /// 返回: 是否已点
  bool isSelected(String recipeId) {
    return _todayMenuCache.any((item) => item.recipeId == recipeId);
  }

  /// 设置当前成员
  void setCurrentMember(FamilyMember member) {
    _currentMember = member;
    notifyListeners();
  }

  /// 检查菜谱是否被当前成员选择
  bool isSelectedByCurrentMember(String recipeId) {
    if (_currentMember == null) return isSelected(recipeId);
    final selection = _selections[recipeId];
    return selection?.isSelectedBy(_currentMember!.id ?? '') ?? false;
  }

  /// 获取菜谱的选择记录
  RecipeSelection? getSelection(String recipeId) {
    return _selections[recipeId];
  }

  /// 初始化当前用户信息
  Future<void> _initCurrentUser() async {
    if (_currentUser == null) {
      _currentUser = await _authService.getUserInfo();
      if (_currentUser != null) {
        debugPrint('当前用户信息: userId=${_currentUser!.userId}, familyId=${_currentUser!.familyId}');
        _currentMember = FamilyMember(
          id: _currentUser!.userId,
          name: _currentUser!.nickname.isNotEmpty
              ? _currentUser!.nickname
              : _currentUser!.username,
        );
      } else {
        debugPrint('获取用户信息失败');
      }
    }
  }

  /// 加载今日菜单缓存（从缓存读取，支持家庭共享）
  /// 每次进入点餐页面时调用
  Future<void> loadTodayMenuFromCache() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 初始化当前用户
      await _initCurrentUser();

      if (_currentUser == null || _currentUser!.familyId.isEmpty) {
        debugPrint('用户未加入家庭，无法加载共享菜单');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 从缓存加载今日菜单
      final cacheItems = await _menuCacheService.getTodayMenu(
        _currentUser!.familyId,
      );

      _todayMenuCache.clear();
      _todayMenuCache.addAll(cacheItems);

      // 同步到本地状态
      _selectedMeals.clear();
      _selections.clear();

      for (final item in cacheItems) {
        final recipe = item.toRecipe();
        _selectedMeals.add(recipe);

        _selections[item.recipeId] = RecipeSelection(
          recipe: recipe,
          selectedBy: item.selectedBy,
          source: item.source,
          isChecked: item.isChecked,
        );
      }

      debugPrint('成功加载今日菜单缓存: ${cacheItems.length} 道菜');
    } catch (e) {
      debugPrint('加载今日菜单缓存失败: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 加载今日菜单（展示用）
  /// 从服务器获取今日订单数据
  Future<void> loadTodayMenu() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 获取最近的订单
      final orders = await _mealService.getMealOrders(
        page: 1,
        pageSize: 10, // 获取最近10条，以便找到今天的订单
      );

      _menuRecipes.clear();

      if (orders != null && orders.list.isNotEmpty) {
        // 查找今天创建的订单
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);

        MealOrder? todayOrder;
        for (final order in orders.list) {
          if (order.createdAt != null) {
            try {
              final orderDate = DateTime.parse(order.createdAt!);
              final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);

              if (orderDay.isAtSameMomentAs(todayStart)) {
                todayOrder = order;
                break;
              }
            } catch (e) {
              debugPrint('解析订单日期失败: $e');
            }
          }
        }

        // 如果找到今天的订单，加载菜谱详情
        if (todayOrder != null) {
          for (final orderRecipe in todayOrder.recipes) {
            try {
              final recipe = await _recipeService.getRecipeDetail(
                orderRecipe.recipeId,
              );
              if (recipe != null) {
                _menuRecipes.add(recipe);
              }
            } catch (e) {
              debugPrint('加载菜谱详情失败: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('加载今日菜单失败: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 添加到已点菜品（同步到缓存）
  /// recipe: 菜谱
  /// source: 来源 'my' 或 'online'
  Future<void> addToSelected(Recipe recipe, {String source = 'my'}) async {
    // 初始化当前用户
    await _initCurrentUser();

    if (_currentUser == null || _currentUser!.familyId.isEmpty) {
      debugPrint('使用本地模式添加菜品（未加入家庭或家庭ID为空）');
      // 降级到本地模式
      _addToSelectedLocal(recipe, source: source);
      return;
    }

    // 检查是否已存在
    if (isSelected(recipe.id)) {
      debugPrint('菜谱已在今日菜单中');
      return;
    }

    try {
      // 添加到缓存
      final cacheItem = await _menuCacheService.addToTodayMenu(
        familyId: _currentUser!.familyId,
        recipeId: recipe.id,
        recipeName: recipe.name,
        source: source,
        selectedBy: _currentMember != null ? [_currentMember!] : [],
      );

      if (cacheItem != null) {
        _todayMenuCache.add(cacheItem);
        _addToSelectedLocal(recipe, source: source);
        debugPrint('成功添加到今日菜单缓存: ${recipe.name}');
      } else {
        debugPrint('添加到缓存失败，使用本地模式');
        _addToSelectedLocal(recipe, source: source);
      }
    } catch (e) {
      debugPrint('添加到菜单缓存失败: $e，使用本地模式');
      // 降级到本地模式
      _addToSelectedLocal(recipe, source: source);
    }
  }

  /// 添加到本地已点菜品（不同步缓存）
  void _addToSelectedLocal(Recipe recipe, {String source = 'my'}) {
    // 旧版本兼容
    if (!_selectedMeals.any((r) => r.id == recipe.id)) {
      _selectedMeals.add(recipe);
    }

    // 新版本：支持多人选择
    if (_selections.containsKey(recipe.id)) {
      // 已存在，添加当前成员（如果有）
      if (_currentMember != null) {
        _selections[recipe.id]!.addSelector(_currentMember!);
      }
    } else {
      // 新建选择记录
      _selections[recipe.id] = RecipeSelection(
        recipe: recipe,
        selectedBy: _currentMember != null ? [_currentMember!] : [],
        source: source,
        isChecked: true,
      );
    }

    notifyListeners();
  }

  /// 从已点菜品移除（同步到缓存）
  /// recipeId: 菜谱ID
  Future<void> removeFromSelected(String recipeId) async {
    // 初始化当前用户
    await _initCurrentUser();

    if (_currentUser == null || _currentUser!.familyId.isEmpty) {
      debugPrint('使用本地模式移除菜品（未加入家庭或家庭ID为空）');
      // 降级到本地模式
      _removeFromSelectedLocal(recipeId);
      return;
    }

    try {
      // 从缓存移除
      final success = await _menuCacheService.removeFromTodayMenu(
        _currentUser!.familyId,
        recipeId,
      );

      if (success) {
        _todayMenuCache.removeWhere((item) => item.recipeId == recipeId);
        _removeFromSelectedLocal(recipeId);
        debugPrint('成功从今日菜单缓存移除: $recipeId');
      } else {
        debugPrint('从缓存移除失败，使用本地模式');
        _removeFromSelectedLocal(recipeId);
      }
    } catch (e) {
      debugPrint('从菜单缓存移除失败: $e，使用本地模式');
      // 降级到本地模式
      _removeFromSelectedLocal(recipeId);
    }
  }

  /// 从本地已点菜品移除（不同步缓存）
  void _removeFromSelectedLocal(String recipeId) {
    // 旧版本兼容
    _selectedMeals.removeWhere((recipe) => recipe.id == recipeId);

    // 新版本：移除当前成员的选择
    if (_selections.containsKey(recipeId)) {
      if (_currentMember != null) {
        _selections[recipeId]!.removeSelector(_currentMember!.id ?? '');
        // 如果没有人选择了，删除整个记录
        if (_selections[recipeId]!.selectedBy.isEmpty) {
          _selections.remove(recipeId);
        }
      } else {
        // 没有当前成员时，直接删除整个记录
        _selections.remove(recipeId);
      }
    }

    notifyListeners();
  }

  /// 切换已点状态
  /// recipe: 菜谱
  /// source: 来源 'my' 或 'online'
  /// 返回: 操作后是否已点
  Future<bool> toggleSelected(Recipe recipe, {String source = 'my'}) async {
    // 检查当前用户是否已选择该菜品
    final isCurrentlySelected = isSelectedByCurrentMember(recipe.id);

    if (isCurrentlySelected) {
      await removeFromSelected(recipe.id);
      return false;
    } else {
      await addToSelected(recipe, source: source);
      return true;
    }
  }

  /// 清空已点菜品（同步到缓存）
  Future<void> clearSelected() async {
    // 初始化当前用户
    await _initCurrentUser();

    if (_currentUser != null && _currentUser!.familyId.isNotEmpty) {
      try {
        // 清空缓存
        await _menuCacheService.clearTodayMenu(_currentUser!.familyId);
        _todayMenuCache.clear();
        debugPrint('成功清空今日菜单缓存');
      } catch (e) {
        debugPrint('清空菜单缓存失败: $e');
      }
    }

    _selectedMeals.clear();
    _selections.clear();
    notifyListeners();
  }

  /// 切换菜谱的勾选状态
  void toggleChecked(String recipeId) {
    if (_selections.containsKey(recipeId)) {
      _selections[recipeId]!.isChecked = !_selections[recipeId]!.isChecked;
      notifyListeners();
    }
  }

  /// 获取已勾选的菜谱
  List<RecipeSelection> getCheckedSelections() {
    return _selections.values.where((s) => s.isChecked).toList();
  }

  /// 获取已点菜品数量
  int get selectedCount => _selections.length;

  /// 刷新今日菜单（确认点餐后调用）
  Future<void> refreshTodayMenu() async {
    await loadTodayMenu();
    await loadTodayMenuFromCache();
  }
}
