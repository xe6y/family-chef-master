import '../config/api_config.dart';
import 'http_client.dart';

/// 存储位置模型
class StorageLocation {
  final String id;
  final String name;
  final int sortOrder;
  final bool isSystem;

  StorageLocation({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.isSystem = false,
  });

  factory StorageLocation.fromJson(Map<String, dynamic> json) {
    return StorageLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isSystem: json['isSystem'] as bool? ?? false,
    );
  }
}

/// 存储位置服务
class StorageLocationService {
  final HttpClient _client = HttpClient();
  static final StorageLocationService _instance = StorageLocationService._internal();

  factory StorageLocationService() => _instance;

  StorageLocationService._internal();

  /// 获取存储位置列表
  Future<List<StorageLocation>> getStorageLocations() async {
    final response = await _client.get(ApiConfig.storageLocations);
    if (response.isSuccess && response.data != null) {
      final list = response.data['list'] as List? ?? [];
      return list.map((e) => StorageLocation.fromJson(e)).toList();
    }
    return [];
  }

  /// 创建存储位置
  Future<StorageLocation?> createStorageLocation(String name, int sortOrder) async {
    final response = await _client.post(
      ApiConfig.storageLocations,
      data: {'name': name, 'sortOrder': sortOrder},
    );
    if (response.isSuccess && response.data != null) {
      return StorageLocation.fromJson(response.data);
    }
    return null;
  }

  /// 更新存储位置
  Future<StorageLocation?> updateStorageLocation(String id, {String? name, int? sortOrder}) async {
    final response = await _client.put(
      '${ApiConfig.storageLocations}/$id',
      data: {
        if (name != null) 'name': name,
        if (sortOrder != null) 'sortOrder': sortOrder,
      },
    );
    if (response.isSuccess && response.data != null) {
      return StorageLocation.fromJson(response.data);
    }
    return null;
  }

  /// 删除存储位置
  Future<bool> deleteStorageLocation(String id) async {
    final response = await _client.delete('${ApiConfig.storageLocations}/$id');
    return response.isSuccess;
  }

  /// 重新排序
  Future<bool> reorderStorageLocations(List<String> ids) async {
    final response = await _client.post(
      ApiConfig.storageLocationsReorder,
      data: {'ids': ids},
    );
    return response.isSuccess;
  }
}
