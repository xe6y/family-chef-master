/// 食材库模型（主数据）
class IngredientMaster {
  final String id;
  final String name;
  final String? categoryId;
  final String baseUnitId;
  final double caloriesPer100;
  final double proteinPer100;
  final double fatPer100;
  final double carbPer100;
  final int sortOrder;

  IngredientMaster({
    required this.id,
    required this.name,
    this.categoryId,
    this.baseUnitId = 'g',
    this.caloriesPer100 = 0,
    this.proteinPer100 = 0,
    this.fatPer100 = 0,
    this.carbPer100 = 0,
    this.sortOrder = 0,
  });

  factory IngredientMaster.fromJson(Map<String, dynamic> json) {
    return IngredientMaster(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      categoryId: json['categoryId'] ?? json['category_id'],
      baseUnitId: json['baseUnitId'] ?? json['base_unit_id'] ?? 'g',
      caloriesPer100: (json['caloriesPer100'] ?? json['calories_per_100'] ?? 0).toDouble(),
      proteinPer100: (json['proteinPer100'] ?? json['protein_per_100'] ?? 0).toDouble(),
      fatPer100: (json['fatPer100'] ?? json['fat_per_100'] ?? 0).toDouble(),
      carbPer100: (json['carbPer100'] ?? json['carb_per_100'] ?? 0).toDouble(),
      sortOrder: json['sortOrder'] ?? json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'baseUnitId': baseUnitId,
        'caloriesPer100': caloriesPer100,
        'proteinPer100': proteinPer100,
        'fatPer100': fatPer100,
        'carbPer100': carbPer100,
        'sortOrder': sortOrder,
      };
}

/// 食材-常用单位项（某食材下的单位及换算）
class IngredientUnitOption {
  final String unitId;
  final double factorToBase;
  final String displayName;
  final int sortOrder;

  IngredientUnitOption({
    required this.unitId,
    required this.factorToBase,
    required this.displayName,
    this.sortOrder = 0,
  });

  factory IngredientUnitOption.fromJson(Map<String, dynamic> json) {
    return IngredientUnitOption(
      unitId: json['unitId']?.toString() ?? json['unit_id'] ?? '',
      factorToBase: (json['factorToBase'] ?? json['factor_to_base'] ?? 0).toDouble(),
      displayName: json['displayName'] ?? json['display_name'] ?? '',
      sortOrder: json['sortOrder'] ?? json['sort_order'] ?? 0,
    );
  }
}
