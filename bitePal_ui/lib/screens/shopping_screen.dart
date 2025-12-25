import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../widgets/edit_item_dialog.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  List<ShoppingItem> _items = [
    ShoppingItem(id: 1, name: "西红柿", amount: "2个", price: 4.5),
    ShoppingItem(id: 2, name: "土豆", amount: "3个", price: 3.2),
    ShoppingItem(id: 3, name: "牛排", amount: "2块", price: 89),
  ];

  void _toggleItem(int id) {
    setState(() {
      _items = _items.map((item) {
        if (item.id == id) {
          return item.copyWith(checked: !item.checked);
        }
        return item;
      }).toList();
    });
  }

  void _editItem(ShoppingItem item) {
    showDialog(
      context: context,
      builder: (context) => EditItemDialog(
        item: item,
        onSave: (updatedItem) {
          setState(() {
            _items = _items
                .map((i) => i.id == updatedItem.id ? updatedItem : i)
                .toList();
          });
        },
      ),
    );
  }

  double get _total {
    return _items.fold(0.0, (sum, item) => sum + item.price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "购物清单",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // Share
                    },
                  ),
                ],
              ),
            ),
            // Shopping Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: IconButton(
                        icon: Icon(
                          item.checked
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: item.checked
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        onPressed: () => _toggleItem(item.id),
                      ),
                      title: Text(
                        item.name,
                        style: TextStyle(
                          decoration: item.checked
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.checked
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4)
                              : null,
                        ),
                      ),
                      subtitle: Text(item.amount),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "¥${item.price.toStringAsFixed(1)}",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: item.checked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.checked
                                  ? Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.4)
                                  : null,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editItem(item),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Total and Checkout - 缩小并靠近底部
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "预计总计",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        "¥ ${_total.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        // Checkout
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        "购买结束",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8), // 为底部导航栏留出空间
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
