import 'package:flutter/material.dart';
import '../models/ingredient_item.dart';
import '../services/ingredient_service.dart';

/// 添加购物项对话框
class AddShoppingItemDialog extends StatefulWidget {
  final Function(String name) onAdd;

  const AddShoppingItemDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddShoppingItemDialog> createState() => _AddShoppingItemDialogState();
}

class _AddShoppingItemDialogState extends State<AddShoppingItemDialog> {
  final TextEditingController _searchController = TextEditingController();
  final IngredientService _ingredientService = IngredientService();
  
  List<IngredientItem> _allIngredients = [];
  List<IngredientItem> _filteredIngredients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
    _searchController.addListener(_filterIngredients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载食材库
  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);
    try {
      // 获取所有食材
      final ingredients = await _ingredientService.getIngredients();
      _allIngredients = ingredients;
      _filteredIngredients = ingredients;
    } catch (e) {
      debugPrint('加载食材失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 过滤食材
  void _filterIngredients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredIngredients = _allIngredients;
      } else {
        _filteredIngredients = _allIngredients
            .where((item) => item.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '添加食材',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索食材...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredIngredients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _searchController.text.isEmpty ? '暂无食材' : '未找到相关食材',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    widget.onAdd(_searchController.text);
                                  },
                                  icon: const Icon(Icons.add),
                                  label: Text('直接添加 "${_searchController.text}"'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredIngredients.length,
                          itemBuilder: (context, index) {
                            final item = _filteredIngredients[index];
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  item.name.isNotEmpty ? item.name[0] : '?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              title: Text(item.name),
                              subtitle: Text(item.categoryName),
                              trailing: const Icon(Icons.add_circle_outline),
                              onTap: () {
                                widget.onAdd(item.name);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
