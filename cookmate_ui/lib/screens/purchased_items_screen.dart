import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/shopping_item.dart';
import '../services/shopping_service.dart';
import '../widgets/refreshable_screen.dart';

// --- Theme Constants ---
const Color _oatmeal = Color(0xFFF5F5F0);
const Color _sageGreen = Color(0xFFB2AC88);
const Color _textPrimary = Color(0xFF4A4F50);
const Color _textSecondary = Color(0xFF8C8F90);

// --- Helper Components ---

class BouncyCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const BouncyCard({super.key, required this.child, this.onTap});

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
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
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
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _controller.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      onTap: widget.onTap,
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
                  blurRadius: 16,
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

class MinimalInput extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? prefixText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  const MinimalInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixText,
    this.onChanged,
    this.keyboardType,
  });

  @override
  State<MinimalInput> createState() => _MinimalInputState();
}

class _MinimalInputState extends State<MinimalInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
      () => setState(() => _isFocused = _focusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _isFocused
            ? _sageGreen.withValues(alpha: 0.05)
            : _oatmeal.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (widget.prefixText != null)
            Text(
              widget.prefixText!,
              style: const TextStyle(
                fontSize: 14,
                color: _textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              onChanged: widget.onChanged,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: _textSecondary.withValues(alpha: 0.3),
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Main Screen ---

class PurchasedItemsScreen extends RefreshableScreen {
  final String listId;

  const PurchasedItemsScreen({super.key, required this.listId});

  @override
  State<PurchasedItemsScreen> createState() => _PurchasedItemsScreenState();
}

class _PurchasedItemsScreenState extends State<PurchasedItemsScreen>
    with RefreshableScreenState<PurchasedItemsScreen> {
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
    if (widget.listId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final list = await _shoppingService.getShoppingListDetail(widget.listId);
      if (list != null) {
        setState(() {
          _items = list.items.where((item) => item.checked).toList();
        });
      }
    } catch (e) {
      debugPrint('加载失败: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateItem(
    ShoppingItem item,
    String field,
    String value,
  ) async {
    double? newPrice;
    String? newActualAmount;
    if (field == 'price') {
      newPrice = double.tryParse(value) ?? item.price;
    } else if (field == 'actualAmount') {
      newActualAmount = value;
    }
    await _shoppingService.updateShoppingItem(
      widget.listId,
      item.id,
      price: newPrice,
      actualAmount: newActualAmount,
    );
    // Silent update in background or update local state if needed
  }

  Future<void> _generateBill() async {
    HapticFeedback.heavyImpact();
    final success = await _shoppingService.completeShoppingList(widget.listId);
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('采购记录已封存 🛒')));
      Navigator.pop(context, true);
    }
  }

  double get _totalPrice => _items.fold(0, (sum, item) => sum + item.price);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _oatmeal,
      appBar: AppBar(
        backgroundColor: _oatmeal,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '收纳小记',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: _textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _sageGreen),
                  )
                : _items.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: BouncyCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _sageGreen.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_rounded,
                                        size: 18,
                                        color: _sageGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: MinimalInput(
                                        controller:
                                            TextEditingController(
                                                text:
                                                    item.actualAmount.isNotEmpty
                                                    ? item.actualAmount
                                                    : item.amount,
                                              )
                                              ..selection = TextSelection.collapsed(
                                                offset:
                                                    (item
                                                                .actualAmount
                                                                .isNotEmpty
                                                            ? item.actualAmount
                                                            : item.amount)
                                                        .length,
                                              ),
                                        hintText: "实际分量",
                                        onChanged: (val) => _updateItem(
                                          item,
                                          'actualAmount',
                                          val,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: MinimalInput(
                                        controller:
                                            TextEditingController(
                                                text: item.price > 0
                                                    ? item.price
                                                          .toStringAsFixed(2)
                                                    : "",
                                              )
                                              ..selection = TextSelection.collapsed(
                                                offset:
                                                    (item.price > 0
                                                            ? item.price
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  )
                                                            : "")
                                                        .length,
                                              ),
                                        hintText: "支出金额",
                                        prefixText: "¥ ",
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        onChanged: (val) {
                                          setState(() {
                                            // We update local item to reflect total price instantly
                                            final index = _items.indexWhere(
                                              (i) => i.id == item.id,
                                            );
                                            if (index != -1) {
                                              _items[index] = _items[index]
                                                  .copyWith(
                                                    price:
                                                        double.tryParse(val) ??
                                                        0,
                                                  );
                                            }
                                          });
                                          _updateItem(item, 'price', val);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '总计支出',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '¥ ${_totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _sageGreen,
                    height: 1,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _items.isEmpty ? null : _generateBill,
              style: ElevatedButton.styleFrom(
                backgroundColor: _sageGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                '生成账单',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: _textSecondary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            "篮子里空空如也",
            style: TextStyle(color: _textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
