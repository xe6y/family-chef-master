import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/recipe.dart';
import '../models/ingredient_item.dart';
import '../services/ingredient_service.dart';
import '../services/ingredient_check_service.dart';
import '../services/today_menu_state.dart';
import '../widgets/random_meal_dialog.dart';
import 'recipe_detail_screen.dart';
import 'profile_screen.dart';
import 'ingredient_check_screen.dart';

/// ============================================
/// iOS 风格首页
/// ============================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// 食材服务
  final IngredientService _ingredientService = IngredientService();

  /// 食材检查服务
  final IngredientCheckService _ingredientCheckService = IngredientCheckService();

  /// 今日菜单状态
  final TodayMenuState _todayMenuState = TodayMenuState();

  /// 今日菜谱列表
  List<Recipe> get _todayRecipes => _todayMenuState.menuRecipes;

  /// 即将过期食材列表
  List<IngredientItem> _expiringIngredients = [];

  /// 食材检查结果
  IngredientCheckResult? _ingredientCheckResult;

  /// 是否正在加载
  bool _isLoading = true;

  /// 动画控制器
  late AnimationController _animationController;

  /// 用户心情状态
  MoodState _userMood = MoodState.happy;

  @override
  void initState() {
    super.initState();
    _todayMenuState.addListener(_onTodayMenuStateChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadData();
  }

  @override
  void dispose() {
    _todayMenuState.removeListener(_onTodayMenuStateChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onTodayMenuStateChanged() {
    if (mounted) setState(() {});
  }

  /// 刷新页面数据
  Future<void> refresh() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 并行加载今日菜单、即将过期食材和食材检查结果
      final ingredientsFuture =
          _ingredientService.getExpiringIngredients(days: 3);
      final menuFuture = _todayMenuState.loadTodayMenu();
      final checkFuture = _ingredientCheckService.checkTodayMenuIngredients();

      _expiringIngredients = await ingredientsFuture;
      await menuFuture;
      _ingredientCheckResult = await checkFuture;

      _updateMoodByTime();
    } catch (e) {
      debugPrint('加载数据失败: $e');
      // On error, lists remain empty which is handled by UI
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }

  void _updateMoodByTime() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      _userMood = MoodState.sleepy;
    } else if (hour < 9) {
      _userMood = MoodState.thinking;
    } else if (hour < 12) {
      _userMood = MoodState.hungry;
    } else if (hour < 14) {
      _userMood = MoodState.happy;
    } else if (hour < 18) {
      _userMood = MoodState.calm;
    } else if (hour < 22) {
      _userMood = MoodState.happy;
    } else {
      _userMood = MoodState.sleepy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CupertinoPageScaffold(
      backgroundColor: colorScheme.surface,
      child: _isLoading
          ? Center(
              child: CupertinoActivityIndicator(
                radius: 14,
                color: colorScheme.primary,
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // iOS 风格大标题导航栏
                CupertinoSliverNavigationBar(
                  backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
                  border: null,
                  largeTitle: Text(
                    'CookMate',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/cartoon-avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(
                            CupertinoIcons.person_fill,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 主体内容
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 今日推荐卡片
                      _buildTodayRecommendationCard(),
                      const SizedBox(height: 16),
                      // 今日菜单卡片
                      _buildTodayMenuCard(),
                      const SizedBox(height: 16),
                      // 食材提醒区域
                      if (_expiringIngredients.isNotEmpty)
                        _buildIngredientAlertSection(),
                      const SizedBox(height: 20),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  /// 构建心情选择器 - iOS 风格
  Widget _buildMoodSelector() {
    final theme = Theme.of(context);
    final (icon, color, label) = _getMoodConfig();

    return GestureDetector(
      onTap: _showMoodSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.8), color],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "今天心情",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, String) _getMoodConfig() {
    final colorScheme = Theme.of(context).colorScheme;
    switch (_userMood) {
      case MoodState.happy:
        return (
          Icons.sentiment_very_satisfied_rounded,
          const Color(0xFF81C784),
          '开心',
        );
      case MoodState.excited:
        return (Icons.emoji_emotions_rounded, const Color(0xFFFFB74D), '兴奋');
      case MoodState.calm:
        return (Icons.sentiment_satisfied_rounded, colorScheme.primary, '平静');
      case MoodState.sleepy:
        return (
          Icons.sentiment_dissatisfied_rounded,
          const Color(0xFFB39DDB),
          '困了',
        );
      case MoodState.hungry:
        return (Icons.ramen_dining_rounded, colorScheme.tertiary, '饿了');
      case MoodState.thinking:
        return (Icons.help_outline_rounded, const Color(0xFF7C4DFF), '纠结');
    }
  }

  void _showMoodSelector() {
    final theme = Theme.of(context);
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "取消",
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ),
                    Text(
                      "今天心情如何？",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 60),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 心情选项
              Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: MoodState.values.map((mood) {
                    final (icon, color, label) = _getMoodConfigForState(mood);
                    final isSelected = _userMood == mood;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _userMood = mood);
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withValues(alpha: 0.8),
                                  color
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? Border.all(
                                      color: color,
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: Icon(icon, color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, String) _getMoodConfigForState(MoodState mood) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (mood) {
      case MoodState.happy:
        return (
          Icons.sentiment_very_satisfied_rounded,
          const Color(0xFF81C784),
          '开心',
        );
      case MoodState.excited:
        return (Icons.emoji_emotions_rounded, const Color(0xFFFFB74D), '兴奋');
      case MoodState.calm:
        return (Icons.sentiment_satisfied_rounded, colorScheme.primary, '平静');
      case MoodState.sleepy:
        return (
          Icons.sentiment_dissatisfied_rounded,
          const Color(0xFFB39DDB),
          '困了',
        );
      case MoodState.hungry:
        return (Icons.ramen_dining_rounded, colorScheme.tertiary, '饿了');
      case MoodState.thinking:
        return (Icons.help_outline_rounded, const Color(0xFF7C4DFF), '纠结');
    }
  }

  /// 今日推荐卡片 - 核心操作
  Widget _buildTodayRecommendationCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.9),
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 标题行
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shuffle_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "随便吃点",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      "纠结症发作？让我帮你决定",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 主操作按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const RandomMealDialog(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colorScheme.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "随机推荐一道菜",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 今日菜单卡片
  Widget _buildTodayMenuCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasMenu = _todayRecipes.isNotEmpty;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (hasMenu ? colorScheme.primary : colorScheme.tertiary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasMenu
                          ? Icons.restaurant_menu_rounded
                          : Icons.menu_book_rounded,
                      color: hasMenu ? colorScheme.primary : colorScheme.tertiary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("今日菜单", style: theme.textTheme.titleMedium),
                        if (hasMenu)
                          Text(
                            "已有 ${_todayRecipes.length} 道菜品",
                            style: theme.textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ),
                  if (hasMenu)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        "${_todayRecipes.length} 道",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // 菜单内容
              if (hasMenu) _buildMenuList() else _buildEmptyMenuState(),
            ],
          ),
        ),
        // 食材状态栏
        if (hasMenu && _ingredientCheckResult != null) ...[
          const SizedBox(height: 12),
          _buildIngredientStatusBar(),
        ],
      ],
    );
  }

  Widget _buildMenuList() {
    return Column(
      children: _todayRecipes.asMap().entries.map((entry) {
        final recipe = entry.value;
        final isLast = entry.key == _todayRecipes.length - 1;

        return Column(
          children: [
            _buildMenuItem(recipe),
            if (!isLast) const SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMenuItem(Recipe recipe) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.secondary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // 序号标签
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.8),
                    colorScheme.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(
                Icons.numbers_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 12),
            // 菜名
            Expanded(
              child: Text(
                recipe.name,
                style: theme.textTheme.titleSmall?.copyWith(fontSize: 14),
              ),
            ),
            // 标签
            if (recipe.tags.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  recipe.tags.first,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMenuState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(
              Icons.ramen_dining_rounded,
              size: 40,
              color: colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              "今天还没有安排菜单",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const RandomMealDialog(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18),
                  SizedBox(width: 6),
                  Text(
                    "随机推荐",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 食材提醒区域
  Widget _buildIngredientAlertSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final urgentCount = _expiringIngredients.where((i) => i.urgent).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    (urgentCount > 0
                            ? colorScheme.tertiary
                            : colorScheme.primary)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                urgentCount > 0
                    ? Icons.warning_rounded
                    : Icons.notifications_none_rounded,
                color: urgentCount > 0
                    ? colorScheme.tertiary
                    : colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text("食材提醒", style: theme.textTheme.titleMedium),
            const Spacer(),
            if (urgentCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  "$urgentCount 项紧急",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.tertiary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // 食材列表
        ..._expiringIngredients.map(
          (ingredient) => _buildIngredientItem(ingredient),
        ),
      ],
    );
  }

  Widget _buildIngredientItem(IngredientItem ingredient) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUrgent = ingredient.urgent;
    final alertColor = isUrgent ? colorScheme.tertiary : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isUrgent
              ? colorScheme.tertiary.withValues(alpha: 0.05)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // 食材图标
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: alertColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  ingredient.icon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 14),
                  ),
                  Text(ingredient.amount, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            // 过期时间
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: alertColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                ingredient.expiryText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: alertColor,
                ),
              ),
            ),
          ],
        ),
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

  /// 构建食材状态栏
  Widget _buildIngredientStatusBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allSufficient = _ingredientCheckResult!.allSufficient;
    final insufficientCount = _ingredientCheckResult!.insufficientIngredients.length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const IngredientCheckScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: allSufficient
              ? colorScheme.primary.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: allSufficient
                ? colorScheme.primary.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: allSufficient ? colorScheme.primary : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                allSufficient ? Icons.check_circle : Icons.warning,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allSufficient ? '食材充足' : '食材不足',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: allSufficient ? colorScheme.primary : Colors.red,
                    ),
                  ),
                  if (!allSufficient)
                    Text(
                      '有 $insufficientCount 种食材需要补充',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// 心情状态
enum MoodState { happy, excited, calm, sleepy, hungry, thinking }
