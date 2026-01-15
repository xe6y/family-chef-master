import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/recipe.dart';
import '../models/ingredient_item.dart';
import '../models/today_menu.dart';
import '../services/menu_service.dart';
import '../services/ingredient_service.dart';
import '../services/recipe_service.dart';
import '../utils/app_theme.dart';
import '../widgets/bento_card.dart';
import '../widgets/random_meal_dialog.dart';
import '../widgets/refreshable_screen.dart';
import 'recipe_detail_screen.dart';
import 'profile_screen.dart';

/// 首页 - Bento Grid 风格
class HomeScreen extends RefreshableScreen {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, RefreshableScreenState<HomeScreen> {
  /// 菜单服务
  final MenuService _menuService = MenuService();

  /// 食材服务
  final IngredientService _ingredientService = IngredientService();

  /// 菜谱服务
  final RecipeService _recipeService = RecipeService();

  /// 今日菜单
  TodayMenu? _todayMenu;

  /// 今日菜谱列表
  List<Recipe> _todayRecipes = [];

  /// 即将过期食材列表
  List<IngredientItem> _expiringIngredients = [];

  /// 是否正在加载
  bool _isLoading = true;

  /// 动画控制器
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Future<void> refresh() async {
    await _loadData();
  }

  /// 加载数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _menuService.getTodayMenu(),
        _ingredientService.getExpiringIngredients(days: 3),
      ]);

      _todayMenu = results[0] as TodayMenu?;
      _expiringIngredients = results[1] as List<IngredientItem>;

      if (_todayMenu != null && _todayMenu!.recipes.isNotEmpty) {
        final recipeDetails = await Future.wait(
          _todayMenu!.recipes.map(
            (r) => _recipeService.getRecipeDetail(r.recipeId),
          ),
        );
        _todayRecipes = recipeDetails.whereType<Recipe>().toList();
      }
    } catch (e) {
      debugPrint('加载数据失败: $e');
      _loadMockData();
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }

  /// 加载模拟数据
  void _loadMockData() {
    _todayRecipes = [
      Recipe(
        id: '1',
        name: "番茄炒蛋",
        time: "15 分钟",
        difficulty: "家常便饭",
        tags: ["常做"],
        tagColors: ["bg-blue-500"],
        favorite: false,
        categories: ["家常菜", "酸甜"],
      ),
      Recipe(
        id: '4',
        name: "红烧肉",
        time: "45 分钟",
        difficulty: "餐厅招牌",
        tags: ["常做"],
        tagColors: ["bg-blue-500"],
        favorite: false,
        categories: ["川菜", "咸鲜"],
      ),
    ];

    _expiringIngredients = [
      IngredientItem(
        id: '1',
        name: "生菜",
        amount: "1颗",
        storage: "fridge",
        icon: "🥬",
        expiryDays: 0,
        expiryText: "今天",
        urgent: true,
      ),
      IngredientItem(
        id: '2',
        name: "培根",
        amount: "200g",
        storage: "fridge",
        icon: "🥓",
        expiryDays: 1,
        expiryText: "明天",
        urgent: false,
      ),
      IngredientItem(
        id: '3',
        name: "牛奶",
        amount: "500ml",
        storage: "fridge",
        icon: "🥛",
        expiryDays: 3,
        expiryText: "3天后",
        urgent: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BentoStyle.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 顶部问候区域
                  SliverToBoxAdapter(child: _buildGreetingHeader()),
                  // Bento Grid 主内容
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BentoStyle.gridSpacing,
                    ),
                    sliver: SliverToBoxAdapter(child: _buildBentoGrid()),
                  ),
                  // 底部间距
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  /// 构建问候头部
  Widget _buildGreetingHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariantLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "今天想吃点什么？",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onBackgroundLight,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),
            // 头像
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: BentoStyle.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/cartoon-avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.warmGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 Bento Grid
  Widget _buildBentoGrid() {
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: BentoStyle.gridSpacing,
      crossAxisSpacing: BentoStyle.gridSpacing,
      children: [
        // 1. 随便吃点 - 2x2.1 大卡片（主要功能）
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 2.1,
          child: _buildRandomMealCard(),
        ),

        // 2. 添加菜谱 - 2x1 横向卡片
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 1,
          child: _buildAddRecipeCard(),
        ),

        // 3. 周菜单 - 2x1 横向卡片
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 1,
          child: _buildWeekMenuCard(),
        ),

        // 4. 今日菜单 - 4x2.8 超宽卡片
        StaggeredGridTile.count(
          crossAxisCellCount: 4,
          mainAxisCellCount: 2.8,
          child: _buildTodayMenuCard(),
        ),

        // 5. 食材提醒 - 4x1.5 提醒卡片（如果有过期食材）
        if (_expiringIngredients.isNotEmpty)
          StaggeredGridTile.count(
            crossAxisCellCount: 4,
            mainAxisCellCount: 1.2,
            child: _buildIngredientAlertCard(),
          ),

        // 6. 即将过期食材列表 - 每个食材一个小卡片
        if (_expiringIngredients.isNotEmpty)
          ..._expiringIngredients.take(3).map((ingredient) {
            return StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1,
              child: _buildIngredientCard(ingredient),
            );
          }),
      ],
    );
  }

  /// 随便吃点 - 主要功能卡片
  Widget _buildRandomMealCard() {
    return BentoCard(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const RandomMealDialog(),
        );
      },
      gradient: AppColors.primaryGradient,
      decorIcon: Icons.restaurant_rounded,
      decorIconColor: Colors.white.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 顶部图标
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shuffle_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          // 底部文字
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "随便吃点",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "让我来帮你决定今天吃什么",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 添加菜谱卡片
  Widget _buildAddRecipeCard() {
    return BentoCard(
      onTap: () {
        // 导航到添加菜谱
      },
      backgroundColor: AppColors.secondaryContainer,
      decorIcon: Icons.add_circle_outline_rounded,
      decorIconColor: AppColors.secondary.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add_rounded,
              color: AppColors.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "添加菜谱",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "记录你的拿手好菜",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSecondaryContainer.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 周菜单卡片
  Widget _buildWeekMenuCard() {
    return BentoCard(
      onTap: () {
        // 导航到周菜单
      },
      backgroundColor: AppColors.accentLight.withValues(alpha: 0.15),
      decorIcon: Icons.calendar_month_rounded,
      decorIconColor: AppColors.accent.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "周菜单",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackgroundLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "规划一周美食",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariantLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 今日菜单卡片
  Widget _buildTodayMenuCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return BentoCard(
      onTap: () {},
      backgroundColor: colorScheme.surface,
      decorIcon: Icons.restaurant_menu_rounded,
      decorIconColor: AppColors.primary.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "今日菜单",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (_todayRecipes.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_todayRecipes.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (_todayRecipes.isNotEmpty)
                TextButton(
                  onPressed: () => _showTodayMenuDialog(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '查看全部',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 菜谱列表
          Expanded(
            child: _todayRecipes.isEmpty
                ? _buildEmptyMenuContent()
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.hardEdge,
                      itemCount: _todayRecipes.length > 4
                          ? 4
                          : _todayRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _todayRecipes[index];
                        return Container(
                          width: 100,
                          margin: EdgeInsets.only(
                            right:
                                index <
                                    (_todayRecipes.length > 4
                                        ? 3
                                        : _todayRecipes.length - 1)
                                ? 10
                                : 0,
                          ),
                          child: _buildMiniRecipeCard(recipe),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 显示今日菜单弹窗
  void _showTodayMenuDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                // 拖动条
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 标题
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '今日菜单',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '共 ${_todayRecipes.length} 道',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // 菜谱列表
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                    itemCount: _todayRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _todayRecipes[index];
                      return _buildDialogRecipeCard(recipe);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 弹窗中的菜谱卡片
  Widget _buildDialogRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RecipeDetailScreen(recipeId: recipe.id, isFromMyRecipes: true),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图片区域 - 固定高度 130，与菜谱卡片保持一致
            Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.restaurant_rounded,
                      size: 40,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  if (recipe.favorite)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 信息区域
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppColors.onSurfaceVariantLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe.time,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariantLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 12,
                        color: AppColors.onSurfaceVariantLight,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          recipe.difficulty,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariantLight,
                          ),
                          overflow: TextOverflow.ellipsis,
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

  /// 空菜单内容
  Widget _buildEmptyMenuContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            size: 40,
            color: AppColors.onSurfaceVariantLight.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Text(
            "今日暂无菜单",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariantLight,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const RandomMealDialog(),
              );
            },
            icon: const Icon(Icons.shuffle_rounded, size: 16),
            label: const Text('随机推荐'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  /// 迷你菜谱卡片（简化版：只显示图片和名字）
  Widget _buildMiniRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RecipeDetailScreen(recipeId: recipe.id, isFromMyRecipes: true),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片区域 - 调整比例，图片占2，文字占1
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppColors.warmGradient,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.restaurant_rounded,
                    size: 24,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
            // 名字区域
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                recipe.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 食材提醒卡片
  Widget _buildIngredientAlertCard() {
    final urgentCount = _expiringIngredients.where((i) => i.urgent).length;

    return BentoCard(
      onTap: () {},
      backgroundColor: AppColors.warningLight,
      decorIcon: Icons.notifications_active_rounded,
      decorIconColor: AppColors.warning.withValues(alpha: 0.12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${_expiringIngredients.length} 种食材即将过期",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (urgentCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    "其中 $urgentCount 种今天到期，建议优先使用",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onBackgroundLight.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.warning, size: 28),
        ],
      ),
    );
  }

  /// 单个食材卡片
  Widget _buildIngredientCard(IngredientItem ingredient) {
    final isUrgent = ingredient.urgent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.errorLight : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: BentoStyle.cardShadow,
      ),
      child: Row(
        children: [
          // 食材图标
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isUrgent
                  ? AppColors.error.withValues(alpha: 0.12)
                  : AppColors.warningLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                ingredient.icon,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ingredient.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  ingredient.amount,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariantLight,
                  ),
                ),
              ],
            ),
          ),
          // 过期标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUrgent
                  ? AppColors.error.withValues(alpha: 0.15)
                  : AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ingredient.expiryText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isUrgent ? AppColors.error : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取问候语
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了 🌙';
    if (hour < 9) return '早上好 ☀️';
    if (hour < 12) return '上午好 🌤️';
    if (hour < 14) return '中午好 🍽️';
    if (hour < 18) return '下午好 ☕';
    if (hour < 22) return '晚上好 🌆';
    return '夜深了 🌙';
  }
}
