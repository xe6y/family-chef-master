import '../config/api_config.dart';
import 'http_client.dart';

/// 食材需求项
class IngredientRequirement {
  final String ingredientId;
  final String ingredientName;
  final double requiredAmount;
  final double availableAmount;
  final String unit;
  final bool isSufficient;

  IngredientRequirement({
    required this.ingredientId,
    required this.ingredientName,
    required this.requiredAmount,
    required this.availableAmount,
    required this.unit,
    required this.isSufficient,
  });

  /// 缺少的数量
  double get missingAmount => requiredAmount - availableAmount;

  factory IngredientRequirement.fromJson(Map<String, dynamic> json) {
    return IngredientRequirement(
      ingredientId: json['ingredientId'] ?? '',
      ingredientName: json['ingredientName'] ?? '',
      requiredAmount: (json['requiredAmount'] ?? 0).toDouble(),
      availableAmount: (json['availableAmount'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      isSufficient: json['isSufficient'] ?? false,
    );
  }
}

/// 食材检查结果
class IngredientCheckResult {
  final bool allSufficient;
  final List<IngredientRequirement> requirements;

  IngredientCheckResult({
    required this.allSufficient,
    required this.requirements,
  });

  /// 不足的食材列表
  List<IngredientRequirement> get insufficientIngredients =>
      requirements.where((r) => !r.isSufficient).toList();

  /// 充足的食材列表
  List<IngredientRequirement> get sufficientIngredients =>
      requirements.where((r) => r.isSufficient).toList();

  factory IngredientCheckResult.fromJson(Map<String, dynamic> json) {
    return IngredientCheckResult(
      allSufficient: json['allSufficient'] ?? false,
      requirements: (json['requirements'] as List? ?? [])
          .map((e) => IngredientRequirement.fromJson(e))
          .toList(),
    );
  }
}

/// 食材检查服务
class IngredientCheckService {
  final HttpClient _client = HttpClient();

  static final IngredientCheckService _instance =
      IngredientCheckService._internal();

  factory IngredientCheckService() => _instance;

  IngredientCheckService._internal();

  /// 检查今日菜单的食材需求
  /// 返回: 食材检查结果
  Future<IngredientCheckResult?> checkTodayMenuIngredients() async {
    final response = await _client.get('${ApiConfig.meals}/ingredient-check');

    if (response.isSuccess && response.data != null) {
      return IngredientCheckResult.fromJson(response.data);
    }

    return null;
  }
}
