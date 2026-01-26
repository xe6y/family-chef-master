import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../models/recipe_selection.dart';
import '../models/meal_order.dart';
import '../services/meal_service.dart';
import '../services/category_service.dart';
import '../services/recipe_service.dart';
import '../services/today_menu_state.dart';
import '../widgets/refreshable_screen.dart';
import '../widgets/recipe_card.dart';
import '../widgets/stacked_avatars.dart';
import 'recipe_detail_screen.dart';

// --- Helper Components (1:1 with Recipes Screen) ---

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 10,
    this.opacity = 0.5,
    this.padding = EdgeInsets.zero,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (color ?? Theme.of(context).colorScheme.surface).withValues(
              alpha: opacity,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class BouncyCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? activeShadowColor;

  const BouncyCard({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.activeShadowColor,
  });

  @override
  State<BouncyCard> createState() => _BouncyCardState();
}

class _BouncyCardState extends State<BouncyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: widget.isSelected && widget.activeShadowColor != null
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.activeShadowColor!.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  )
                : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// --- Main Screen ---

class MealsScreen extends RefreshableScreen {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen>
    with RefreshableScreenState<MealsScreen> {
  final MealService _mealService = MealService();
  final RecipeService _recipeService = RecipeService();
  final CategoryService _categoryService = CategoryService();
  final TodayMenuState _todayMenuState = TodayMenuState();
  final TextEditingController _searchController = TextEditingController();

  // State
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  String _searchKeyword = '';
  bool _isSearchExpanded = false;

  // Filter State
  final List<String> _selectedTastes = [];
  final List<String> _selectedDifficulties = [];
  final List<String> _selectedCuisines = [];

  // Data
  List<RecipeCategory> _tasteCategories = [];
  List<RecipeCategory> _difficultyCategories = [];
  List<RecipeCategory> _cuisineCategories = [];

  // Theme Colors (Morandi - Consistent with Recipes)
  static const Color _sageGreen = Color(0xFFB2AC88);
  static const Color _oatmeal = Color(0xFFF5F5F0);
  static const Color _textPrimary = Color(0xFF4A4F50);
  static const Color _textSecondary = Color(0xFF8C8F90);

  @override
  void initState() {
    super.initState();
    // CRITICAL: Restored old method name to fix NoSuchMethodError crash
    _todayMenuState.addListener(_onTodayMenuStateChanged);
    _loadData();
  }

  @override
  void dispose() {
    _todayMenuState.removeListener(_onTodayMenuStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  // CRITICAL: Method name matches what the singleton is trying to call
  void _onTodayMenuStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    await Future.wait([_loadCategories(), _loadRecipes()]);
  }

  Future<void> _loadCategories() async {
    try {
      final results = await Future.wait([
        _categoryService.getCategoriesByType('taste'),
        _categoryService.getCategoriesByType('difficulty'),
        _categoryService.getCategoriesByType('cuisine'),
      ]);
      if (mounted) {
        setState(() {
          _tasteCategories = results[0] ?? [];
          _difficultyCategories = results[1] ?? [];
          _cuisineCategories = results[2] ?? [];
        });
      }
    } catch (e) {
      _loadDefaultCategories();
    }
  }

  void _loadDefaultCategories() {
    _tasteCategories = [
      RecipeCategory(
        id: '1',
        type: 'taste',
        name: '清淡',
        sortOrder: 1,
        isActive: true,
      ),
    ];
    _difficultyCategories = [
      RecipeCategory(
        id: '1',
        type: 'difficulty',
        name: '简单',
        sortOrder: 1,
        isActive: true,
      ),
    ];
    _cuisineCategories = [
      RecipeCategory(
        id: '1',
        type: 'cuisine',
        name: '家常菜',
        sortOrder: 1,
        isActive: true,
      ),
    ];
  }

  @override
  Future<void> refresh() async {
    await _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    try {
      // 只获取我的私房菜谱
      final myRecipesResult = await _recipeService.getMyRecipes();

      var list = myRecipesResult?.list ?? [];

      if (_searchKeyword.isNotEmpty) {
        list = list.where((r) => r.name.contains(_searchKeyword)).toList();
      }
      if (_selectedTastes.isNotEmpty) {
        list = list
            .where((r) => _selectedTastes.any((t) => r.categories.contains(t)))
            .toList();
      }
      if (_selectedDifficulties.isNotEmpty) {
        list = list
            .where((r) => _selectedDifficulties.contains(r.difficulty))
            .toList();
      }
      if (_selectedCuisines.isNotEmpty) {
        list = list
            .where(
              (r) => _selectedCuisines.any((c) => r.categories.contains(c)),
            )
            .toList();
      }

      _recipes = list;
    } catch (e) {
      debugPrint('Error loading meal recipes: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded && _searchKeyword.isNotEmpty) {
        _searchController.clear();
        _searchKeyword = '';
        _loadRecipes();
      }
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(
        selectedTastes: _selectedTastes,
        selectedDifficulties: _selectedDifficulties,
        selectedCuisines: _selectedCuisines,
        tasteCategories: _tasteCategories,
        difficultyCategories: _difficultyCategories,
        cuisineCategories: _cuisineCategories,
        onApply: (tastes, diffs, cuisines) {
          setState(() {
            _selectedTastes.clear();
            _selectedTastes.addAll(tastes);
            _selectedDifficulties.clear();
            _selectedDifficulties.addAll(diffs);
            _selectedCuisines.clear();
            _selectedCuisines.addAll(cuisines);
          });
          _loadRecipes();
        },
      ),
    );
  }

  Future<void> _confirmOrder() async {
    final selected = _todayMenuState.selectedMeals;
    if (selected.isEmpty) return;

    final orderRecipes = selected
        .map((r) => OrderRecipe(recipeId: r.id, recipeName: r.name))
        .toList();
    final order = await _mealService.createMealOrder(orderRecipes);

    if (order != null && mounted) {
      _todayMenuState.clearSelected();
      await _todayMenuState.refreshTodayMenu();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('点餐成功！祝您用餐愉快 🍽️')));
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  void _showOrderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderListSheet(
        todayMenuState: _todayMenuState,
        onConfirm: _confirmOrder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _oatmeal,
      body: CustomScrollView(
        slivers: [
          // 紧凑标题栏
          SliverToBoxAdapter(
            child: Container(
              color: _oatmeal,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 12,
                16,
                12,
              ),
              child: _buildCompactHeader(),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: _sageGreen),
                    ),
                  )
                : _recipes.isEmpty
                ? SliverFillRemaining(child: _buildEmptyState())
                : SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childCount: _recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recipes[index];
                      final isAdded = _todayMenuState.isSelected(recipe.id);
                      return RecipeCard(
                        recipe: recipe,
                        isAdded: isAdded,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(
                                recipeId: recipe.id,
                                isFromMyRecipes: true,
                              ),
                            ),
                          );
                        },
                        onAdd: () {
                          HapticFeedback.lightImpact();
                          _todayMenuState.toggleSelected(recipe);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- Compact Header ---
  Widget _buildCompactHeader() {
    return Row(
      children: [
        // 已选菜品按钮（始终显示）
        if (!_isSearchExpanded) _buildSelectedMealsButton(),

        const Spacer(),

        // 搜索按钮（可展开）
        _buildSearchButton(),

        const SizedBox(width: 8),

        // 筛选按钮
        if (!_isSearchExpanded) _buildFilterButton(),
      ],
    );
  }

  Widget _buildSelectedMealsButton() {
    return GestureDetector(
      onTap: _showOrderSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _sageGreen,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _sageGreen.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_basket_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              "已选 ${_todayMenuState.selectedCount} 道",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isSearchExpanded ? MediaQuery.of(context).size.width - 80 : 40,
      height: 40,
      child: GlassContainer(
        borderRadius: 20,
        opacity: 0.6,
        padding: EdgeInsets.zero,
        child: _isSearchExpanded
            ? Row(
                children: [
                  GestureDetector(
                    onTap: _toggleSearch,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back,
                        color: _textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: "今天想吃点什么？",
                        hintStyle: TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 14, color: _textPrimary),
                      onSubmitted: (val) {
                        _searchKeyword = val;
                        _loadRecipes();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              )
            : GestureDetector(
                onTap: _toggleSearch,
                child: const Center(
                  child: Icon(Icons.search, color: _textSecondary, size: 20),
                ),
              ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: _showFilterModal,
      child: GlassContainer(
        borderRadius: 20,
        opacity: 0.6,
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.tune_rounded, color: _textPrimary, size: 20),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 15),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) =>
                Transform.translate(offset: Offset(0, value), child: child),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _sageGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                size: 48,
                color: _sageGreen,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "今天还没有可选菜品",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "去菜谱库收藏一些心仪的菜吧 ~",
            style: TextStyle(color: Color(0xFFDCD7CD), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// --- Filter Bottom Sheet (1:1 with Recipe Screen) ---

class _FilterBottomSheet extends StatefulWidget {
  final List<String> selectedTastes;
  final List<String> selectedDifficulties;
  final List<String> selectedCuisines;
  final List<RecipeCategory> tasteCategories;
  final List<RecipeCategory> difficultyCategories;
  final List<RecipeCategory> cuisineCategories;
  final Function(List<String>, List<String>, List<String>) onApply;

  const _FilterBottomSheet({
    required this.selectedTastes,
    required this.selectedDifficulties,
    required this.selectedCuisines,
    required this.tasteCategories,
    required this.difficultyCategories,
    required this.cuisineCategories,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late List<String> _tempTastes;
  late List<String> _tempDiffs;
  late List<String> _tempCuisines;

  @override
  void initState() {
    super.initState();
    _tempTastes = List.from(widget.selectedTastes);
    _tempDiffs = List.from(widget.selectedDifficulties);
    _tempCuisines = List.from(widget.selectedCuisines);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "筛选",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection("口味", widget.tasteCategories, _tempTastes),
                  const SizedBox(height: 20),
                  _buildSection("难度", widget.difficultyCategories, _tempDiffs),
                  const SizedBox(height: 20),
                  _buildSection("菜系", widget.cuisineCategories, _tempCuisines),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _tempTastes.clear();
                      _tempDiffs.clear();
                      _tempCuisines.clear();
                    });
                  },
                  child: const Text(
                    "重置",
                    style: TextStyle(color: Color(0xFF8C8F90)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_tempTastes, _tempDiffs, _tempCuisines);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFB2AC88,
                    ), // Consistent Sage Green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "应用",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<RecipeCategory> options,
    List<String> selected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8C8F90),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((cat) {
            final isSelected = selected.contains(cat.name);
            return BouncyCard(
              isSelected: isSelected,
              activeShadowColor: const Color(0xFFB2AC88),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selected.remove(cat.name);
                  } else {
                    selected.add(cat.name);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFB2AC88)
                      : const Color(0xFFF5F5F0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey[200]!,
                  ),
                ),
                child: Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.white : const Color(0xFF4A4F50),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
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

// --- Order List Sheet ---

class _OrderListSheet extends StatefulWidget {
  final TodayMenuState todayMenuState;
  final VoidCallback onConfirm;

  const _OrderListSheet({
    required this.todayMenuState,
    required this.onConfirm,
  });

  @override
  State<_OrderListSheet> createState() => _OrderListSheetState();
}

class _OrderListSheetState extends State<_OrderListSheet> {
  @override
  Widget build(BuildContext context) {
    final selections = widget.todayMenuState.selections;

    // 分组：我的私房 vs 网络菜谱
    final myRecipes = selections.where((s) => s.source == 'my').toList();
    final onlineRecipes = selections.where((s) => s.source == 'online').toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          const SizedBox(height: 24),
          _buildHeader(selections.length),
          const SizedBox(height: 16),
          _buildContent(myRecipes, onlineRecipes),
          const SizedBox(height: 24),
          _buildConfirmButton(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "已选菜品",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A4F50),
          ),
        ),
        Text(
          "$count 道",
          style: const TextStyle(
            color: Color(0xFFB2AC88),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    List<RecipeSelection> myRecipes,
    List<RecipeSelection> onlineRecipes,
  ) {
    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (myRecipes.isNotEmpty) ...[
              _buildSectionTitle("我的私房", myRecipes.length),
              const SizedBox(height: 12),
              ...myRecipes.map((selection) => _buildSelectionItem(selection)),
            ],
            if (myRecipes.isNotEmpty && onlineRecipes.isNotEmpty)
              const SizedBox(height: 24),
            if (onlineRecipes.isNotEmpty) ...[
              _buildSectionTitle("网络菜谱", onlineRecipes.length),
              const SizedBox(height: 12),
              ...onlineRecipes.map((selection) => _buildSelectionItem(selection)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFB2AC88),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4F50),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "($count)",
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8C8F90),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionItem(RecipeSelection selection) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selection.isChecked
              ? const Color(0xFFB2AC88)
              : Colors.grey[200]!,
          width: selection.isChecked ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selection.isChecked,
            onChanged: (value) {
              setState(() {
                widget.todayMenuState.toggleChecked(selection.recipe.id);
              });
            },
            activeColor: const Color(0xFFB2AC88),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selection.recipe.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4F50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${selection.recipe.difficulty} · ${selection.recipe.time}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8C8F90),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StackedAvatars(
            members: selection.selectedBy,
            size: 28,
            maxDisplay: 3,
            overlap: 10,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.grey[400],
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            onPressed: () {
              setState(() {
                widget.todayMenuState.removeFromSelected(selection.recipe.id);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    final checkedCount = widget.todayMenuState.getCheckedSelections().length;
    final isDisabled = checkedCount == 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : widget.onConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB2AC88),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[500],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          "生成今日菜单 ($checkedCount)",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
