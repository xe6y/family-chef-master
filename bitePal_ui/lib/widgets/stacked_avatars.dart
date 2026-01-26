import 'package:flutter/material.dart';
import '../models/user.dart';

/// 堆叠头像组件
/// 显示多个家庭成员的头像，堆叠排列
class StackedAvatars extends StatelessWidget {
  /// 家庭成员列表
  final List<FamilyMember> members;

  /// 头像大小
  final double size;

  /// 最多显示数量
  final int maxDisplay;

  /// 堆叠偏移量
  final double overlap;

  const StackedAvatars({
    super.key,
    required this.members,
    this.size = 32,
    this.maxDisplay = 3,
    this.overlap = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    final displayMembers = members.take(maxDisplay).toList();
    final remainingCount = members.length - displayMembers.length;

    return SizedBox(
      width: size + (displayMembers.length - 1) * overlap +
             (remainingCount > 0 ? overlap : 0),
      height: size,
      child: Stack(
        children: [
          // 显示头像
          ...List.generate(displayMembers.length, (index) {
            return Positioned(
              left: index * overlap,
              child: _buildAvatar(
                displayMembers[index],
                size,
              ),
            );
          }),
          // 显示剩余数量
          if (remainingCount > 0)
            Positioned(
              left: displayMembers.length * overlap,
              child: _buildCountBadge(remainingCount, size),
            ),
        ],
      ),
    );
  }

  /// 构建单个头像
  Widget _buildAvatar(FamilyMember member, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: _getColorForName(member.name),
        child: Text(
          _getInitial(member.name),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 构建数量角标
  Widget _buildCountBadge(int count, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFB2AC88),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '+$count',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 根据名字获取首字母
  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  /// 根据名字生成颜色
  Color _getColorForName(String name) {
    final colors = [
      const Color(0xFF7B9E89), // 深绿
      const Color(0xFFE8956F), // 橙色
      const Color(0xFF6B9BD1), // 蓝色
      const Color(0xFFD97BA6), // 粉色
      const Color(0xFF9B8DC7), // 紫色
      const Color(0xFFE5A85B), // 黄色
    ];

    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }
}
