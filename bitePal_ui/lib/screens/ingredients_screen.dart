import 'package:flutter/material.dart';
import '../models/ingredient_item.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  String _activeCategory = "room";

  final Map<String, List<IngredientItem>> _ingredientsByCategory = {
    "room": [
      IngredientItem(
        id: 1,
        name: "西红柿",
        amount: "2个",
        category: "room",
        icon: "🍅",
        expiryDays: 3,
        expiryText: "3天后过期",
      ),
      IngredientItem(
        id: 2,
        name: "土豆",
        amount: "5kg",
        category: "room",
        icon: "🥔",
        expiryDays: 14,
        expiryText: "14天后过期",
      ),
    ],
    "fridge": [
      IngredientItem(
        id: 3,
        name: "生菜",
        amount: "1颗",
        category: "fridge",
        icon: "🥬",
        expiryDays: 0,
        expiryText: "今天过期",
        urgent: true,
      ),
    ],
    "freezer": [],
  };

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'id': 'room', 'label': '常温'},
      {'id': 'fridge', 'label': '冷藏'},
      {'id': 'freezer', 'label': '冷冻'},
    ];

    final currentIngredients = _ingredientsByCategory[_activeCategory] ?? [];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "食材库存",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  // Category Tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: categories.map((category) {
                        final isActive = _activeCategory == category['id'];
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(
                                () =>
                                    _activeCategory = category['id'] as String,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Theme.of(context).cardColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                category['label'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isActive
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "蔬菜水果",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // Ingredients List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: currentIngredients.length,
                itemBuilder: (context, index) {
                  final ingredient = currentIngredients[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            ingredient.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      title: Text(
                        ingredient.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(ingredient.amount),
                      trailing: Text(
                        ingredient.expiryText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ingredient.urgent
                              ? Colors.red.shade600
                              : ingredient.expiryDays <= 3
                              ? Colors.orange.shade600
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "ingredients_fab",
        onPressed: () {
          // Add ingredient
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
