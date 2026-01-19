import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/ingredient_item.dart';
import '../models/shopping_item.dart';
import '../services/ingredient_service.dart';
import '../services/storage_location_service.dart';
import '../widgets/refreshable_screen.dart';
import 'ingredient_detail_screen.dart';
import 'ingredient_edit_screen.dart';
import 'ingredient_category_screen.dart';
import 'shopping_history_selection_screen.dart';

// --- Helper Components ---

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

class BouncyCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? activeShadowColor;

  const BouncyCard({
    super.key,
    required this.child,
    this.onTap,
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
      end: 0.96,
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

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
    if (widget.isBreathing) _controller.repeat(reverse: true);
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
      ),
      child: Stack(
        children: [
          if (widget.isBreathing)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: widget.color.withOpacity(_opacityAnimation.value),
                  ),
                ),
              ),
            ),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Main Screen ---

class IngredientsScreen extends RefreshableScreen {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen>
    with RefreshableScreenState<IngredientsScreen> {
  final IngredientService _ingredientService = IngredientService();
  final StorageLocationService _storageService = StorageLocationService();
  final TextEditingController _searchController = TextEditingController();

  // State
  String _activeStorage = "";
  List<StorageLocation> _storages = [];
  List<IngredientGroup> _groups = [];
  bool _isLoading = true;
  String _searchKeyword = '';

  // Theme Colors
  static const Color _sageGreen = Color(0xFFB2AC88);
  static const Color _oatmeal = Color(0xFFF5F5F0);
  static const Color _persimmon = Color(0xFFE58A73);
  static const Color _textPrimary = Color(0xFF4A4F50);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Future<void> refresh() async {
    await _loadIngredients();
  }

  Future<void> _loadInitialData() async {
    await _loadStorageLocations();
    await _loadIngredients();
  }

  Future<void> _loadStorageLocations() async {
    try {
      final locations = await _storageService.getStorageLocations();
      if (mounted && locations.isNotEmpty) {
        setState(() {
          _storages = locations;
          if (_activeStorage.isEmpty) _activeStorage = _storages.first.id;
        });
      }
    } catch (e) {
      debugPrint('加载位置失败: $e');
    }
  }

  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);
    try {
      if (_activeStorage.isEmpty && _storages.isNotEmpty)
        _activeStorage = _storages.first.id;
      final groups = await _ingredientService.getIngredientsGrouped(
        storage: _activeStorage,
      );

      // Local filtering for search
      if (_searchKeyword.isNotEmpty) {
        _groups = groups
            .map(
              (g) => IngredientGroup(
                category: g.category,
                ingredients: g.ingredients
                    .where((i) => i.name.contains(_searchKeyword))
                    .toList(),
                count: g.ingredients
                    .where((i) => i.name.contains(_searchKeyword))
                    .length,
              ),
            )
            .where((g) => g.ingredients.isNotEmpty)
            .toList();
      } else {
        _groups = groups;
      }
    } catch (e) {
      debugPrint('加载食材失败: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _handleAddIngredient() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "添加新食材",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildAddOption(
              Icons.add_circle_outline_rounded,
              "直接创建",
              "手动输入食材信息",
              () {
                Navigator.pop(context);
                _openEditScreen();
              },
            ),
            const SizedBox(height: 16),
            _buildAddOption(Icons.history_rounded, "从历史订单选择", "快速录入买过的食材", () {
              Navigator.pop(context);
              _selectFromHistory();
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption(
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap,
  ) {
    return BouncyCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _oatmeal.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _sageGreen),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditScreen() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IngredientEditScreen(defaultStorage: _activeStorage),
      ),
    );
    if (res == true) _loadIngredients();
  }

