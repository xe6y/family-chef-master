import 'package:flutter/material.dart';
import '../services/ingredient_check_service.dart';

class IngredientCheckScreen extends StatefulWidget {
  const IngredientCheckScreen({super.key});

  @override
  State<IngredientCheckScreen> createState() => _IngredientCheckScreenState();
}

class _IngredientCheckScreenState extends State<IngredientCheckScreen> {
  final IngredientCheckService _checkService = IngredientCheckService();
  IngredientCheckResult? _checkResult;
  bool _isLoading = true;

  static const Color _sageGreen = Color(0xFFB2AC88);
  static const Color _oatmeal = Color(0xFFF5F5F0);
  static const Color _textPrimary = Color(0xFF4A4F50);
  static const Color _textSecondary = Color(0xFF8C8F90);

  @override
  void initState() {
    super.initState();
    _loadCheckResult();
  }

  Future<void> _loadCheckResult() async {
    setState(() => _isLoading = true);
    try {
      final result = await _checkService.checkTodayMenuIngredients();
      if (mounted) {
        setState(() {
          _checkResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _oatmeal,
      appBar: AppBar(
        title: const Text('食材需求检查'),
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _sageGreen),
            )
          : _checkResult == null
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.kitchen_outlined,
            size: 64,
            color: _textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无今日菜单',
            style: TextStyle(
              fontSize: 16,
              color: _textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请先添加今日菜单',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final insufficient = _checkResult!.insufficientIngredients;
    final sufficient = _checkResult!.sufficientIngredients;

    return CustomScrollView(
      slivers: [
        // 状态卡片
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStatusCard(),
          ),
        ),

        // 不足的食材
        if (insufficient.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '食材不足',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${insufficient.length})',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildIngredientItem(insufficient[index], true);
                },
                childCount: insufficient.length,
              ),
            ),
          ),
        ],

        // 充足的食材
        if (sufficient.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _sageGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '食材充足',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${sufficient.length})',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildIngredientItem(sufficient[index], false);
                },
                childCount: sufficient.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusCard() {
    final allSufficient = _checkResult!.allSufficient;
    final insufficientCount = _checkResult!.insufficientIngredients.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: allSufficient
            ? _sageGreen.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allSufficient
              ? _sageGreen.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: allSufficient ? _sageGreen : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              allSufficient ? Icons.check_circle : Icons.warning,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allSufficient ? '食材充足' : '食材不足',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: allSufficient ? _sageGreen : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  allSufficient
                      ? '所有食材都已准备充足'
                      : '有 $insufficientCount 种食材需要补充',
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(IngredientRequirement item, bool isInsufficient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInsufficient
              ? Colors.red.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.ingredientName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isInsufficient ? Colors.red : _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '需要: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                    Text(
                      '${item.requiredAmount} ${item.unit}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '现有: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                    Text(
                      '${item.availableAmount} ${item.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isInsufficient ? Colors.red : _sageGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isInsufficient)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '缺 ${item.missingAmount.toStringAsFixed(1)} ${item.unit}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
