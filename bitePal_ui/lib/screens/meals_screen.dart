import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../models/meal_order.dart';
import '../services/meal_service.dart';
import '../services/category_service.dart';
import '../services/recipe_service.dart';
import '../services/today_menu_state.dart';
import '../widgets/refreshable_screen.dart';
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
            color: (color ?? Theme.of(context).colorScheme.surface).withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
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

class _BouncyCardState extends State<BouncyCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
                        color: widget.activeShadowColor!.withOpacity(0.4),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
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

class _MealsScreenState extends State<MealsScreen> with RefreshableScreenState<MealsScreen> {
  final MealService _mealService = MealService();
  final RecipeService _recipeService = RecipeService();
  final CategoryService _categoryService = CategoryService();
  final TodayMenuState _todayMenuState = TodayMenuState();
  final TextEditingController _searchController = TextEditingController();

  // State
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  String _searchKeyword = '';
  
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
  static const Color _persimmon = Color(0xFFE58A73);
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
    await Future.wait([
      _loadCategories(),
      _loadRecipes(),
    ]);
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
    _tasteCategories = [RecipeCategory(id: '1', type: 'taste', name: '清淡', sortOrder: 1, isActive: true)];
    _difficultyCategories = [RecipeCategory(id: '1', type: 'difficulty', name: '简单', sortOrder: 1, isActive: true)];
    _cuisineCategories = [RecipeCategory(id: '1', type: 'cuisine', name: '家常菜', sortOrder: 1, isActive: true)];
  }

  @override
  Future<void> refresh() async {
    await _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    try {
      await _todayMenuState.loadTodayMenu();
      final favResult = await _recipeService.getMyRecipes(favorite: true);
      
      final Map<String, Recipe> uniqueMap = {};
      for (var r in _todayMenuState.menuRecipes) { uniqueMap[r.id] = r; }
      if (favResult != null) {
        for (var r in favResult.list) { uniqueMap[r.id] = r; }
      }

      var list = uniqueMap.values.toList();
      
      if (_searchKeyword.isNotEmpty) {
        list = list.where((r) => r.name.contains(_searchKeyword)).toList();
      }
      if (_selectedTastes.isNotEmpty) {
        list = list.where((r) => _selectedTastes.any((t) => r.categories.contains(t))).toList();
      }
      if (_selectedDifficulties.isNotEmpty) {
        list = list.where((r) => _selectedDifficulties.contains(r.difficulty)).toList();
      }
      if (_selectedCuisines.isNotEmpty) {
        list = list.where((r) => _selectedCuisines.any((c) => r.categories.contains(c))).toList();
      }

      _recipes = list;
    } catch (e) {
      _loadMockData();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadMockData() {
    _recipes = [
      Recipe(id: '1', name: "番茄炒蛋", time: "15分钟", difficulty: "简单", tags: ["家常"], tagColors: ["bg-green-500"], favorite: true, categories: ["酸甜"]),
    ];
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
            _selectedTastes.clear(); _selectedTastes.addAll(tastes);
            _selectedDifficulties.clear(); _selectedDifficulties.addAll(diffs);
            _selectedCuisines.clear(); _selectedCuisines.addAll(cuisines);
          });
          _loadRecipes();
        },
      ),
    );
  }

  Future<void> _confirmOrder() async {
    final selected = _todayMenuState.selectedMeals;
    if (selected.isEmpty) return;

    final orderRecipes = selected.map((r) => OrderRecipe(recipeId: r.id, recipeName: r.name)).toList();
    final order = await _mealService.createMealOrder(orderRecipes);
    
    if (order != null && mounted) {
      _todayMenuState.clearSelected();
      await _todayMenuState.refreshTodayMenu();
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('点餐成功！祝您用餐愉快 🍽️')));
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
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 120,
            backgroundColor: _oatmeal,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              "家庭点餐",
              style: TextStyle(fontWeight: FontWeight.w800, color: _textPrimary),
            ),
            actions: [
               IconButton(
                icon: const Icon(Icons.tune_rounded, color: _textPrimary),
                onPressed: _showFilterModal,
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: GlassContainer(
                  borderRadius: 24,
                  opacity: 0.6,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: _textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "今天想吃点什么？",
                            hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14, color: _textPrimary),
                          onSubmitted: (val) {
                            _searchKeyword = val;
                            _loadRecipes();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: _isLoading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: _sageGreen)))
                : _recipes.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : SliverMasonryGrid.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childCount: _recipes.length,
                        itemBuilder: (context, index) => _buildMealCard(_recipes[index]),
                      ),
          ),
        ],
      ),
      floatingActionButton: _todayMenuState.selectedCount > 0
          ? FloatingActionButton.extended(
              onPressed: _showOrderSheet,
              backgroundColor: _sageGreen,
              elevation: 4,
              label: Row(
                children: [
                  const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text("${_todayMenuState.selectedCount} 道菜品", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildMealCard(Recipe recipe) {
    final isAdded = _todayMenuState.isSelected(recipe.id);
    
    return BouncyCard(
      isSelected: isAdded,
      activeShadowColor: _sageGreen,
      onTap: () async {
        Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: recipe.id, isFromMyRecipes: true)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 1.1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      (recipe.image != null && recipe.image!.isNotEmpty && recipe.image!.startsWith('assets/'))
                          ? recipe.image!
                          : 'assets/chinese-potato-strips.jpg',
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: StatusChip(
                        label: recipe.difficulty,
                        color: recipe.difficulty == "简单" ? _sageGreen : _persimmon,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textPrimary)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${recipe.time} ", style: const TextStyle(fontSize: 12, color: _textSecondary)),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _todayMenuState.toggleSelected(recipe);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isAdded ? _sageGreen : _sageGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAdded ? Icons.check : Icons.add,
                            size: 18,
                            color: isAdded ? Colors.white : _sageGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
            builder: (context, value, child) => Transform.translate(offset: Offset(0, value), child: child),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: _sageGreen.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.restaurant_rounded, size: 48, color: _sageGreen),
            ),
          ),
          const SizedBox(height: 24),
          const Text("今天还没有可选菜品", style: TextStyle(color: _textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text("去菜谱库收藏一些心仪的菜吧 ~", style: TextStyle(color: Color(0xFFDCD7CD), fontSize: 14)),
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
          const Text("筛选", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                  child: const Text("重置", style: TextStyle(color: Color(0xFF8C8F90))),
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
                    backgroundColor: const Color(0xFFB2AC88), // Consistent Sage Green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("应用", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<RecipeCategory> options, List<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF8C8F90))),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFB2AC88) : const Color(0xFFF5F5F0),
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

class _OrderListSheet extends StatelessWidget {
  final TodayMenuState todayMenuState;
  final VoidCallback onConfirm;

  const _OrderListSheet({required this.todayMenuState, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final meals = todayMenuState.selectedMeals;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("已选菜品", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A4F50))),
              Text("${meals.length} 道", style: const TextStyle(color: Color(0xFFB2AC88), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: meals.length,
              itemBuilder: (context, index) {
                final meal = meals[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/chinese-potato-strips.jpg',
                          width: 50, 
                          height: 50, 
                          fit: BoxFit.cover
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(meal.difficulty, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => todayMenuState.removeFromSelected(meal.id),
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFE58A73), size: 20),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB2AC88),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("确认提交菜单", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}