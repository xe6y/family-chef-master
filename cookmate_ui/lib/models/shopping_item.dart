/// 购物项模型
class ShoppingItem {
  /// 购物项ID
  final String id;

  /// 食材ID（关联到 IngredientMaster）
  final String ingredientId;

  /// 食材名称
  final String ingredientName;

  /// 预计购买数量
  final double quantity;

  /// 单位ID
  final String unitId;

  /// 单位名称
  final String unitName;

  /// 实际购买数量
  final double? actualQuantity;

  /// 价格
  final double price;

  /// 是否已购买
  final bool checked;

  ShoppingItem({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.unitId,
    required this.unitName,
    this.actualQuantity,
    this.price = 0.0,
    this.checked = false,
  });

  /// 从JSON创建ShoppingItem实例
  /// json: JSON数据
  /// 返回: ShoppingItem实例
  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id']?.toString() ?? '',
      ingredientId: json['ingredientId'] ?? '',
      ingredientName: json['ingredientName'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitId: json['unitId'] ?? '',
      unitName: json['unitName'] ?? '',
      actualQuantity: json['actualQuantity'] != null
          ? (json['actualQuantity'] as num).toDouble()
          : null,
      price: (json['price'] ?? 0).toDouble(),
      checked: json['checked'] ?? false,
    );
  }

  /// 转换为JSON
  /// 返回: JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ingredientId': ingredientId,
      'ingredientName': ingredientName,
      'quantity': quantity,
      'unitId': unitId,
      'unitName': unitName,
      'actualQuantity': actualQuantity,
      'price': price,
      'checked': checked,
    };
  }

  /// 复制并修改
  ShoppingItem copyWith({
    String? id,
    String? ingredientId,
    String? ingredientName,
    double? quantity,
    String? unitId,
    String? unitName,
    double? actualQuantity,
    double? price,
    bool? checked,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      ingredientId: ingredientId ?? this.ingredientId,
      ingredientName: ingredientName ?? this.ingredientName,
      quantity: quantity ?? this.quantity,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      price: price ?? this.price,
      checked: checked ?? this.checked,
    );
  }

  /// 获取显示用的数量字符串
  String get displayAmount => '$quantity$unitName';
}

/// 购物清单模型
class ShoppingList {
  /// 清单ID
  final String id;

  /// 清单名称
  final String name;

  /// 购物项列表
  final List<ShoppingItem> items;

  /// 总价
  final double totalPrice;

  /// 创建时间
  final String? createdAt;

  /// 完成时间
  final String? completedAt;

  /// 家庭ID
  final String? familyId;

  ShoppingList({
    required this.id,
    required this.name,
    required this.items,
    required this.totalPrice,
    this.createdAt,
    this.completedAt,
    this.familyId,
  });

  /// 从JSON创建ShoppingList实例
  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '购物清单',
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => ShoppingItem.fromJson(e))
              .toList()
          : [],
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      createdAt: json['createdAt'],
      completedAt: json['completedAt'],
      familyId: json['familyId'],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((e) => e.toJson()).toList(),
      'totalPrice': totalPrice,
      'familyId': familyId,
    };
  }

  /// 是否已完成
  bool get isCompleted => completedAt != null;
}
