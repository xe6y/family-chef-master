import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../services/shopping_service.dart';
import '../widgets/refreshable_screen.dart';

/// 已购买食材页面
class PurchasedItemsScreen extends RefreshableScreen {
  final String listId;

  const PurchasedItemsScreen({super.key, required this.listId});

  @override
  State<PurchasedItemsScreen> createState() => _PurchasedItemsScreenState();
}

class _PurchasedItemsScreenState extends State<PurchasedItemsScreen> with RefreshableScreenState<PurchasedItemsScreen> {
  final ShoppingService _shoppingService = ShoppingService();
  List<ShoppingItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  Future<void> refresh() async {
    await _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final list = await _shoppingService.getShoppingListDetail(widget.listId);
      if (list != null) {
        setState(() {
          _items = list.items.where((item) => item.checked).toList();
        });
      }
    } catch (e) {
      debugPrint('加载已购买食材失败: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateItem(ShoppingItem item, String field, String value) async {
    try {
      double? newPrice;
      String? newActualAmount;

      if (field == 'price') {
        newPrice = double.tryParse(value) ?? item.price;
      } else if (field == 'actualAmount') {
        newActualAmount = value;
      }

      final updated = await _shoppingService.updateShoppingItem(
        widget.listId,
        item.id,
        price: newPrice,
        actualAmount: newActualAmount,
      );

      if (updated != null) {
        setState(() {
          final index = _items.indexWhere((i) => i.id == item.id);
          if (index != -1) {
            _items[index] = updated;
          }
        });
      }
    } catch (e) {
      debugPrint('更新失败: $e');
    }
  }

  Future<void> _generateBill() async {
    final success = await _shoppingService.completeShoppingList(widget.listId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('账单生成成功')),
      );
      Navigator.pop(context, true); // Return success
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('生成账单失败')),
      );
    }
  }

  double get _totalPrice => _items.fold(0, (sum, item) => sum + item.price);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('已购买食材'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: item.actualAmount.isNotEmpty ? item.actualAmount : item.amount,
                                      decoration: const InputDecoration(
                                        labelText: '购买数量',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (val) => _updateItem(item, 'actualAmount', val),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: item.price > 0 ? item.price.toString() : '',
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: '花费金额',
                                        prefixText: '¥ ',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (val) => _updateItem(item, 'price', val),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '总计金额',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      '¥ ${_totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _generateBill,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('生成账单'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
