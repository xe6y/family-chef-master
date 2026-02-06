import 'package:flutter/material.dart';
import '../models/ingredient_item.dart';
import '../services/ingredient_service.dart';
import '../services/storage_location_service.dart';

// --- Theme Colors ---
const Color _oatmeal = Color(0xFFF5F5F0);
const Color _sageGreen = Color(0xFFB2AC88);
const Color _persimmon = Color(0xFFE58A73);
const Color _textPrimary = Color(0xFF4A4F50);
const Color _textSecondary = Color(0xFF8C8F90);

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
      backgroundColor: _oatmeal,
      appBar: AppBar(
        backgroundColor: _oatmeal,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '分类管理',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: _textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _sageGreen,
          unselectedLabelColor: _textSecondary,
          indicatorColor: _sageGreen.withValues(alpha: 0.3),
          indicatorWeight: 2,
          dividerColor: Colors.transparent,
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '确认删除',
          style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
        ),
        content: Text(
          '确定要删除分类"${category.name}"吗？',
          style: const TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _persimmon,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
      backgroundColor: _oatmeal,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _sageGreen))
          : RefreshIndicator(
              color: _sageGreen,
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
        backgroundColor: _sageGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, bool isExpanded, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
              size: 24,
              color: _sageGreen,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _sageGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count个',
                style: TextStyle(
                  fontSize: 12,
                  color: _sageGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IngredientCategory category, {required bool canEdit}) {
    final color = _parseColor(category.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              category.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: _textPrimary,
          ),
        ),
        trailing: canEdit
            ? IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                color: _sageGreen,
                onPressed: () => _editCategory(category),
              )
            : Icon(
                Icons.lock_rounded,
                size: 18,
                color: _textSecondary.withValues(alpha: 0.4),
              ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '确认删除',
          style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
        ),
        content: Text(
          '确定要删除位置"${location.name}"吗？',
          style: const TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _persimmon,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
      backgroundColor: _oatmeal,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _sageGreen))
          : RefreshIndicator(
              color: _sageGreen,
              onRefresh: _loadLocations,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(
                              _isExpanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                              size: 24,
                              color: _sageGreen,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '我的位置',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _sageGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_locations.length}个',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _sageGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
        backgroundColor: _sageGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildLocationItem(StorageLocation location) {
    return Container(
      key: ValueKey(location.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _sageGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.drag_handle_rounded,
            color: _sageGreen,
            size: 20,
          ),
        ),
        title: Text(
          location.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: _textPrimary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: _sageGreen,
              onPressed: () => _editLocation(location),
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, size: 20),
              color: _persimmon,
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: _textPrimary),
          decoration: InputDecoration(
            labelText: '名称',
            labelStyle: TextStyle(color: _textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _textSecondary.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _sageGreen, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) Navigator.pop(context, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _sageGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          initialName != null ? '编辑分类' : '添加分类',
          style: const TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: _textPrimary),
              decoration: InputDecoration(
                labelText: '名称',
                labelStyle: TextStyle(color: _textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _textSecondary.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _sageGreen, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '选择图标',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: icons.map((icon) => InkWell(
                onTap: () => setDialogState(() => selectedIcon = icon),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedIcon == icon
                        ? _sageGreen.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.1),
                    border: Border.all(
                      color: selectedIcon == icon ? _sageGreen : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
              )).toList(),
            ),
             const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '选择颜色',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((color) => InkWell(
                onTap: () => setDialogState(() => selectedColor = color),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                    border: Border.all(
                      color: selectedColor == color ? _textPrimary : Colors.transparent,
                      width: 3,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: selectedColor == color
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {'name': nameController.text, 'icon': selectedIcon, 'color': selectedColor}),
            style: ElevatedButton.styleFrom(
              backgroundColor: _sageGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    ),
  );
}