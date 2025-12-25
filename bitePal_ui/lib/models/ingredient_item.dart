class IngredientItem {
  final int id;
  final String name;
  final String amount;
  final String category; // room, fridge, freezer
  final String icon;
  final int expiryDays;
  final String expiryText;
  final bool urgent;

  IngredientItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.icon,
    required this.expiryDays,
    required this.expiryText,
    this.urgent = false,
  });

  IngredientItem copyWith({
    int? id,
    String? name,
    String? amount,
    String? category,
    String? icon,
    int? expiryDays,
    String? expiryText,
    bool? urgent,
  }) {
    return IngredientItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      expiryDays: expiryDays ?? this.expiryDays,
      expiryText: expiryText ?? this.expiryText,
      urgent: urgent ?? this.urgent,
    );
  }
}
