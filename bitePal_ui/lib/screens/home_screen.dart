import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/ingredient_item.dart';
import '../widgets/recipe_card.dart';
import '../widgets/random_meal_dialog.dart';
import 'recipe_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Recipe> _todayRecipes = [
    Recipe(
      id: 1,
      name: "番茄炒蛋",
      time: "15 分钟",
      difficulty: "简单",
      tags: ["常做"],
      tagColors: ["bg-blue-500"],
      favorite: false,
      categories: ["家常菜", "酸甜"],
    ),
    Recipe(
      id: 4,
      name: "红烧肉",
      time: "45 分钟",
      difficulty: "中等",
      tags: ["常做"],
      tagColors: ["bg-blue-500"],
      favorite: false,
      categories: ["川菜", "咸鲜"],
    ),
  ];

  final List<IngredientItem> _expiringIngredients = [
    IngredientItem(
      id: 1,
      name: "生菜",
      amount: "1颗",
      category: "fridge",
      icon: "🥬",
      expiryDays: 0,
      expiryText: "今天",
      urgent: true,
    ),
    IngredientItem(
      id: 2,
      name: "培根",
      amount: "200g",
      category: "fridge",
      icon: "🥓",
      expiryDays: 1,
      expiryText: "明天",
      urgent: false,
    ),
    IngredientItem(
      id: 3,
      name: "牛奶",
      amount: "500ml",
      category: "fridge",
      icon: "🥛",
      expiryDays: 3,
      expiryText: "3天后",
      urgent: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "做伴",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "你的做饭伴侣",
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFB84D), Color(0xFFFF6B35)],
                          ),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.asset(
                            'assets/cartoon-avatar.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 32,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Today's Menu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "今日菜单",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _todayRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _todayRecipes[index];
                          return Container(
                            width: 256,
                            margin: EdgeInsets.only(
                              right: index < _todayRecipes.length - 1 ? 16 : 0,
                            ),
                            child: RecipeCard(
                              recipe: recipe,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RecipeDetailScreen(recipeId: recipe.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Ingredient Alert
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade500,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "3 种食材即将过期",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "建议优先使用：生菜、培根、牛奶",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  // Navigate to ingredients
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "查看详情",
                                      style: TextStyle(
                                        color: Colors.amber.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: Colors.amber.shade700,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Expiring Soon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "即将过期",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to ingredients
                          },
                          child: const Text("查看全部"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: _expiringIngredients.map((ingredient) {
                          return ListTile(
                            leading: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: ingredient.urgent
                                    ? Colors.red
                                    : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(ingredient.name),
                            subtitle: Text(ingredient.amount),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: ingredient.urgent
                                    ? Colors.red.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                ingredient.expiryText,
                                style: TextStyle(
                                  color: ingredient.urgent
                                      ? Colors.red.shade700
                                      : Colors.orange.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Action
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const RandomMealDialog(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("随便吃点", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),

              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}
