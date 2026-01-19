import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/shopping_item.dart';
import '../services/shopping_service.dart';
import '../widgets/refreshable_screen.dart';

// --- Theme Constants ---
const Color _oatmeal = Color(0xFFF5F5F0);
const Color _sageGreen = Color(0xFFB2AC88);
const Color _persimmon = Color(0xFFE58A73);
const Color _textPrimary = Color(0xFF4A4F50);
const Color _textSecondary = Color(0xFF8C8F90);

class ShoppingHistoryScreen extends RefreshableScreen {
  const ShoppingHistoryScreen({super.key});

  @override
  State<ShoppingHistoryScreen> createState() => _ShoppingHistoryScreenState();
}

class _ShoppingHistoryScreenState extends State<ShoppingHistoryScreen> with RefreshableScreenState<ShoppingHistoryScreen> {
  final ShoppingService _shoppingService = ShoppingService();
  List<ShoppingListHistory> _historyLists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  Future<void> refresh() async {
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final pagedData = await _shoppingService.getShoppingHistory();
      if (pagedData != null) {
        setState(() {
          _historyLists = pagedData.list;
        });
      }
    } catch (e) {
      debugPrint('加载历史失败: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _oatmeal,
      appBar: AppBar(
        backgroundColor: _oatmeal,
        elevation: 0,
        centerTitle: true,
        title: const Text('购物账本', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _textPrimary)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPrimary, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _sageGreen))
          : _historyLists.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historyLists.length,
                  itemBuilder: (context, index) => _HistoryExpandableCard(
                    history: _historyLists[index],
                    service: _shoppingService,
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_rounded, size: 64, color: _textSecondary.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text("尚无结案记录", style: TextStyle(color: _textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}

class _HistoryExpandableCard extends StatefulWidget {
  final ShoppingListHistory history;
  final ShoppingService service;

  const _HistoryExpandableCard({required this.history, required this.service});

  @override
  State<_HistoryExpandableCard> createState() => _HistoryExpandableCardState();
}

class _HistoryExpandableCardState extends State<_HistoryExpandableCard> {
  bool _isExpanded = false;
  List<ShoppingItem>? _details;
  bool _isLoadingDetails = false;

  Future<void> _toggleExpand() async {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded && _details == null) {
      setState(() => _isLoadingDetails = true);
      try {
        final fullList = await widget.service.getShoppingListDetail(widget.history.id);
        if (fullList != null) {
          setState(() {
            _details = fullList.items;
          });
        }
      } catch (e) {
        debugPrint('加载详情失败: $e');
      }
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.history.completedAt != null 
        ? DateTime.tryParse(widget.history.completedAt!)?.toLocal() 
        : null;
    final dateStr = date != null ? "${date.month}月${date.day}日" : "未知日期";
    final yearStr = date != null ? "${date.year}年" : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header (Compact View)
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(yearStr, style: const TextStyle(fontSize: 10, color: _textSecondary)),
                          Text(dateStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("支出共计", style: TextStyle(fontSize: 10, color: _textSecondary)),
                          Text("¥${widget.history.totalPrice.toStringAsFixed(2)}", 
                            style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: _sageGreen)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "包含 ${widget.history.itemCount} 项物品", 
                          style: const TextStyle(fontSize: 12, color: _textSecondary)
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.expand_more_rounded, color: Colors.grey, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded Content
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildDetails(),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    if (_isLoadingDetails) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _sageGreen))),
      );
    }

    if (_details == null || _details!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Center(child: Text("暂无详细项", style: TextStyle(fontSize: 12, color: _textSecondary))),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          ..._details!.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 6, color: _sageGreen),
                const SizedBox(width: 12),
                Expanded(child: Text(item.name, style: const TextStyle(fontSize: 14, color: _textPrimary))),
                Text("¥${item.price.toStringAsFixed(2)}", 
                  style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
