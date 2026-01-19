import 'package:flutter/material.dart';
import '../models/ingredient_item.dart';
import '../models/shopping_item.dart';
import '../services/ingredient_service.dart';
import '../services/storage_location_service.dart';
import '../config/api_config.dart';
import '../widgets/refreshable_screen.dart';
import 'ingredient_detail_screen.dart';
import 'ingredient_edit_screen.dart';
import 'ingredient_category_screen.dart';
import 'shopping_history_selection_screen.dart';

/// 食材库存页面
class IngredientsScreen extends RefreshableScreen {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> with RefreshableScreenState<IngredientsScreen> {
  /// 食材服务
  final IngredientService _ingredientService = IngredientService();
  final StorageLocationService _storageService = StorageLocationService();

  /// 当前选中的存储位置
  String _activeStorage = ""; // 默认为空，加载后设置为第一个

  /// 存储位置列表
  List<StorageLocation> _storages = [];

  /// 是否正在加载
  bool _isLoading = true;

  /// 分组食材数据
  List<IngredientGroup> _groups = [];

  /// 折叠状态（按分类ID存储）
  final Map<String, bool> _expandedState = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  Future<void> refresh() async {
    await _loadIngredients();
  }

  Future<void> _loadInitialData() async {
    await _loadStorageLocations();
    await _loadIngredients();
  }

  /// 加载存储位置
  Future<void> _loadStorageLocations() async {
    try {
      final locations = await _storageService.getStorageLocations();
      if (mounted) {
        setState(() {
          _storages = locations;
          // 如果当前没有选中位置，且有位置数据，选中第一个
          if (_activeStorage.isEmpty && _storages.isNotEmpty) {
            _activeStorage = _storages.first.id;
          }
        });
      }
    } catch (e) {
      debugPrint('加载存储位置失败: $e');
    }
  }

  /// 加载食材数据
  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);

    try {
      // 如果还没有存储位置，先不加载
      if (_activeStorage.isEmpty && _storages.isEmpty) {
        // 尝试再次加载存储位置
        await _loadStorageLocations();
        if (_activeStorage.isEmpty) {
             setState(() => _isLoading = false);
             return;
        }
      }

      // 加载分组数据
      _groups = await _ingredientService.getIngredientsGrouped(storage: _activeStorage);

      // 默认展开所有分组
      for (var group in _groups) {
        _expandedState[group.category.id] ??= true;
      }
    } catch (e) {
      debugPrint('加载食材失败: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 删除食材
  Future<void> _deleteIngredient(IngredientItem ingredient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${ingredient.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _ingredientService.deleteIngredient(ingredient.id);
      if (success) {
        _loadIngredients();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功'), duration: Duration(seconds: 1)),
          );
        }
      }
    }
  }

  /// 处理添加食材逻辑
  void _handleAddIngredient() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('直接创建'),
              onTap: () {
                Navigator.pop(context);
                _openAddIngredientScreen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('从历史购物订单选择'),
              onTap: () {
                Navigator.pop(context);
                _selectFromHistory();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 打开添加食材页面（直接创建或带预填数据）
  Future<void> _openAddIngredientScreen({IngredientItem? prefillData}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => IngredientEditScreen(
          defaultStorage: _activeStorage,
          ingredient: prefillData, // 如果是预填模式，这里可能需要特殊处理，因为IngredientEditScreen通常用于编辑已存在的。
          // 更好的做法是传递一个初始值对象，而不是复用编辑对象，或者修改IngredientEditScreen支持initialData。
          // 暂时我们假设IngredientEditScreen如果传入的ingredient没有id，则视为新建。
          // 检查 IngredientItem 模型，id通常是必须的。
          // 我们可以在 IngredientEditScreen 增加一个 initialData 参数。
        ),
      ),
    );

    if (result == true) {
      _loadIngredients();
    }
  }
  
  /// 从历史选择
  Future<void> _selectFromHistory() async {
    final ShoppingItem? selected = await Navigator.push<ShoppingItem>(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingHistorySelectionScreen()),
    );