  Future<void> _selectFromHistory() async {
    final ShoppingItem? selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShoppingHistorySelectionScreen()),
    );
    if (selected != null) {
      final prefill = IngredientItem(
        id: '',
        name: selected.name,
        quantity: 1,
        unit: '个',
        amount: selected.amount,
        storage: _activeStorage,
        categoryId: 'cat_other',
        icon: '🥬',
        expiryDays: 7,
        expiryText: '',
      );
      final res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IngredientEditScreen(
            defaultStorage: _activeStorage,
            ingredient: prefill,
          ),
        ),
      );
      if (res == true) _loadIngredients();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _oatmeal,
      body: CustomScrollView(
        slivers: [
          // 1. Immersive Header
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 120,
            backgroundColor: _oatmeal,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              "食材模块",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IngredientCategoryScreen(),
                  ),
                ),
                child: const Text("分类管理", style: TextStyle(color: _sageGreen)),
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
                      const Icon(
                        Icons.search,
                        color: Color(0xFF8C8F90),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "搜索我的食材...",
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                          onSubmitted: (v) {
                            _searchKeyword = v;
                            _loadIngredients();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Storage Navigation
          SliverPersistentHeader(
            pinned: true,
            delegate: _StorageHeaderDelegate(
              storages: _storages,
              activeId: _activeStorage,
              onChanged: (id) {
                setState(() => _activeStorage = id);
                _loadIngredients();
              },
            ),
          ),

          // 3. Grid of Ingredients
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: _sageGreen),
              ),
            )
          else if (_groups.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            ..._buildAllGroups(),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "ingredients_fab", // Unique tag to prevent Hero conflict
        onPressed: _handleAddIngredient,
        backgroundColor: _sageGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Widget> _buildAllGroups() {
    final List<Widget> slivers = [];
    for (var group in _groups) {
      slivers.add(
        SliverToBoxAdapter(
          key: ValueKey('header_${group.category.id}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                Text(group.category.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  group.category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${group.count}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );

      slivers.add(
        SliverPadding(
          key: ValueKey('grid_${group.category.id}'),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childCount: group.ingredients.length,
            itemBuilder: (context, idx) =>
                _buildIngredientCard(group.ingredients[idx]),
          ),
        ),
      );
    }
    return slivers;
  }

  Widget _buildIngredientCard(IngredientItem item) {
    final isUrgent = item.urgent || item.expiryDays <= 2;

    return BouncyCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IngredientDetailScreen(
            ingredientId: item.id,
            initialIngredient: item,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon/Image with robust safety check
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _oatmeal.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Builder(
                  builder: (context) {
                    // Check if thumbnail exists and is a valid asset path
                    final hasThumbnail =
                        item.thumbnail.isNotEmpty &&
                        item.thumbnail.startsWith('assets/');
                    if (hasThumbnail) {
                      return Image.asset(
                        item.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildIconPlaceholder(item.icon),
                      );
                    }
                    return _buildIconPlaceholder(item.icon);
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
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.displayAmount,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  StatusChip(
                    label: item.expiryText,
                    color: isUrgent ? _persimmon : _sageGreen,
                    isBreathing: isUrgent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconPlaceholder(String icon) {
    return Text(
      icon.isNotEmpty ? icon : '📦',
      style: const TextStyle(fontSize: 40),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 10),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, v, child) =>
                Transform.translate(offset: Offset(0, v), child: child),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _sageGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.kitchen_outlined,
                size: 48,
                color: _sageGreen,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "储藏柜空空如也",
            style: TextStyle(
              color: Color(0xFF8C8F90),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "快把新鲜食材搬回家吧 ~",
            style: TextStyle(color: Color(0xFFDCD7CD), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// --- Storage Header Delegate ---

class _StorageHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<StorageLocation> storages;
  final String activeId;
  final ValueChanged<String> onChanged;

  _StorageHeaderDelegate({
    required this.storages,
    required this.activeId,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      // Force expand to full height constraint
      child: Container(
        color: const Color(0xFFF5F5F0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: storages.map((s) {
              final isActive = activeId == s.id;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => onChanged(s.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFB2AC88) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        if (isActive)
                          BoxShadow(
                            color: const Color(0xFFB2AC88).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Text(
                      s.name,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF4A4F50),
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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
  bool shouldRebuild(covariant _StorageHeaderDelegate oldDelegate) =>
      activeId != oldDelegate.activeId || storages != oldDelegate.storages;
}
