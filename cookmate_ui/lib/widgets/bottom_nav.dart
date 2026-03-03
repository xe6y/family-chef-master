import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// 底部导航栏 - iOS 风格
class BottomNav extends StatelessWidget {
  /// 当前选中的索引
  final int currentIndex;

  /// 点击回调
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      _NavItem(icon: CupertinoIcons.house, activeIcon: CupertinoIcons.house_fill, label: '首页'),
      _NavItem(icon: CupertinoIcons.book, activeIcon: CupertinoIcons.book_fill, label: '菜谱'),
      _NavItem(icon: CupertinoIcons.square_list, activeIcon: CupertinoIcons.square_list_fill, label: '点餐'),
      _NavItem(icon: CupertinoIcons.cube_box, activeIcon: CupertinoIcons.cube_box_fill, label: '食材'),
      _NavItem(icon: CupertinoIcons.bag, activeIcon: CupertinoIcons.bag_fill, label: '购物'),
    ];

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          child: Row(
            children: List.generate(
              navItems.length,
              (index) => _buildNavItem(
                context,
                navItems[index],
                index,
                index == currentIndex,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建导航项 - iOS 风格
  Widget _buildNavItem(
    BuildContext context,
    _NavItem item,
    int index,
    bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 24,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 导航项数据
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
