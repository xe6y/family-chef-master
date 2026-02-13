import '../config/api_config.dart';
import '../models/unit.dart';
import 'http_client.dart';

/// 单位服务
class UnitService {
  final HttpClient _client = HttpClient();
  static final UnitService _instance = UnitService._internal();
  factory UnitService() => _instance;
  UnitService._internal();

  /// 获取单位列表
  Future<List<Unit>> getUnits() async {
    final response = await _client.get(ApiConfig.units);
    if (response.isSuccess && response.data != null) {
      return (response.data['list'] as List? ?? [])
          .map((e) => Unit.fromJson(e))
          .toList();
    }
    return [];
  }
}
