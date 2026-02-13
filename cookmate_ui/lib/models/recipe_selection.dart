import 'recipe.dart';
import 'user.dart';

/// 菜谱选择记录
/// 记录一道菜被哪些家庭成员选择
class RecipeSelection {
  /// 菜谱信息
  final Recipe recipe;

  /// 选择者列表（家庭成员）
  final List<FamilyMember> selectedBy;

  /// 来源类型：'my' 我的私房, 'online' 网络菜谱
  final String source;

  /// 是否勾选（最终确认）
  bool isChecked;

  RecipeSelection({
    required this.recipe,
    required this.selectedBy,
    required this.source,
    this.isChecked = true,
  });

  /// 获取选择人数
  int get selectionCount => selectedBy.length;

  /// 检查特定成员是否选择了这道菜
  bool isSelectedBy(String memberId) {
    return selectedBy.any((member) => member.id == memberId);
  }

  /// 添加选择者
  void addSelector(FamilyMember member) {
    if (!isSelectedBy(member.id ?? '')) {
      selectedBy.add(member);
    }
  }

  /// 移除选择者
  void removeSelector(String memberId) {
    selectedBy.removeWhere((member) => member.id == memberId);
  }

  /// 从 JSON 创建实例
  factory RecipeSelection.fromJson(Map<String, dynamic> json) {
    return RecipeSelection(
      recipe: Recipe.fromJson(json['recipe'] ?? {}),
      selectedBy: (json['selectedBy'] as List<dynamic>?)
              ?.map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      source: json['source'] ?? 'my',
      isChecked: json['isChecked'] ?? true,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'recipe': recipe.toJson(),
      'selectedBy': selectedBy.map((e) => e.toJson()).toList(),
      'source': source,
      'isChecked': isChecked,
    };
  }
}
