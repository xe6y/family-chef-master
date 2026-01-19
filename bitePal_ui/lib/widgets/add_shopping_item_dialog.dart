import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ingredient_item.dart';
import '../services/ingredient_service.dart';

// --- Theme Constants ---
const Color _oatmeal = Color(0xFFF5F5F0);
const Color _sageGreen = Color(0xFFB2AC88);
const Color _textPrimary = Color(0xFF4A4F50);
const Color _textSecondary = Color(0xFF8C8F90);

// --- Helper Components ---

class BouncyCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BouncyCard({super.key, required this.child, required this.onTap});

  @override
  State<BouncyCard> createState() => _BouncyCardState();
}

class _BouncyCardState extends State<BouncyCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap(); },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        ),
      ),
    );
  }
}

class MinimalInput extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const MinimalInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.onChanged,
    this.autofocus = false,
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
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() { _focusNode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _isFocused ? _sageGreen.withOpacity(0.08) : _oatmeal.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isFocused ? _sageGreen.withOpacity(0.2) : Colors.transparent),
      ),
      child: Row(
        children: [
          if (widget.prefixIcon != null)
            Icon(widget.prefixIcon, size: 18, color: _isFocused ? _sageGreen : _textSecondary.withOpacity(0.5)),
          if (widget.prefixIcon != null) const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              style: const TextStyle(fontSize: 14, color: _textPrimary, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(color: _textSecondary.withOpacity(0.3), fontWeight: FontWeight.normal),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Main Dialog ---

class AddShoppingItemDialog extends StatefulWidget {
  final Function(String name, String amount) onAdd;

  const AddShoppingItemDialog({super.key, required this.onAdd});

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadIngredients() async {
    try {
      final ingredients = await _ingredientService.getIngredients();
      if (mounted) {
        setState(() {
          _allIngredients = ingredients;
          _filteredIngredients = ingredients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filter(String q) {
    setState(() {
      _filteredIngredients = _allIngredients.where((i) => i.name.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  void _showAmountInput(String name) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('添加 $name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
              const SizedBox(height: 20),
              MinimalInput(controller: amountController, hintText: "预计数量 (如: 2个, 500g)", autofocus: true),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("取消", style: TextStyle(color: _textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onAdd(name, amountController.text);
                        Navigator.pop(context); // Close amount
                        Navigator.pop(context); // Close main add
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _sageGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("确认"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                children: [
                  const Text('找点食材', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textPrimary)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close_rounded, color: _textSecondary), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            
            // Search Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: MinimalInput(
                controller: _searchController,
                hintText: "搜索食材库...",
                prefixIcon: Icons.search_rounded,
                onChanged: _filter,
              ),
            ),
            const SizedBox(height: 16),

            // Results List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _sageGreen))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _filteredIngredients.length + (_searchController.text.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_searchController.text.isNotEmpty && index == 0) {
                          return _buildActionTile("直接添加 \"${_searchController.text}\"", "作为新食材添加", Icons.add_rounded, () {
                            _showAmountInput(_searchController.text);
                          });
                        }
                        final item = _filteredIngredients[_searchController.text.isNotEmpty ? index - 1 : index];
                        return _buildIngredientTile(item);
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, String sub, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BouncyCard(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _sageGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(icon, color: _sageGreen, size: 20)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textPrimary)),
                    Text(sub, style: const TextStyle(color: _textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientTile(IngredientItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BouncyCard(
        onTap: () => _showAmountInput(item.name),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _oatmeal.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Text(item.icon.isNotEmpty ? item.icon : (item.name.isNotEmpty ? item.name[0] : '📦'), style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textPrimary)),
                    Text(item.categoryName, style: const TextStyle(color: _textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.add_rounded, color: _sageGreen, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}