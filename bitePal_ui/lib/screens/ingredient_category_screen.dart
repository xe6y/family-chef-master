import 'package:flutter/material.dart';
import '../models/ingredient_item.dart';
import '../services/ingredient_service.dart';
import '../services/storage_location_service.dart';

/// 分类管理页面
class IngredientCategoryScreen extends StatefulWidget {
  const IngredientCategoryScreen({super.key});

  @override
  State<IngredientCategoryScreen> createState() => _IngredientCategoryScreenState();
}

class _IngredientCategoryScreenState extends State<IngredientCategoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '食材分类'),
            Tab(text: '位置分类'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          IngredientCategoryTab(),
          StorageLocationTab(),
        ],
      ),
    );
  }
}

/// 食材分类标签页
class IngredientCategoryTab extends StatefulWidget {
  const IngredientCategoryTab({super.key});

  @override
  State<IngredientCategoryTab> createState() => _IngredientCategoryTabState();
}

class _IngredientCategoryTabState extends State<IngredientCategoryTab> {
  final IngredientCategoryService _categoryService = IngredientCategoryService();
  List<IngredientCategory> _categories = [];
  bool _isLoading = true;
  // 控制分组展开/折叠
  bool _userCategoriesExpanded = true;
  bool _systemCategoriesExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      _categories = await _categoryService.getCategories();
    } catch (e) {
      debugPrint('加载分类失败: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _addCategory() async {
    final result = await _showCategoryDialog(context);
    if (result != null) {
      final category = await _categoryService.createCategory(
        name: result['name']!,
        icon: result['icon'] ?? '📦',
        color: result['color'] ?? '#9E9E9E',
      );
      if (category != null) {
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('添加成功')));
        }
      }
    }
  }

  Future<void> _editCategory(IngredientCategory category) async {
    if (category.isSystem) return;
    final result = await _showCategoryDialog(
      context,
      initialName: category.name,
      initialIcon: category.icon,
      initialColor: category.color,
    );
    if (result != null) {
      final updated = await _categoryService.updateCategory(
        category.id,
        name: result['name'],
        icon: result['icon'],
        color: result['color'],
      );
      if (updated != null) {
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('更新成功')));
        }
      }
    }
  }

  Future<void> _deleteCategory(IngredientCategory category) async {
    if (category.isSystem) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分类"${category.name}"吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _categoryService.deleteCategory(category.id);
      if (success) {
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除成功')));
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败，该分类下可能还有食材')));
      }
    }
  }

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
    final systemCategories = _categories.where((c) => c.isSystem).toList();
    final userCategories = _categories.where((c) => !c.isSystem).toList();

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (userCategories.isNotEmpty) ...[
                    _buildSectionHeader(
                      '我的分类',
                      userCategories.length,
                      _userCategoriesExpanded,
                      () => setState(() => _userCategoriesExpanded = !_userCategoriesExpanded),
                    ),
                    if (_userCategoriesExpanded)
                      ...userCategories.map((cat) => _buildCategoryItem(cat, canEdit: true)),
                    const SizedBox(height: 16),
                  ],
                  _buildSectionHeader(
                    '系统分类',
                    systemCategories.length,
                    _systemCategoriesExpanded,
                    () => setState(() => _systemCategoriesExpanded = !_systemCategoriesExpanded),
                  ),
                  if (_systemCategoriesExpanded)
                    ...systemCategories.map((cat) => _buildCategoryItem(cat, canEdit: false)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        heroTag: 'add_category',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, bool isExpanded, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(isExpanded ? Icons.expand_more : Icons.chevron_right, size: 24),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('$count个', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IngredientCategory category, {required bool canEdit}) {
    final color = _parseColor(category.color);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(category.icon, style: const TextStyle(fontSize: 24))),
        ),
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: canEdit
            ? IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editCategory(category))
            : Icon(Icons.lock, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
        onTap: canEdit ? () => _editCategory(category) : null,
        onLongPress: canEdit ? () => _deleteCategory(category) : null,
      ),
    );
  }
}

/// 位置分类标签页
class StorageLocationTab extends StatefulWidget {
  const StorageLocationTab({super.key});

  @override
  State<StorageLocationTab> createState() => _StorageLocationTabState();
}

class _StorageLocationTabState extends State<StorageLocationTab> {
  final StorageLocationService _storageService = StorageLocationService();
  List<StorageLocation> _locations = [];
  bool _isLoading = true;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    try {
      _locations = await _storageService.getStorageLocations();
    } catch (e) {
      debugPrint('加载位置失败: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _addLocation() async {
    final name = await _showNameDialog(context, '添加位置');
    if (name != null) {
      final newLocation = await _storageService.createStorageLocation(
        name,
        _locations.length + 1,
      );
      if (newLocation != null) {
        _loadLocations();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('添加成功')));
      }
    }
  }

  Future<void> _editLocation(StorageLocation location) async {
    final name = await _showNameDialog(context, '编辑位置', initialValue: location.name);
    if (name != null) {
      final updated = await _storageService.updateStorageLocation(location.id, name: name);
      if (updated != null) {
        _loadLocations();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('更新成功')));
      }
    }
  }

  Future<void> _deleteLocation(StorageLocation location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除位置"${location.name}"吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await _storageService.deleteStorageLocation(location.id);
      if (success) {
        _loadLocations();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除成功')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败，该位置下可能还有食材')));
      }
    }
  }

  Future<void> _reorderLocations(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _locations.removeAt(oldIndex);
    _locations.insert(newIndex, item);
    setState(() {}); // 更新UI

    final ids = _locations.map((e) => e.id).toList();
    await _storageService.reorderStorageLocations(ids);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLocations,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(_isExpanded ? Icons.expand_more : Icons.chevron_right, size: 24),
                            const SizedBox(width: 8),
                            const Text('我的位置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('${_locations.length}个', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                    ),
                    if (_isExpanded)
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: _reorderLocations,
                        children: _locations.map((loc) => _buildLocationItem(loc)).toList(),
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLocation,
        heroTag: 'add_location',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLocationItem(StorageLocation location) {
    return Card(
      key: ValueKey(location.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.drag_handle),
        title: Text(location.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editLocation(location),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteLocation(location),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showNameDialog(BuildContext context, String title, {String? initialValue}) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '名称', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) Navigator.pop(context, controller.text);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

Future<Map<String, String>?> _showCategoryDialog(BuildContext context, {String? initialName, String? initialIcon, String? initialColor}) async {
  final nameController = TextEditingController(text: initialName ?? '');
  String selectedIcon = initialIcon ?? '📦';
  String selectedColor = initialColor ?? '#9E9E9E';

  // 简化版图标和颜色选择器，仅为示例
  final icons = ['🥩', '🥬', '🍎', '🥛', '📦'];
  final colors = ['#E53935', '#43A047', '#FB8C00', '#FDD835', '#9E9E9E'];

  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(initialName != null ? '编辑分类' : '添加分类'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '名称')),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: icons.map((icon) => InkWell(
                onTap: () => setDialogState(() => selectedIcon = icon),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: selectedIcon == icon ? Border.all(color: Colors.blue) : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
              )).toList(),
            ),
             const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: colors.map((color) => InkWell(
                onTap: () => setDialogState(() => selectedColor = color),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                    border: selectedColor == color ? Border.all(color: Colors.black, width: 2) : null,
                    shape: BoxShape.circle,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {'name': nameController.text, 'icon': selectedIcon, 'color': selectedColor}),
            child: const Text('保存'),
          ),
        ],
      ),
    ),
  );
}