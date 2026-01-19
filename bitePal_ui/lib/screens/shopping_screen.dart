import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../services/shopping_service.dart';
import '../widgets/refreshable_screen.dart';
import '../widgets/add_shopping_item_dialog.dart';
import 'purchased_items_screen.dart';

/// 购物清单页面
class ShoppingScreen extends RefreshableScreen {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> with RefreshableScreenState<ShoppingScreen> {
  final ShoppingService _shoppingService = ShoppingService();
  ShoppingList? _currentList;
  List<ShoppingItem> _items = []; // Items to buy (checked == false)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
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
        // Only show unchecked items in the main list
        _items = list.items.where((item) => !item.checked).toList();
      }
    } catch (e) {
      debugPrint('加载购物清单失败: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteItem(ShoppingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${item.name}" 吗？'),
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

    if (confirmed == true && _currentList != null) {
      await _shoppingService.deleteShoppingItem(_currentList!.id, item.id);
      setState(() {
        _items.removeWhere((i) => i.id == item.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除')));
      }
    }
  }

  Future<void> _markAsPurchased(ShoppingItem item) async {
    if (_currentList != null) {
      // Mark as checked (purchased)
      // When marking as purchased, we can default actualAmount to estimated amount if not set
      final actualAmount = item.actualAmount.isNotEmpty ? item.actualAmount : item.amount;
      
      await _shoppingService.updateShoppingItem(
        _currentList!.id,
        item.id,
        checked: true,
        actualAmount: actualAmount,
      );
      
      setState(() {
        _items.removeWhere((i) => i.id == item.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已将 "${item.name}" 加入已购买'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: '撤销',
              onPressed: () => _undoPurchase(item),
            ),
          ),
        );
      }
    }
  }
  
  Future<void> _undoPurchase(ShoppingItem item) async {
    if (_currentList != null) {
      await _shoppingService.updateShoppingItem(
        _currentList!.id,
        item.id,
        checked: false,
      );
      _loadShoppingList(); // Reload to get it back in order
    }
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
          } else {
             // Create list if not exists? Usually handled by backend or init.
             // For now assuming list exists as per previous logic.
          }
        },
      ),
    );
  }

  void _finishShopping() async {
    if (_currentList != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PurchasedItemsScreen(listId: _currentList!.id),
        ),
      );
      
      if (result == true) {
        // Bill generated, refresh list (it should be empty or new list)
        _loadShoppingList();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    "购物清单",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // Removed top Add button
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadShoppingList,
                      child: _items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "待购列表为空",
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return Dismissible(
                                  key: Key(item.id),
                                  // Left Swipe: Mark as Purchased
                                  background: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 16),
                                    color: Colors.green,
                                    child: const Icon(Icons.check, color: Colors.white),
                                  ),
                                  // Right Swipe: Delete
                                  secondaryBackground: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 16),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  confirmDismiss: (direction) async {
                                    if (direction == DismissDirection.endToStart) {
                                      // Delete confirm
                                      return await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('确认删除'),
                                          content: Text('确定要删除 "${item.name}" 吗？'),
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
                                    } else {
                                      // Mark purchased, auto confirm
                                      return true;
                                    }
                                  },
                                  onDismissed: (direction) {
                                    if (direction == DismissDirection.endToStart) {
                                      _deleteItem(item);
                                    } else {
                                      _markAsPurchased(item);
                                    }
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      height: 80, // Fixed height for centering
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (item.amount.isNotEmpty)
                                                  Text(
                                                    "预计: ${item.amount}",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_item',
            onPressed: _showAddItemDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加食材'),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'finish_shopping',
            onPressed: _finishShopping,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('购物结束'),
          ),
        ],
      ),
    );
  }
}