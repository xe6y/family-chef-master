import 'package:flutter/material.dart';

/// 标签选择器组件
///
/// 用于多选标签的场景，如口味偏好、食材选择等
class TagSelector extends StatelessWidget {
  /// 标题
  final String title;

  /// 可选标签列表
  final List<String> availableTags;

  /// 已选中的标签
  final List<String> selectedTags;

  /// 标签选择变化回调
  final ValueChanged<List<String>> onChanged;

  /// 是否允许自定义标签
  final bool allowCustom;

  /// 自定义标签提示文本
  final String? customHint;

  /// 最大选择数量（null 表示不限制）
  final int? maxSelection;

  const TagSelector({
    super.key,
    required this.title,
    required this.availableTags,
    required this.selectedTags,
    required this.onChanged,
    this.allowCustom = false,
    this.customHint,
    this.maxSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3648),
            ),
          ),
        ),

        // 标签网格
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 预设标签
            ...availableTags.map((tag) => _buildTag(
                  context,
                  tag,
                  isSelected: selectedTags.contains(tag),
                  onTap: () => _toggleTag(tag),
                )),

            // 自定义标签按钮
            if (allowCustom)
              _buildAddCustomTag(context),
          ],
        ),

        // 选择数量提示
        if (maxSelection != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '已选择 ${selectedTags.length}/$maxSelection',
              style: TextStyle(
                fontSize: 12,
                color: selectedTags.length >= maxSelection!
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFF8F9BB3),
              ),
            ),
          ),
      ],
    );
  }

  /// 构建单个标签
  Widget _buildTag(
    BuildContext context,
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4CAF50)
                : const Color(0xFFE4E9F2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF2D3648),
          ),
        ),
      ),
    );
  }

  /// 构建添加自定义标签按钮
  Widget _buildAddCustomTag(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCustomTagDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4CAF50),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 16,
              color: Color(0xFF4CAF50),
            ),
            SizedBox(width: 4),
            Text(
              '自定义',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 切换标签选中状态
  void _toggleTag(String tag) {
    final newSelection = List<String>.from(selectedTags);

    if (newSelection.contains(tag)) {
      newSelection.remove(tag);
    } else {
      // 检查是否超过最大选择数量
      if (maxSelection != null && newSelection.length >= maxSelection!) {
        return;
      }
      newSelection.add(tag);
    }

    onChanged(newSelection);
  }

  /// 显示自定义标签对话框
  void _showCustomTagDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加自定义标签'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: customHint ?? '请输入标签名称',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty && !selectedTags.contains(tag)) {
                _toggleTag(tag);
              }
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
