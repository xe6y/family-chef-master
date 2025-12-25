import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'icon': Icons.home, 'label': '首页'},
      {'icon': Icons.menu_book, 'label': '菜谱'},
      {'icon': Icons.restaurant, 'label': '点餐'},
      {'icon': Icons.inventory_2, 'label': '食材'},
      {'icon': Icons.shopping_cart, 'label': '购物'},
    ];

    return Container(
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
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              navItems.length,
              (index) => Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        navItems[index]['icon'] as IconData,
                        size: 24,
                        color: currentIndex == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        navItems[index]['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: currentIndex == index
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: currentIndex == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
