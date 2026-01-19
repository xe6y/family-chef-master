import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../services/recipe_service.dart';
import '../services/category_service.dart';
import '../widgets/refreshable_screen.dart';
import 'recipe_detail_screen.dart';

// --- Helper Components (Internal for this screen per requirement) ---

/// 磨砂玻璃容器
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
            color: (color ?? Theme.of(context).colorScheme.surface).withOpacity(
              opacity,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 弹性卡片 (简化版)
class BouncyCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? activeShadowColor;

  const BouncyCard({
    super.key,
    required this.child,
    required this.onTap,
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
        widget.onTap();
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

/// 状态标签 (带呼吸动效)
class StatusChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool isBreathing;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.isBreathing = false,
  });

  @override
  State<StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<StatusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _opacityAnimation = Tween<double>(
      begin: 0.1,
      end: 0.4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isBreathing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBreathing != oldWidget.isBreathing) {
      if (widget.isBreathing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: widget.isBreathing
            ? null
            : Border.all(color: widget.color.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          if (widget.isBreathing)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: widget.color.withOpacity(_opacityAnimation.value),
                    ),
                  );
                },
              ),
            ),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Main Screen ---

class RecipesScreen extends RefreshableScreen {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen>
    with RefreshableScreenState<RecipesScreen> {
  final RecipeService _recipeService = RecipeService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State
  String _activeTab = "my";
  String _searchKeyword = '';
  bool _isLoading = true;

  // Filter State
  final List<String> _selectedTastes = [];
  final List<String> _selectedDifficulties = [];
  final List<String> _selectedCuisines = [];

  // Data
  List<RecipeCategory> _tasteCategories = [];
  List<RecipeCategory> _difficultyCategories = [];
  List<RecipeCategory> _cuisineCategories = [];
  List<Recipe> _myRecipes = [];
  List<Recipe> _onlineRecipes = [];

  // Theme Colors (Morandi)
  static const Color _sageGreen = Color(0xFFB2AC88);
  static const Color _oatmeal = Color(0xFFF5F5F0);
  static const Color _persimmon = Color(0xFFE58A73);

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    // Keep existing fallback logic
    _tasteCategories = [
      RecipeCategory(
        id: '1',
        type: 'taste',
        name: '清淡',
        sortOrder: 1,
        isActive: true,
      ),
      RecipeCategory(
        id: '2',
        type: 'taste',
        name: '咸鲜',
        sortOrder: 2,
        isActive: true,
      ),
      RecipeCategory(
        id: '3',
        type: 'taste',
        name: '酸',
        sortOrder: 3,
        isActive: true,
      ),
      RecipeCategory(
        id: '4',
        type: 'taste',
        name: '甜',
        sortOrder: 4,
        isActive: true,
      ),
      RecipeCategory(
        id: '5',
        type: 'taste',
        name: '麻',
        sortOrder: 5,
        isActive: true,
      ),
      RecipeCategory(
        id: '6',
        type: 'taste',
        name: '辣',
        sortOrder: 6,
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
      RecipeCategory(
        id: '2',
        type: 'difficulty',
        name: '中等',
        sortOrder: 2,
        isActive: true,
      ),
      RecipeCategory(
        id: '3',
        type: 'difficulty',
        name: '困难',
        sortOrder: 3,
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
      RecipeCategory(
        id: '2',
        type: 'cuisine',
        name: '川菜',
        sortOrder: 2,
        isActive: true,
      ),
      RecipeCategory(
        id: '3',
        type: 'cuisine',
        name: '粤菜',
        sortOrder: 3,
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
      final tastes = _selectedTastes.isNotEmpty
          ? _selectedTastes.join(',')
          : null;
      final difficulty = _selectedDifficulties.isNotEmpty
          ? _selectedDifficulties.join(',')
          : null;
      final cuisines = _selectedCuisines.isNotEmpty
          ? _selectedCuisines.join(',')
          : null;

      if (_activeTab == "my") {
        final result = await _recipeService.getMyRecipes(
          keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
          tastes: tastes,
          difficulty: difficulty,
          cuisines: cuisines,
        );
        if (result != null) _myRecipes = result.list;
      } else {
        final result = await _recipeService.getPublicRecipes(
          keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
          tastes: tastes,
          difficulty: difficulty,
          cuisines: cuisines,
        );
        if (result != null) _onlineRecipes = result.list;
      }
    } catch (e) {
      _loadMockData();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadMockData() {
    _myRecipes = [
      Recipe(
        id: '1',
        name: "番茄炒蛋",
        time: "15分钟",
        difficulty: "有手就行",
        difficultyColor: "#E8F5E9",
        tags: ["家常", "快手"],
        tagColors: ["#10B981", "#F59E0B"],
        favorite: true,
        categories: ["家常菜", "酸甜"],
      ),
      Recipe(
        id: '4',
        name: "红烧肉",
        time: "45分钟",
        difficulty: "家常便饭",
        difficultyColor: "#E3F2FD",
        tags: ["常做"],
        tagColors: ["#3B82F6"],
        favorite: false,
        categories: ["川菜", "咸鲜"],
      ),
      Recipe(
        id: '3',
        name: "清蒸鲈鱼",
        time: "25分钟",
        difficulty: "有手就行",
        difficultyColor: "#E8F5E9",
        tags: ["健康"],
        tagColors: ["#10B981"],
        favorite: true,
        categories: ["粤菜", "清淡"],
      ),
    ];
    _onlineRecipes = [
      Recipe(
        id: '101',
        name: "宫保鸡丁",
        time: "30分钟",
        difficulty: "餐厅招牌",
        difficultyColor: "#FFFDE7",
        tags: ["热门", "川菜"],
        tagColors: ["#EF4444", "#F59E0B"],
        favorite: false,
        categories: ["川菜", "麻辣"],
      ),
      Recipe(
        id: '102',
        name: "糖醋里脊",
        time: "25分钟",
        difficulty: "家常便饭",
        difficultyColor: "#E3F2FD",
        tags: ["热门"],
        tagColors: ["#EF4444"],
        favorite: false,
        categories: ["鲁菜", "酸甜"],
      ),
    ];
  }

  List<Recipe> get _currentRecipes =>
      _activeTab == "my" ? _myRecipes : _onlineRecipes;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _oatmeal,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const RecipeDetailScreen(isCreateMode: true),
            ),
          );
          if (result == true) _loadRecipes();
        },
        backgroundColor: _sageGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. Immersive Header & Search
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 120,
            backgroundColor: _oatmeal,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              "菜谱库",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF4A4F50),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Color(0xFF4A4F50)),
                onPressed: _showFilterModal,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: _oatmeal),
              expandedTitleScale: 1.0,
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              title: LayoutBuilder(
                builder: (context, constraints) {
                  // Simple animation based on collapse state could be added here
                  // For now, we keep the search bar constant in the flexible space
                  // but visually aligned.
                  return const SizedBox.shrink();
                },
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: GlassContainer(
                  borderRadius: 24,
                  opacity: 0.6,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF8C8F90)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "搜索美味...",
                            hintStyle: TextStyle(
                              color: Color(0xFF8C8F90),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4A4F50),
                          ),
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

          // 2. Tab Switcher
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabHeaderDelegate(
              activeTab: _activeTab,
              onTabChanged: (tab) {
                setState(() => _activeTab = tab);
                _loadRecipes();
              },
            ),
          ),

          // 3. Recipe List (Staggered Grid)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: _sageGreen),
                    ),
                  )
                : _currentRecipes.isEmpty
                ? SliverFillRemaining(child: _buildEmptyState())
                : SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childCount: _currentRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _currentRecipes[index];
                      return _buildMagazineCard(recipe);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- Magazine Style Card ---
  Widget _buildMagazineCard(Recipe recipe) {
    // 使用数据库中的难度颜色，如果没有则使用默认颜色
    Color diffColor = _sageGreen;
    if (recipe.difficultyColor != null && recipe.difficultyColor!.isNotEmpty) {
      try {
        // 解析颜色字符串（支持 #RRGGBB 格式）
        final colorStr = recipe.difficultyColor!.replaceAll('#', '');
        diffColor = Color(int.parse('FF$colorStr', radix: 16));
      } catch (e) {
        // 如果解析失败，使用默认颜色
        diffColor = _sageGreen;
      }
    }

    // 判断是否为专家级别（用于呼吸动效）
    bool isExpert = recipe.difficulty == "专业厨师" || recipe.difficulty == "硬核挑战";

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              recipeId: recipe.id,
              isFromMyRecipes: _activeTab == "my",
            ),
          ),
        );
        if (result == true) _loadRecipes();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with fade-in
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 1, // Square for top part
                child: Builder(
                  builder: (context) {
                    final imagePath = recipe.image;
                    final isValidAsset =
                        imagePath != null &&
                        imagePath.isNotEmpty &&
                        imagePath.startsWith('assets/');

                    return Image.asset(
                      isValidAsset
                          ? imagePath
                          : 'assets/chinese-potato-strips.jpg',
                      fit: BoxFit.cover,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                              child: child,
                            );
                          },
                      errorBuilder: (_, __, ___) => Container(
                        color: _oatmeal,
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4F50),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 标签行（最多显示两个标签）
                  if (recipe.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          for (
                            int i = 0;
                            i <
                                (recipe.tags.length > 2
                                    ? 2
                                    : recipe.tags.length);
                            i++
                          ) ...[
                            _buildRecipeTag(
                              recipe.tags[i],
                              i < recipe.tagColors.length
                                  ? recipe.tagColors[i]
                                  : null,
                            ),
                            if (i < 1 && recipe.tags.length > 1)
                              const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Color(0xFF8C8F90),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe.time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8C8F90),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 难度标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: diffColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: diffColor.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          recipe.difficulty,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: diffColor,
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

  // --- Recipe Tag Widget ---
  Widget _buildRecipeTag(String tagName, String? tagColor) {
    // 解析标签颜色
    Color color = _sageGreen;
    if (tagColor != null && tagColor.isNotEmpty) {
      try {
        // 支持多种颜色格式
        if (tagColor.startsWith('#')) {
          final colorStr = tagColor.replaceAll('#', '');
          color = Color(int.parse('FF$colorStr', radix: 16));
        } else if (tagColor.startsWith('bg-')) {
          // 支持 Tailwind CSS 风格的颜色类名
          color = _parseTailwindColor(tagColor);
        }
      } catch (e) {
        color = _sageGreen;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        tagName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // --- Parse Tailwind Color ---
  Color _parseTailwindColor(String tailwindClass) {
    // 简单的 Tailwind 颜色映射
    if (tailwindClass.contains('blue')) return const Color(0xFF3B82F6);
    if (tailwindClass.contains('red')) return const Color(0xFFEF4444);
    if (tailwindClass.contains('green')) return const Color(0xFF10B981);
    if (tailwindClass.contains('yellow')) return const Color(0xFFF59E0B);
    if (tailwindClass.contains('purple')) return const Color(0xFF8B5CF6);
    if (tailwindClass.contains('pink')) return const Color(0xFFEC4899);
    if (tailwindClass.contains('orange')) return const Color(0xFFF97316);
    return _sageGreen;
  }

  // --- Empty State with Floating Animation ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 10),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            onEnd: () {
              // Loop logic would require a stateful widget wrapper or repeating controller,
              // but TweenAnimationBuilder is simple for one-off/simple physics.
              // For continuous float, we'd typically use an AnimationController.
              // Simplified here to just stay "floating" visually.
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _sageGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.dining_outlined,
                size: 48,
                color: _sageGreen,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _activeTab == "my" ? "还没有私房菜谱" : "没有找到相关菜谱",
            style: const TextStyle(color: Color(0xFF8C8F90), fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "快去添加或搜索看看吧 ~",
            style: TextStyle(color: Color(0xFFDCD7CD), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// --- Tab Header Delegate ---

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  _TabHeaderDelegate({required this.activeTab, required this.onTabChanged});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF5F5F0), // Oatmeal
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassContainer(
        borderRadius: 30,
        opacity: 0.5,
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(30),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                children: [
                  AnimatedAlign(
                    alignment: activeTab == "my"
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutBack,
                    child: Container(
                      width: width / 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _buildTabItem(
                        "我的私房",
                        activeTab == "my",
                        () => onTabChanged("my"),
                      ),
                      _buildTabItem(
                        "探索发现",
                        activeTab == "online",
                        () => onTabChanged("online"),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? const Color(0xFF4A4F50)
                  : const Color(0xFF8C8F90),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 60;
  @override
  double get minExtent => 60;
  @override
  bool shouldRebuild(covariant _TabHeaderDelegate oldDelegate) {
    return activeTab != oldDelegate.activeTab;
  }
}

// --- Filter Bottom Sheet (Premium Style) ---

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
                    backgroundColor: const Color(0xFFB2AC88), // Sage Green
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
