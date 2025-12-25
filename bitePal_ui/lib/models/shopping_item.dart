class ShoppingItem {
  final int id;
  final String name;
  final String amount;
  final double price;
  final bool checked;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.price,
    this.checked = false,
  });

  ShoppingItem copyWith({
    int? id,
    String? name,
    String? amount,
    double? price,
    bool? checked,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      price: price ?? this.price,
      checked: checked ?? this.checked,
    );
  }
}
