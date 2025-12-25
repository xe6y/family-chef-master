import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String _activeTab = "my";
  bool _filterExpanded = false;
  final List<String> _selectedTastes = [];
  final List<String> _selectedDifficulty = [];
  final List<String> _selectedCuisines = [];

  final List<Recipe> _myRecipes = [
    Recipe(
      id: 1,
      name: "番茄炒蛋",
      time: "15分钟",
      difficulty: "简单",
      tags: ["常做"],
      tagColors: ["bg-blue-500"],
      favorite: true,
      categories: ["家常菜", "酸甜"],
    ),
    Recipe(
      id: 4,
      name: "红烧肉",
      image: "/images/image.png",
      time: "45分钟",
      difficulty: "中等",
      tags: ["常做"],
      tagColors: ["bg-blue-500", "bg-pink-500"],
      favorite: false,
      categories: ["川菜", "咸鲜"],
    ),
    Recipe(
      id: 3,
      name: "清蒸鲈鱼",
      image: "/images/image.png",
      time: "25分钟",
      difficulty: "简单",
      tags: ["常做"],
      tagColors: ["bg-blue-500"],
      favorite: true,
      categories: ["粤菜", "清淡"],
    ),
    Recipe(
      id: 6,
      name: "酸辣土豆丝",
      time: "10分钟",
      difficulty: "简单",
      tags: ["常做"],
      tagColors: ["bg-blue-500", "bg-pink-500"],
      favorite: true,
      categories: ["家常菜", "酸辣"],
    ),
  ];

  final List<Recipe> _onlineRecipes = [
    Recipe(
      id: 101,
      name: "宫保鸡丁",
      image: "/images/image.png",
      time: "30分钟",
      difficulty: "中等",
      tags: ["热门", "川菜"],
      tagColors: ["bg-red-500", "bg-orange-500"],
      favorite: false,
      categories: ["川菜", "麻辣"],
    ),
    Recipe(
      id: 102,
      name: "糖醋里脊",
      image: "/images/image.png",
      time: "25分钟",
      difficulty: "中等",
      tags: ["热门", "酸甜"],
      tagColors: ["bg-red-500", "bg-yellow-500"],
      favorite: false,
      categories: ["鲁菜", "酸甜"],
    ),
    Recipe(
      id: 103,
      name: "麻婆豆腐",
      image: "/images/image.png",
      time: "20分钟",
      difficulty: "简单",
      tags: ["素食", "下饭"],
      tagColors: ["bg-green-500", "bg-blue-500"],
      favorite: false,
      categories: ["川菜", "麻辣"],
    ),
    Recipe(
      id: 104,
      name: "鱼香肉丝",
      image: "/images/image.png",
      time: "25分钟",
      difficulty: "中等",
      tags: ["经典", "下饭"],
      tagColors: ["bg-purple-500", "bg-blue-500"],
      favorite: false,
      categories: ["川菜", "酸甜"],
    ),
    Recipe(
      id: 105,
      name: "白切鸡",
      image: "/images/image.png",
      time: "40分钟",
      difficulty: "简单",
      tags: ["粤菜", "清淡"],
      tagColors: ["bg-cyan-500", "bg-green-500"],
      favorite: false,
      categories: ["粤菜", "清淡"],
    ),
    Recipe(
      id: 106,
      name: "回锅肉",
      image: "/images/image.png",
      time: "30分钟",
      difficulty: "中等",
      tags: ["经典", "下饭"],
      tagColors: ["bg-orange-500", "bg-blue-500"],
      favorite: false,
      categories: ["川菜", "咸鲜"],
    ),
  ];

  List<Recipe> get _currentRecipes {
    return _activeTab == "my" ? _myRecipes : _onlineRecipes;
  }

  @override
  Widget build(BuildContext context) {
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
                    "菜谱",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  // Tabs
                  Row(
                    children: [
                      Expanded(
                        child: _buildTabButton("我的菜谱", _activeTab == "my", () {
                          setState(() => _activeTab = "my");
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTabButton(
                          "网络菜谱",
                          _activeTab == "online",
                          () {
                            setState(() => _activeTab = "online");
                          },
                          enabled: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search and Filter
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "搜索菜谱...",
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune, color: Colors.white),
                          onPressed: () {
                            setState(() => _filterExpanded = !_filterExpanded);
                          },
                        ),
                      ),
                    ],
                  ),
                  // Filter Panel
                  if (_filterExpanded) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterSection(
                              "口味",
                              ["清淡", "咸鲜", "酸甜", "麻辣", "酸辣"],
                              _selectedTastes,
                              (taste) {
                                setState(() {
                                  if (_selectedTastes.contains(taste)) {
                                    _selectedTastes.remove(taste);
                                  } else {
                                    _selectedTastes.add(taste);
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildFilterSection(
                              "难度",
                              ["简单", "中等", "困难"],
                              _selectedDifficulty,
                              (difficulty) {
                                setState(() {
                                  if (_selectedDifficulty.contains(
                                    difficulty,
                                  )) {
                                    _selectedDifficulty.remove(difficulty);
                                  } else {
                                    _selectedDifficulty.add(difficulty);
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildFilterSection(
                              "菜系",
                              ["家常菜", "川菜", "粤菜", "浙菜", "湘菜"],
                              _selectedCuisines,
                              (cuisine) {
                                setState(() {
                                  if (_selectedCuisines.contains(cuisine)) {
                                    _selectedCuisines.remove(cuisine);
                                  } else {
                                    _selectedCuisines.add(cuisine);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Recipe Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _currentRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _currentRecipes[index];
                    return RecipeCard(
                      recipe: recipe,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailScreen(
                              recipeId: recipe.id,
                              isFromMyRecipes: _activeTab == "my",
                            ),
                          ),
                        );
                      },
                      onFavorite: () {
                        setState(() {
                          // Toggle favorite
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "recipes_fab",
        onPressed: () {
          // Add recipe
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabButton(
    String label,
    bool isActive,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: isActive
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    List<String> selected,
    Function(String) onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (value) => onToggle(option),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(color: isSelected ? Colors.white : null),
            );
          }).toList(),
        ),
      ],
    );
  }
}
