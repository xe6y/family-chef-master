import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../models/recipe_selection.dart';
import '../models/user.dart';
import 'meal_service.dart';
import 'recipe_service.dart';

/// 全局状态管理器
/// 使用单例模式管理已点菜品状态，支持多页面同步
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

  /// 今日菜单中的菜谱数据（展示用）
  final List<Recipe> _menuRecipes = [];

  /// 已点的菜品列表（用于点餐页面）- 旧版本，保持兼容
  final List<Recipe> _selectedMeals = [];

  /// 菜谱选择记录（新版本，支持多人选择）
  final Map<String, RecipeSelection> _selections = {};

  /// 当前用户/成员信息
  FamilyMember? _currentMember;

  /// 是否正在加载
  bool _isLoading = false;

  /// 获取已点菜品列表（旧版本，保持兼容）
  List<Recipe> get selectedMeals => List.unmodifiable(_selectedMeals);

  /// 获取菜谱选择记录列表（新版本）
  List<RecipeSelection> get selections => _selections.values.toList();

  /// 获取今日菜单中的菜谱（展示用）
  List<Recipe> get menuRecipes => List.unmodifiable(_menuRecipes);

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 获取当前成员
  FamilyMember? get currentMember => _currentMember;

  /// 检查菜谱是否已点
  /// recipeId: 菜谱ID
  /// 返回: 是否已点
  bool isSelected(String recipeId) {
    return _selectedMeals.any((recipe) => recipe.id == recipeId);
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

  /// 加载今日菜单（展示用）
  /// 从服务器获取今日订单数据
  Future<void> loadTodayMenu() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 获取今日订单（今日菜单 = 今日订单）
      final orders = await _mealService.getMealOrders(
        page: 1,
        pageSize: 1,
      );

      _menuRecipes.clear();

      if (orders != null && orders.list.isNotEmpty) {
        final todayOrder = orders.list.first;

        // 从订单中获取菜谱列表
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
    } catch (e) {
      debugPrint('加载今日菜单失败: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 添加到已点菜品
  /// recipe: 菜谱
  /// source: 来源 'my' 或 'online'
  void addToSelected(Recipe recipe, {String source = 'my'}) {
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

  /// 从已点菜品移除
  /// recipeId: 菜谱ID
  void removeFromSelected(String recipeId) {
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
  bool toggleSelected(Recipe recipe, {String source = 'my'}) {
    final isCurrentlySelected = _currentMember != null
        ? isSelectedByCurrentMember(recipe.id)
        : isSelected(recipe.id);

    if (isCurrentlySelected) {
      removeFromSelected(recipe.id);
      return false;
    } else {
      addToSelected(recipe, source: source);
      return true;
    }
  }

  /// 清空已点菜品
  void clearSelected() {
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
  }
}
