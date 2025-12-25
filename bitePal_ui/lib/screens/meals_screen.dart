import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import '../utils/app_constants.dart';
import '../services/mock_data_service.dart';
import 'recipe_detail_screen.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  bool _filterExpanded = false;
  final List<String> _selectedTastes = [];
  final List<String> _selectedStatus = [];
  final List<String> _selectedMealTypes = [];
  final List<String> _selectedCuisines = [];
  final List<Recipe> _selectedMeals = []; // 已点的菜品列表
  final List<Recipe> _recipes = MockDataService.getMealRecipes();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section - 独立清晰的头部区域
            _buildHeaderSection(theme, colorScheme),
            // Filter Section - 可展开的筛选区域
            if (_filterExpanded) _buildFilterSection(theme, colorScheme),
            // Recipe Grid - 主要内容区域
            Expanded(child: _buildRecipeGrid(theme)),
          ],
        ),
      ),
      floatingActionButton: _selectedMeals.isNotEmpty
          ? _buildModernFAB(colorScheme)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// 构建头部区域 - 清晰的层级结构
  Widget _buildHeaderSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacingXL,
        AppConstants.spacingXL,
        AppConstants.spacingXL,
        AppConstants.spacingL,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题区域 - 主信息
          Text(
            "家庭点餐",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.2,
              inherit: false,
            ),
          ),
          SizedBox(height: AppConstants.spacingXL),
          // 搜索和筛选按钮行
          Row(
            children: [
              Expanded(child: _buildSearchField(theme, colorScheme)),
              SizedBox(width: AppConstants.spacingL),
              _buildFilterButton(theme, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建搜索框 - 更现代的样式
  Widget _buildSearchField(ThemeData theme, ColorScheme colorScheme) {
    return TextField(
      decoration: InputDecoration(
        hintText: "搜索菜名...",
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: AppConstants.textSizeL,
          textBaseline: TextBaseline.alphabetic,
          inherit: false,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
          size: 20,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingXL,
          vertical: AppConstants.spacingL,
        ),
      ),
      style: TextStyle(
        fontSize: AppConstants.textSizeL,
        color: colorScheme.onSurface,
        textBaseline: TextBaseline.alphabetic,
        inherit: false,
      ),
    );
  }

  /// 构建筛选按钮 - 统一的视觉风格
  Widget _buildFilterButton(ThemeData theme, ColorScheme colorScheme) {
    return Material(
      color: _filterExpanded
          ? colorScheme.primaryContainer
          : colorScheme.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          if (!mounted) return;
          setState(() {
            _filterExpanded = !_filterExpanded;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          child: Icon(
            Icons.tune_rounded,
            color: _filterExpanded
                ? colorScheme.onPrimaryContainer
                : colorScheme.onPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }

  /// 构建筛选区域 - 优雅的展开动画
  Widget _buildFilterSection(ThemeData theme, ColorScheme colorScheme) {
    if (!_filterExpanded) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          AppConstants.spacingXL,
          0,
          AppConstants.spacingXL,
          AppConstants.spacingL,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterChipSection(
                theme,
                colorScheme,
                "口味",
                ["酸", "甜", "苦", "麻", "辣"],
                _selectedTastes,
                (taste) {
                  if (!mounted) return;
                  setState(() {
                    if (_selectedTastes.contains(taste)) {
                      _selectedTastes.remove(taste);
                    } else {
                      _selectedTastes.add(taste);
                    }
                  });
                },
              ),
              SizedBox(height: AppConstants.spacingXL),
              _buildFilterChipSection(
                theme,
                colorScheme,
                "食材状态",
                ["食材充足", "需要补充"],
                _selectedStatus,
                (status) {
                  if (!mounted) return;
                  setState(() {
                    if (_selectedStatus.contains(status)) {
                      _selectedStatus.remove(status);
                    } else {
                      _selectedStatus.add(status);
                    }
                  });
                },
              ),
              SizedBox(height: AppConstants.spacingXL),
              _buildFilterChipSection(
                theme,
                colorScheme,
                "类型",
                ["早餐", "午餐", "晚餐", "夜宵"],
                _selectedMealTypes,
                (type) {
                  if (!mounted) return;
                  setState(() {
                    if (_selectedMealTypes.contains(type)) {
                      _selectedMealTypes.remove(type);
                    } else {
                      _selectedMealTypes.add(type);
                    }
                  });
                },
              ),
              SizedBox(height: AppConstants.spacingXL),
              _buildFilterChipSection(
                theme,
                colorScheme,
                "菜系",
                ["川菜", "粤菜", "鲁菜", "西餐"],
                _selectedCuisines,
                (cuisine) {
                  if (!mounted) return;
                  setState(() {
                    if (_selectedCuisines.contains(cuisine)) {
                      _selectedCuisines.remove(cuisine);
                    } else {
                      _selectedCuisines.add(cuisine);
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建菜品网格 - 优化的间距和布局
  Widget _buildRecipeGrid(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingXL),
      child: GridView.builder(
        padding: EdgeInsets.only(
          top: AppConstants.spacingL,
          bottom: AppConstants.spacingXXL + 20, // 为FAB留出空间
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppConstants.spacingXL,
          mainAxisSpacing: AppConstants.spacingXL,
          childAspectRatio: 0.75,
        ),
        itemCount: _recipes.length,
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          final isAdded = _selectedMeals.any((meal) => meal.id == recipe.id);
          return RecipeCard(
            recipe: recipe,
            isAdded: isAdded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
                ),
              );
            },
            onAdd: () {
              if (!mounted) return;
              setState(() {
                if (!isAdded) {
                  _selectedMeals.add(recipe);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已添加 ${recipe.name}'),
                        duration: AppConstants.snackBarDuration,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('该菜品已在清单中'),
                        duration: AppConstants.snackBarDuration,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              });
            },
          );
        },
      ),
    );
  }

  /// 构建现代化的FAB - 更优雅的设计
  Widget _buildModernFAB(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (mounted) {
              _showMealListDialog();
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.spacingXL,
              vertical: AppConstants.spacingL,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: colorScheme.onPrimary,
                  size: 22,
                ),
                SizedBox(width: AppConstants.spacingM),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedMeals.length}',
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontSize: AppConstants.textSizeS,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      inherit: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMealListDialog() {
    if (!mounted) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              final currentMeals = List<Recipe>.from(_selectedMeals);
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    // 拖拽指示器
                    Container(
                      margin: EdgeInsets.only(top: AppConstants.spacingL),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // 头部区域
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        AppConstants.spacingXL,
                        AppConstants.spacingXL,
                        AppConstants.spacingXL,
                        AppConstants.spacingL,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '已点菜品',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              inherit: false,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingL,
                              vertical: AppConstants.spacingS,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '共 ${currentMeals.length} 道',
                              style: TextStyle(
                                fontSize: AppConstants.textSizeM,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimaryContainer,
                                inherit: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 列表内容
                    Expanded(
                      child: currentMeals.isEmpty
                          ? _buildEmptyState(theme, colorScheme)
                          : ListView.builder(
                              controller: scrollController,
                              padding: EdgeInsets.all(AppConstants.spacingXL),
                              itemCount: currentMeals.length,
                              itemBuilder: (context, index) {
                                final meal = currentMeals[index];
                                return _buildMealListItem(
                                  theme,
                                  colorScheme,
                                  meal,
                                  index,
                                  setModalState,
                                );
                              },
                            ),
                    ),
                    // 底部操作栏
                    if (currentMeals.isNotEmpty)
                      _buildBottomActionBar(theme, colorScheme),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppConstants.spacingXXL),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          SizedBox(height: AppConstants.spacingXL),
          Text(
            '还没有点任何菜品',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              inherit: false,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建菜品列表项
  Widget _buildMealListItem(
    ThemeData theme,
    ColorScheme colorScheme,
    Recipe meal,
    int index,
    StateSetter setModalState,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacingL),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingXL,
          vertical: AppConstants.spacingM,
        ),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: meal.image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    meal.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.restaurant_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                )
              : Icon(
                  Icons.restaurant_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
        ),
        title: Text(
          meal.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            inherit: false,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: AppConstants.spacingXS),
          child: Text(
            '${meal.time} · ${meal.difficulty}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              inherit: false,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        trailing: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!mounted) return;
              setState(() {
                if (index < _selectedMeals.length) {
                  _selectedMeals.removeAt(index);
                }
              });
              setModalState(() {});
              if (_selectedMeals.isEmpty && mounted) {
                Navigator.pop(context);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(AppConstants.spacingM),
              child: Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomActionBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacingXL,
        AppConstants.spacingL,
        AppConstants.spacingXL,
        AppConstants.spacingXL + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (!mounted) return;
                setState(() {
                  _selectedMeals.clear();
                });
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: AppConstants.spacingL),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '清空清单',
                style: TextStyle(
                  fontSize: AppConstants.textSizeL,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  inherit: false,
                ),
              ),
            ),
          ),
          SizedBox(width: AppConstants.spacingL),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已提交 ${_selectedMeals.length} 道菜品'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: AppConstants.spacingL),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                '确认点餐',
                style: TextStyle(
                  fontSize: AppConstants.textSizeL,
                  fontWeight: FontWeight.w700,
                  inherit: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipSection(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    List<String> options,
    List<String> selected,
    Function(String) onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            letterSpacing: 0.2,
            inherit: false,
          ),
        ),
        SizedBox(height: AppConstants.spacingL),
        Wrap(
          spacing: AppConstants.spacingM,
          runSpacing: AppConstants.spacingM,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onToggle(option),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingL,
                    vertical: AppConstants.spacingM,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: AppConstants.textSizeM,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      inherit: false, // 避免动画插值错误
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
