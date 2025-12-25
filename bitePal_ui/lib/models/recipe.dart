class Recipe {
  final int id;
  final String name;
  final String? image;
  final String time;
  final String difficulty;
  final List<String> tags;
  final List<String> tagColors;
  final bool favorite;
  final List<String> categories;
  final List<Ingredient>? ingredients;
  final List<String>? steps;

  Recipe({
    required this.id,
    required this.name,
    this.image,
    required this.time,
    required this.difficulty,
    required this.tags,
    required this.tagColors,
    this.favorite = false,
    required this.categories,
    this.ingredients,
    this.steps,
  });

  Recipe copyWith({
    int? id,
    String? name,
    String? image,
    String? time,
    String? difficulty,
    List<String>? tags,
    List<String>? tagColors,
    bool? favorite,
    List<String>? categories,
    List<Ingredient>? ingredients,
    List<String>? steps,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      time: time ?? this.time,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      tagColors: tagColors ?? this.tagColors,
      favorite: favorite ?? this.favorite,
      categories: categories ?? this.categories,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
    );
  }
}

class Ingredient {
  final String name;
  final String amount;
  final bool available;

  Ingredient({required this.name, required this.amount, this.available = true});
}
