import 'package:flutter/material.dart';
import '../models/ingredient_item.dart';
import '../services/ingredient_service.dart';

/// 添加购物项对话框
class AddShoppingItemDialog extends StatefulWidget {
  final Function(String name, String amount) onAdd;

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

  /// 显示数量输入对话框
  Future<void> _showAmountDialog(String name) async {
    final amountController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加 $name'),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(
            labelText: '预计购买数量',
            hintText: '例如: 2个, 500g',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onAdd(name, amountController.text);
              Navigator.pop(context); // Close amount dialog
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
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
                  : ListView.builder(
                      itemCount: _filteredIngredients.length + (_searchController.text.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        // 如果有输入内容，第一个显示"直接添加"选项
                        if (_searchController.text.isNotEmpty) {
                          if (index == 0) {
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.add),
                              ),
                              title: Text('直接添加 "${_searchController.text}"'),
                              subtitle: const Text('作为新食材添加'),
                              onTap: () {
                                _showAmountDialog(_searchController.text);
                              },
                            );
                          }
                          // 修正索引以获取正确的食材
                          final item = _filteredIngredients[index - 1];
                          return _buildIngredientTile(item);
                        }
                        
                        // 没有输入内容，直接显示列表
                        final item = _filteredIngredients[index];
                        return _buildIngredientTile(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientTile(IngredientItem item) {
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
        _showAmountDialog(item.name);
      },
    );
  }
}
