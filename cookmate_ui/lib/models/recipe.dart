/// 菜谱模型
class Recipe {
  /// 菜谱ID
  final String id;

  /// 菜谱名称
  final String name;

  /// 图片URL
  final String? image;

  /// 制作时间
  final String time;

  /// 难度（有手就行/家常便饭/餐厅招牌/硬核挑战/专业厨师）
  final String difficulty;

  /// 难度颜色（从数据库读取）
  final String? difficultyColor;

  /// 标签数组
  final List<String> tags;

  /// 标签颜色数组
  final List<String> tagColors;

  /// 是否收藏
  final bool favorite;

  /// 分类数组
  final List<String> categories;

  /// 食材列表（详情接口会带 name/amountDisplay/status）
  final List<Ingredient>? ingredients;

  /// 总热量/营养（详情接口返回）
  final double? caloriesTotal;
  final double? proteinTotal;
  final double? fatTotal;
  final double? carbTotal;

  /// 制作步骤
  final List<String>? steps;

  /// 创建用户ID
  final String? userId;

  /// 是否公开
  final bool? isPublic;

  Recipe({
    required this.id,
    required this.name,
    this.image,
    required this.time,
    required this.difficulty,
    this.difficultyColor,
    required this.tags,
    required this.tagColors,
    this.favorite = false,
    required this.categories,
    this.ingredients,
    this.steps,
    this.userId,
    this.isPublic,
    this.caloriesTotal,
    this.proteinTotal,
    this.fatTotal,
    this.carbTotal,
  });

  /// 从JSON创建Recipe实例
  /// json: JSON数据
  /// 返回: Recipe实例
  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<Ingredient>? ingredients;
    if (json['ingredientsDisplay'] != null) {
      ingredients = (json['ingredientsDisplay'] as List)
          .map((e) => Ingredient.fromJson(e))
          .toList();
    } else if (json['ingredients'] != null) {
      ingredients = (json['ingredients'] as List)
          .map((e) => Ingredient.fromJson(e))
          .toList();
    }
    return Recipe(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      time: json['time'] ?? '',
      difficulty: json['difficulty'] ?? '有手就行',
      difficultyColor: json['difficultyColor'],
      tags: List<String>.from(json['tags'] ?? []),
      tagColors: List<String>.from(json['tagColors'] ?? []),
      favorite: json['favorite'] ?? false,
      categories: List<String>.from(json['categories'] ?? []),
      ingredients: ingredients,
      steps: json['steps'] != null ? List<String>.from(json['steps']) : null,
      userId: json['userId'],
      isPublic: json['isPublic'],
      caloriesTotal: _toDouble(json['caloriesTotal'] ?? json['calories_total']),
      proteinTotal: _toDouble(json['proteinTotal'] ?? json['protein_total']),
      fatTotal: _toDouble(json['fatTotal'] ?? json['fat_total']),
      carbTotal: _toDouble(json['carbTotal'] ?? json['carb_total']),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return null;
  }

  /// 转换为JSON
  /// 返回: JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'time': time,
      'difficulty': difficulty,
      'difficultyColor': difficultyColor,
      'tags': tags,
      'tagColors': tagColors,
      'favorite': favorite,
      'categories': categories,
      'ingredients': ingredients?.map((e) => e.toJson()).toList(),
      'steps': steps,
      'isPublic': isPublic,
      'caloriesTotal': caloriesTotal,
      'proteinTotal': proteinTotal,
      'fatTotal': fatTotal,
      'carbTotal': carbTotal,
    };
  }

  /// 复制并修改
  Recipe copyWith({
    String? id,
    String? name,
    String? image,
    String? time,
    String? difficulty,
    String? difficultyColor,
    List<String>? tags,
    List<String>? tagColors,
    bool? favorite,
    List<String>? categories,
    List<Ingredient>? ingredients,
    List<String>? steps,
    String? userId,
    bool? isPublic,
    double? caloriesTotal,
    double? proteinTotal,
    double? fatTotal,
    double? carbTotal,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      time: time ?? this.time,
      difficulty: difficulty ?? this.difficulty,
      difficultyColor: difficultyColor ?? this.difficultyColor,
      tags: tags ?? this.tags,
      tagColors: tagColors ?? this.tagColors,
      favorite: favorite ?? this.favorite,
      categories: categories ?? this.categories,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      userId: userId ?? this.userId,
      isPublic: isPublic ?? this.isPublic,
      caloriesTotal: caloriesTotal ?? this.caloriesTotal,
      proteinTotal: proteinTotal ?? this.proteinTotal,
      fatTotal: fatTotal ?? this.fatTotal,
      carbTotal: carbTotal ?? this.carbTotal,
    );
  }
}

/// 菜谱食材模型（单位统一化：ingredientId + quantity + unitId）
class Ingredient {
  /// 食材库ID
  final String ingredientId;

  /// 数量（适量时为 null）
  final double? quantity;

  /// 单位ID
  final String unitId;

  /// 展示用名称（由接口 ingredientsDisplay 或解析得到）
  final String? name;

  /// 展示用用量（如 "2只"、"适量"）
  final String? amountDisplay;

  /// 库存状态：sufficient / insufficient / unknown
  final String? status;

  /// 兼容旧版
  final String? amount;
  final bool? available;

  Ingredient({
    required this.ingredientId,
    this.quantity,
    required this.unitId,
    this.name,
    this.amountDisplay,
    this.status,
    this.amount,
    this.available,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    double? q;
    if (json['quantity'] != null) {
      final v = json['quantity'];
      if (v is int) q = v.toDouble();
      if (v is num) q = v.toDouble();
    }
    return Ingredient(
      ingredientId: json['ingredientId']?.toString() ?? '',
      quantity: q,
      unitId: json['unitId']?.toString() ?? '',
      name: json['name'],
      amountDisplay: json['amountDisplay'],
      status: json['status'],
      amount: json['amount'],
      available: json['available'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredientId': ingredientId,
      'quantity': quantity,
      'unitId': unitId,
    };
  }

  /// 用于展示的用量文案（优先 amountDisplay，否则 quantity+单位 或 amount）
  String get displayAmount {
    if (amountDisplay != null && amountDisplay!.isNotEmpty) {
      return amountDisplay!;
    }
    if (quantity != null && quantity! > 0 && unitId.isNotEmpty) {
      if (quantity! == quantity!.truncate()) {
        return '${quantity!.toInt()}$unitId';
      }
      return '$quantity$unitId';
    }
    return amount ?? '适量';
  }
}
