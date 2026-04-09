import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../models/recipe_draft.dart';
import '../services/recipe_service.dart';
import '../services/category_service.dart';
import '../services/draft_service.dart';
import '../config/api_config.dart';
import '../widgets/refreshable_screen.dart';
import '../widgets/recipe_card.dart';
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
        color: widget.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: widget.isBreathing
            ? null
            : Border.all(color: widget.color.withValues(alpha: 0.2)),
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
                      color: widget.color.withValues(
                        alpha: _opacityAnimation.value,
                      ),
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
  final DraftService _draftService = DraftService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State
  String _activeTab = "my";
  String _searchKeyword = '';
  bool _isLoading = true;
  bool _isSearchExpanded = false;

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

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadRecipes();
    _draftService.load();
    _draftService.addListener(_onDraftsChanged);
  }

  void _onDraftsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _draftService.removeListener(_onDraftsChanged);
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
        name: '有手就行',
        sortOrder: 1,
        isActive: true,
      ),
      RecipeCategory(
        id: '2',
        type: 'difficulty',
        name: '家常便饭',
        sortOrder: 2,
        isActive: true,
      ),
      RecipeCategory(
        id: '3',
        type: 'difficulty',
        name: '硬核挑战',
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
      debugPrint('Error loading recipes: $e');
      // If error occurs, we just keep the empty lists or previous state
      // Optionally show a snackbar or error state
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<Recipe> get _currentRecipes =>
      _activeTab == "my" ? _myRecipes : _onlineRecipes;

  void _toggleTab() {
    setState(() {
      _activeTab = _activeTab == "my" ? "online" : "my";
    });
    _loadRecipes();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) {
        // 只有当搜索关键词不为空时才刷新
        if (_searchKeyword.isNotEmpty) {
          _searchController.clear();
          _searchKeyword = '';
          _loadRecipes();
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _oatmeal,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. 紧凑标题栏（菜谱库 + 切换按钮 + 搜索 + 筛选）
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

          // 2. 草稿箱（仅在"我的私房"标签下显示）
          if (_activeTab == "my" && _draftService.drafts.isNotEmpty)
            SliverToBoxAdapter(child: _buildDraftsSection()),

          // 3. Recipe List (Staggered Grid)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      return RecipeCard(
                        recipe: recipe,
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
                          if (result == true) {
                            _loadRecipes();
                          }
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 44,
      child: Row(
        children: [
          // 标签切换按钮（替代菜谱库标题）
          if (!_isSearchExpanded)
            _buildTabSwitchButton(),

          if (!_isSearchExpanded) const SizedBox(width: 8),

          // 搜索区域（可展开）
          Flexible(
            fit: FlexFit.loose,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: _buildSearchArea(constraints.maxWidth),
                );
              },
            ),
          ),

          if (!_isSearchExpanded) const SizedBox(width: 8),

          // 筛选按钮
          if (!_isSearchExpanded)
            _buildFilterButton(),

          // 添加菜谱按钮
          if (!_isSearchExpanded) ...[
            const SizedBox(width: 8),
            _buildAddButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildTabSwitchButton() {
    return GestureDetector(
      onTap: _toggleTab,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabOption(
              label: "我的私房",
              isActive: _activeTab == "my",
              color: const Color(0xFF7B9E89), // 深绿色
            ),
            const SizedBox(width: 4),
            _buildTabOption(
              label: "探索发现",
              isActive: _activeTab == "online",
              color: const Color(0xFFE8956F), // 橙色
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabOption({
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isActive ? Colors.white : const Color(0xFF8C8F90),
        ),
      ),
    );
  }

  Widget _buildSearchArea(double maxWidth) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isSearchExpanded ? maxWidth : maxWidth.clamp(0.0, 40.0),
      height: 40,
      child: GlassContainer(
        borderRadius: 20,
        opacity: 0.6,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleSearch,
              child: Icon(
                _isSearchExpanded ? Icons.arrow_back : Icons.search,
                color: const Color(0xFF8C8F90),
                size: 20,
              ),
            ),
            if (_isSearchExpanded) ...[
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
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
          ],
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
        child: const Icon(
          Icons.tune_rounded,
          color: Color(0xFF4A4F50),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showAddRecipeOptions,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _sageGreen,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _sageGreen.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _showAddRecipeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddRecipeSheet(
        onManual: () async {
          Navigator.pop(ctx);
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RecipeDetailScreen(isCreateMode: true),
            ),
          );
          if (result == true) _loadRecipes();
        },
        onFromUrl: () {
          Navigator.pop(ctx);
          _showUrlInputDialog();
        },
      ),
    );
  }

  void _showUrlInputDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '从链接获取菜谱',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4A4F50),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Icon(Icons.public_rounded, size: 15, color: Color(0xFFE8956F)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '提取后菜谱将直接发布到探索发现（待审核）',
                      style: TextStyle(fontSize: 12, color: Color(0xFFE8956F)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '粘贴菜谱视频或网页链接，AI 将自动提取菜谱内容。\n支持 YouTube、Bilibili、下厨房等。',
              style: TextStyle(fontSize: 13, color: Color(0xFF8C8F90)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://...',
                hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                filled: true,
                fillColor: const Color(0xFFF5F5F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF4A4F50)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Color(0xFF8C8F90))),
          ),
          TextButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isEmpty) return;
              Navigator.pop(ctx);
              _checkAndStartExtraction(url);
            },
            child: const Text(
              '开始提取',
              style: TextStyle(
                color: Color(0xFFB2AC88),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 查重后启动提取。有重复则弹提示；无重复则开始后台提取。
  Future<void> _checkAndStartExtraction(String url) async {
    // 显示加载指示
    if (!mounted) return;
    final loadingOverlay = OverlayEntry(
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFB2AC88)),
      ),
    );
    Overlay.of(context).insert(loadingOverlay);

    try {
      final existing = await _recipeService.checkPublicRecipeByUrl(url);
      loadingOverlay.remove();

      if (!mounted) return;

      if (existing != null) {
        // 已存在 → 提示用户并提供跳转
        _showDuplicateUrlDialog(existing);
      } else {
        // 不存在 → 开始提取
        _startUrlExtraction(url);
      }
    } catch (_) {
      loadingOverlay.remove();
      if (!mounted) return;
      // 查重失败时降级处理：直接开始提取
      _startUrlExtraction(url);
    }
  }

  void _showDuplicateUrlDialog(Map<String, String> existing) {
    final recipeName = existing['name'] ?? '未知菜谱';
    final recipeId = existing['id'] ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '已有相同菜谱',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4A4F50),
          ),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B6F70), height: 1.5),
            children: [
              const TextSpan(text: '该链接已被提取为菜谱\n'),
              TextSpan(
                text: '「$recipeName」',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A4F50),
                ),
              ),
              const TextSpan(text: '\n\n可以直接前往查看或保存到私房。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Color(0xFF8C8F90))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (recipeId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(recipeId: recipeId),
                  ),
                );
              }
            },
            child: const Text(
              '去查看',
              style: TextStyle(
                color: Color(0xFFB2AC88),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startUrlExtraction(String url) {
    // 异步启动提取，不阻塞 UI；DraftService 监听器会在完成时刷新界面
    _draftService.extractFromUrl(url, ApiConfig.extractorBaseUrl);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('正在后台提取菜谱，完成后将出现在草稿箱 ✨'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF4A4F50),
      ),
    );
  }

  // --- Drafts Section ---

  Widget _buildDraftsSection() {
    final drafts = _draftService.drafts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 10),
          child: Row(
            children: [
              const Text(
                '草稿箱',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8C8F90),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFB2AC88).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${drafts.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB2AC88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: drafts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _DraftCard(
              draft: drafts[i],
              onTap: () => _onDraftTap(drafts[i]),
              onDelete: () => _draftService.deleteDraft(drafts[i].id),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Divider(
          height: 1,
          thickness: 0.5,
          indent: 16,
          endIndent: 16,
          color: Colors.grey.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _onDraftTap(RecipeDraft draft) {
    if (draft.status == DraftStatus.extracting) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('菜谱正在提取中，请稍候...'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF4A4F50),
        ),
      );
      return;
    }
    if (draft.status == DraftStatus.failed) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('提取失败'),
          content: Text(draft.errorMessage ?? '未知错误'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _draftService.deleteDraft(draft.id);
              },
              child: const Text(
                '删除',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭'),
            ),
                  if (draft.sourceUrl != null)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _draftService.deleteDraft(draft.id);
                        // 重试也要先做查重
                        _checkAndStartExtraction(draft.sourceUrl!);
                      },
                      child: const Text(
                        '重试',
                        style: TextStyle(color: Color(0xFFB2AC88)),
                      ),
                    ),
          ],
        ),
      );
      return;
    }
    // 草稿已就绪，以公开模式打开预填充的菜谱编辑界面（直接发布到探索发现）
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(
          isCreateMode: true,
          isPublicMode: true,
          initialData: draft.extractedData,
          draftId: draft.id,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _draftService.deleteDraft(draft.id);
        _loadRecipes();
      }
    });
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
                color: _sageGreen.withValues(alpha: 0.1),
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

