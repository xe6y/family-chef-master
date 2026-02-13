/// 单位模型（全局单位定义）
class Unit {
  final String id;
  final String displayName;
  final String unitType;
  final int sortOrder;

  Unit({
    required this.id,
    required this.displayName,
    this.unitType = 'unspecified',
    this.sortOrder = 0,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName'] ?? json['display_name'] ?? '',
      unitType: json['unitType'] ?? json['unit_type'] ?? 'unspecified',
      sortOrder: json['sortOrder'] ?? json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'unitType': unitType,
        'sortOrder': sortOrder,
      };
}
