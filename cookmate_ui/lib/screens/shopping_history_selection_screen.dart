import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../services/shopping_service.dart';
import '../widgets/refreshable_screen.dart';

/// 购物历史选择页面
class ShoppingHistorySelectionScreen extends RefreshableScreen {
  const ShoppingHistorySelectionScreen({super.key});

  @override
  State<ShoppingHistorySelectionScreen> createState() => _ShoppingHistorySelectionScreenState();
}

class _ShoppingHistorySelectionScreenState extends State<ShoppingHistorySelectionScreen> with RefreshableScreenState<ShoppingHistorySelectionScreen> {
  final ShoppingService _shoppingService = ShoppingService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ShoppingItem> _items = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Future<void> refresh() async {
    _page = 1;
    await _loadItems();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final data = await _shoppingService.getShoppingHistoryItems(
        page: _page,
        search: _searchController.text,
      );
      if (data != null) {
        setState(() {
          _items = data.list;
          _hasMore = data.list.length >= 20; // 假设每页20
        });
      }
    } catch (e) {
      debugPrint('加载历史失败: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final nextPage = _page + 1;
      final data = await _shoppingService.getShoppingHistoryItems(
        page: nextPage,
        search: _searchController.text,
      );
      if (data != null) {
        setState(() {
          _items.addAll(data.list);
          _page = nextPage;
          _hasMore = data.list.length >= 20;
        });
      }
    } catch (e) {
      debugPrint('加载更多失败: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _onSearch() {
    _page = 1;
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('从历史购物选择'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索历史商品...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _onSearch,
                ),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          Expanded(
            child: _items.isEmpty && !_isLoading
                ? const Center(child: Text('没有找到相关商品'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _items.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                      }
                      final item = _items[index];
                      return ListTile(
                        title: Text(item.ingredientName),
                        subtitle: Text(item.displayAmount),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context, item);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
