import '../config/api_config.dart';
import '../models/ingredient_master.dart';
import 'http_client.dart';

/// 食材库服务
class IngredientMasterService {
  final HttpClient _client = HttpClient();
  static final IngredientMasterService _instance = IngredientMasterService._internal();
  factory IngredientMasterService() => _instance;
  IngredientMasterService._internal();

  /// 搜索/列表食材库
  Future<List<IngredientMaster>> search({String? q}) async {
    final response = await _client.get(
      ApiConfig.ingredientMaster,
      queryParams: {if (q != null && q.isNotEmpty) 'q': q},
    );
    if (response.isSuccess && response.data != null) {
      return (response.data['list'] as List? ?? [])
          .map((e) => IngredientMaster.fromJson(e))
          .toList();
    }
    return [];
  }

  /// 获取某食材的常用单位列表
  Future<List<IngredientUnitOption>> getUnitsForIngredient(String ingredientId) async {
    final response = await _client.get(
      '${ApiConfig.ingredientMaster}/$ingredientId/units',
    );
    if (response.isSuccess && response.data != null) {
      return (response.data['list'] as List? ?? [])
          .map((e) => IngredientUnitOption.fromJson(e))
          .toList();
    }
    return [];
  }
}
