import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/meal_order.dart';
import '../services/meal_service.dart';

class OrderSummaryScreen extends StatefulWidget {
  final List<Recipe> selectedRecipes;

  const OrderSummaryScreen({
    super.key,
    required this.selectedRecipes,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final MealService _mealService = MealService();
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 如果有已选菜谱，传递 recipeIds 用于统计食材
      final recipeIds = widget.selectedRecipes.isNotEmpty
          ? widget.selectedRecipes.map((r) => r.id).join(',')
          : null;

      final summary = await _mealService.getOrderSummary(recipeIds: recipeIds);

      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('订单统计'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载失败: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSummary,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_summary == null) {
      return const Center(child: Text('暂无数据'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelectedRecipesSection(),
          const SizedBox(height: 16),
          if (_summary!['hasTodayMenu'] == true) ...[
            _buildTodayMenuSection(),
            const SizedBox(height: 16),
          ],
          _buildIngredientsSection(),
          const SizedBox(height: 24),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildSelectedRecipesSection() {
    final recipes = (_summary!['selectedRecipes'] as List<dynamic>?) ?? [];
    final totalCount = (_summary!['totalCount'] as int?) ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant_menu, size: 20),
                const SizedBox(width: 8),
                Text(
                  '已选菜品',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '共 $totalCount 道',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey[300]),
            ...recipes.map((recipe) {
              final name = recipe['name'] ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(name)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayMenuSection() {
    final recipes = (_summary!['todayRecipes'] as List<dynamic>?) ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '今日已生成菜单',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '共 ${recipes.length} 道',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey[300]),
            ...recipes.map((recipe) {
              final name = recipe['name'] ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(name)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    final ingredients = (_summary!['ingredients'] as List<dynamic>?) ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_basket, size: 20),
                const SizedBox(width: 8),
                Text(
                  '所需食材',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '共 ${ingredients.length} 种',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey[300]),
            ...ingredients.map((ingredient) {
              final name = ingredient['name'] ?? '';
              final amount = ingredient['amount'] ?? '';
              final available = ingredient['available'] ?? false;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      available ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 20,
                      color: available ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          decoration: available ? TextDecoration.lineThrough : null,
                          color: available ? Colors.grey : null,
                        ),
                      ),
                    ),
                    Text(
                      amount,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _confirmOrder,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '确认生成菜单',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _confirmOrder() async {
    try {
      // 构建订单菜品列表
      final orderRecipes = widget.selectedRecipes
          .map((r) => OrderRecipe(recipeId: r.id, recipeName: r.name))
          .toList();

      // 调用创建订单接口
      final order = await _mealService.createMealOrder(orderRecipes);

      if (order != null && mounted) {
        // 创建成功，返回上一页
        Navigator.pop(context, true);
      } else if (mounted) {
        // 创建失败
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('创建订单失败，请重试')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建订单失败: $e')),
        );
      }
    }
  }
}
