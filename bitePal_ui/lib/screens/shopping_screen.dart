import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/shopping_item.dart';
import '../services/shopping_service.dart';
import '../widgets/refreshable_screen.dart';
import '../widgets/add_shopping_item_dialog.dart';
import 'purchased_items_screen.dart';
import 'shopping_history_screen.dart';

// --- Theme Constants ---
const Color _oatmeal = Color(0xFFF5F5F0);
const Color _sageGreen = Color(0xFFB2AC88);
const Color _persimmon = Color(0xFFE58A73);
const Color _textPrimary = Color(0xFF4A4F50);
const Color _textSecondary = Color(0xFF8C8F90);

// --- Helper Components ---

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 10,
    this.opacity = 0.5,
    this.padding = EdgeInsets.zero,
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
            color: Colors.white.withValues(alpha: opacity),
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

  const BouncyCard({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
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

// --- Main Screen ---

class ShoppingScreen extends RefreshableScreen {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen>
    with RefreshableScreenState<ShoppingScreen> {
  final ShoppingService _shoppingService = ShoppingService();
  final TextEditingController _searchController = TextEditingController();
  ShoppingList? _currentList;
  List<ShoppingItem> _allItems = [];
  List<ShoppingItem> _items = [];
  bool _isLoading = true;
  bool _isSearchExpanded = false;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Future<void> refresh() async {
    await _loadShoppingList();
  }

  Future<void> _loadShoppingList() async {
    setState(() => _isLoading = true);
    try {
      final list = await _shoppingService.getCurrentShoppingList();
      if (list != null) {
        _currentList = list;
        _allItems = list.items.where((item) => !item.checked).toList();
        _items = _filterItems(_allItems);
      }
    } catch (e) {
      debugPrint('加载失败: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<ShoppingItem> _filterItems(List<ShoppingItem> source) {
    final keyword = _searchKeyword.trim().toLowerCase();
    if (keyword.isEmpty) return List<ShoppingItem>.from(source);
    return source
        .where((item) => item.name.toLowerCase().contains(keyword))
        .toList();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded && _searchKeyword.isNotEmpty) {
        _searchController.clear();
        _searchKeyword = '';
        _items = _filterItems(_allItems);
      }
    });
  }

  Future<void> _markAsPurchased(ShoppingItem item) async {
    if (_currentList == null) return;
    HapticFeedback.mediumImpact();
    final actualAmount = item.actualAmount.isNotEmpty
        ? item.actualAmount
        : item.amount;
    await _shoppingService.updateShoppingItem(
      _currentList!.id,
      item.id,
      checked: true,
      actualAmount: actualAmount,
    );
    setState(() {
      _allItems.removeWhere((i) => i.id == item.id);
      _items = _filterItems(_allItems);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${item.name}" 已放入菜篮 🧺'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AddShoppingItemDialog(
        onAdd: (name, amount) async {
          Navigator.pop(context);
          if (_currentList != null) {
            await _shoppingService.addShoppingItem(
              _currentList!.id,
              name: name,
              amount: amount,
              price: 0,
            );
            _loadShoppingList();
          }
        },
      ),
    );
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
            toolbarHeight: 68,
            backgroundColor: _oatmeal,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 16,
            title: _buildAppBarTitle(),
            actions: _isSearchExpanded
                ? []
                : [
                    _buildActionButton(
                      icon: Icons.history_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShoppingHistoryScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
          ),

          // 2. Shopping List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            sliver: _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: _sageGreen),
                    ),
                  )
                : _items.isEmpty
                ? SliverFillRemaining(child: _buildEmptyState())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildShoppingItem(_items[index]),
                      childCount: _items.length,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildAppBarTitle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const titleStyle = TextStyle(
          fontWeight: FontWeight.w800,
          color: _textPrimary,
        );
        final maxWidth = constraints.maxWidth;
        final searchWidth = _isSearchExpanded ? maxWidth : 40.0;
        const gap = 8.0;
        if (_isSearchExpanded) {
          return SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildSearchButton(searchWidth),
            ),
          );
        }
        return SizedBox(
          height: 40,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.only(right: 40 + gap),
                  child: const Text(
                    "购物清单",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _buildSearchButton(searchWidth),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchButton(double maxWidth) {
    final collapsedWidth = maxWidth.clamp(0.0, 40.0);
    final targetWidth = _isSearchExpanded ? maxWidth : collapsedWidth;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: targetWidth,
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
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Icon(
                        Icons.arrow_back,
                        color: _textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: "搜索清单项目...",
                          hintStyle: TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 14, color: _textPrimary),
                        onChanged: (val) {
                          setState(() {
                            _searchKeyword = val;
                            _items = _filterItems(_allItems);
                          });
                        },
                        onSubmitted: (val) {
                          setState(() {
                            _searchKeyword = val;
                            _items = _filterItems(_allItems);
                          });
                        },
                      ),
                    ),
                  ),
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

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: GlassContainer(
          borderRadius: 20,
          opacity: 0.6,
          padding: EdgeInsets.zero,
          child: Center(
            child: Icon(icon, color: _textSecondary, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildShoppingItem(ShoppingItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.horizontal,
        background: _buildDismissBackground(
          Alignment.centerLeft,
          Icons.check_circle_rounded,
          _sageGreen,
        ),
        secondaryBackground: _buildDismissBackground(
          Alignment.centerRight,
          Icons.delete_outline_rounded,
          _persimmon,
        ),
        onDismissed: (dir) {
          if (dir == DismissDirection.startToEnd) {
            _markAsPurchased(item);
          } else {
            // Delete logic would go here
          }
        },
        child: BouncyCard(
          onTap: () => _markAsPurchased(item),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _sageGreen.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _textPrimary,
                        ),
                      ),
                      if (item.amount.isNotEmpty)
                        Text(
                          "需要: ${item.amount}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground(Alignment align, IconData icon, Color color) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildModernFAB() {
    return GlassContainer(
      borderRadius: 30,
      opacity: 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFABAction(
            Icons.add_rounded,
            "添加食材",
            _sageGreen,
            _showAddItemDialog,
          ),
          const SizedBox(width: 8),
          _buildFABAction(Icons.shopping_bag_rounded, "去结算", _persimmon, () {
            if (_currentList != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PurchasedItemsScreen(listId: _currentList!.id),
                ),
              ).then((v) {
                if (v == true) _loadShoppingList();
              });
            }
          }),
        ],
      ),
    );
  }

  Widget _buildFABAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
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
            tween: Tween(begin: 0, end: 10),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, v, child) =>
                Transform.translate(offset: Offset(0, v), child: child),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _sageGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 48,
                color: _sageGreen,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "清单已清空",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "所有的美味都已准备就绪 ~",
            style: TextStyle(color: Color(0xFFDCD7CD), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