    if (selected != null) {
      // 解析数量和单位
      double quantity = 0;
      String unit = '个';
      String amount = selected.amount;
      
      // 简单尝试解析 "2个", "500g" 等
      final RegExp regex = RegExp(r'^(\d+(\.\d+)?)\s*(.*)$');
      final match = regex.firstMatch(amount);
      if (match != null) {
        quantity = double.tryParse(match.group(1) ?? '0') ?? 0;
        unit = match.group(3) ?? '个';
      }

      // 构造预填数据的 IngredientItem
      // 注意：这里 id 为空，表示是新创建
      final prefill = IngredientItem(
        id: '', // 空ID表示新建
        name: selected.name,
        quantity: quantity,
        unit: unit,
        amount: amount,
        storage: _activeStorage,
        categoryId: 'cat_other',
        icon: '🥬',
        expiryDays: 7,
        expiryText: '',
      );

      _openAddIngredientScreen(prefillData: prefill);
    }
  }

  /// 打开食材详情页面
  Future<void> _openIngredientDetail(IngredientItem ingredient) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => IngredientDetailScreen(
          ingredientId: ingredient.id,
          initialIngredient: ingredient,
        ),
      ),
    );

    if (result == true) {
      _loadIngredients();
    }
  }

  /// 打开分类管理页面
  Future<void> _openCategoryManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IngredientCategoryScreen(),
      ),
    );
    // 返回后刷新数据（可能位置或分类有变动）
    _loadInitialData();
  }

  /// 解析颜色字符串
  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return Colors.grey;
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 头部
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "食材库存",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _openCategoryManagement,
                        child: const Text('分类管理', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 存储位置标签 (可滚动)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // 紧凑布局
                        children: _storages.map((storage) {
                          final isActive = _activeStorage == storage.id;
                          return InkWell(
                            onTap: () {
                              setState(() => _activeStorage = storage.id);
                              _loadIngredients();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isActive ? Theme.of(context).cardColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                storage.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                  color: isActive
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 食材列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadIngredients,
                      child: _groups.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _groups.length,
                              itemBuilder: (context, index) {
                                return _buildCategoryGroup(_groups[index]);
                              },
                            ),
                    ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "ingredients_fab",
        onPressed: _handleAddIngredient,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.kitchen,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "暂无食材",
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _handleAddIngredient,
            icon: const Icon(Icons.add),
            label: const Text('添加食材'),
          ),
        ],
      ),
    );
  }

  /// 构建分类分组
  Widget _buildCategoryGroup(IngredientGroup group) {
    final isExpanded = _expandedState[group.category.id] ?? true;
    final categoryColor = _parseColor(group.category.color);

    return Column(
      children: [
        // 分类标题（可折叠）
        InkWell(
          onTap: () {
            setState(() {
              _expandedState[group.category.id] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                // 分类图标和名称
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(group.category.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        group.category.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 数量标签
                Text(
                  '${group.count}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                // 展开/折叠图标
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),

        // 食材列表（可折叠）
        if (isExpanded)
          ...group.ingredients.map((ingredient) => _buildIngredientItem(ingredient)),

        const SizedBox(height: 8),
      ],
    );
  }

  /// 构建食材项
  Widget _buildIngredientItem(IngredientItem ingredient) {
    final hasImage = ingredient.thumbnail.isNotEmpty;

    return Dismissible(
      key: Key(ingredient.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除"${ingredient.name}"吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteIngredient(ingredient),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: () => _openIngredientDetail(ingredient),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasImage
                  ? Image.network(
                      ingredient.thumbnail.startsWith('http')
                          ? ingredient.thumbnail
                          : '${ApiConfig.devBaseUrl.replaceAll('/api', '')}${ingredient.thumbnail}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(ingredient.icon, style: const TextStyle(fontSize: 28)),
                      ),
                    )
                  : Center(
                      child: Text(ingredient.icon, style: const TextStyle(fontSize: 28)),
                    ),
            ),
          ),
          title: Text(
            ingredient.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              Text(ingredient.displayAmount),
              if (ingredient.note.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ingredient.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ingredient.urgent
                  ? Colors.red.withValues(alpha: 0.1)
                  : ingredient.expiryDays <= 3
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ingredient.expiryText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ingredient.urgent
                    ? Colors.red.shade600
                    : ingredient.expiryDays <= 3
                        ? Colors.orange.shade600
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}