// --- Add Recipe Bottom Sheet ---

class _AddRecipeSheet extends StatelessWidget {
  final VoidCallback onManual;
  final VoidCallback onFromUrl;

  const _AddRecipeSheet({required this.onManual, required this.onFromUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            '添加菜谱',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A4F50),
            ),
          ),
          const SizedBox(height: 24),
          _OptionTile(
            icon: Icons.edit_note_rounded,
            title: '手动创建',
            subtitle: '从零开始填写，保存到我的私房',
            color: const Color(0xFF7B9E89),
            onTap: onManual,
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.link_rounded,
            title: '从链接获取',
            subtitle: 'AI 提取菜谱，直接发布到探索发现',
            badge: '公开',
            color: const Color(0xFFE8956F),
            onTap: onFromUrl,
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A4F50),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8C8F90),
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Draft Card ---

class _DraftCard extends StatelessWidget {
  final RecipeDraft draft;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DraftCard({
    required this.draft,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExtracting = draft.status == DraftStatus.extracting;
    final isFailed = draft.status == DraftStatus.failed;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (isExtracting) {
      statusColor = const Color(0xFF7B9E89);
      statusIcon = Icons.hourglass_top_rounded;
      statusLabel = '提取中';
    } else if (isFailed) {
      statusColor = const Color(0xFFE07070);
      statusIcon = Icons.error_outline_rounded;
      statusLabel = '失败';
    } else {
      statusColor = const Color(0xFFE8956F);
      statusIcon = Icons.check_circle_outline_rounded;
      statusLabel = '待编辑';
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red),
                  title: const Text(
                    '删除草稿',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isExtracting)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  )
                else
                  Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                draft.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A4F50),
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(draft.createdAt),
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFBBBBBB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${dt.month}/${dt.day}';
  }
}

// --- Tab Header Delegate ---

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
