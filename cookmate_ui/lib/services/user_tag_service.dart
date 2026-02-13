import '../config/api_config.dart';
import 'http_client.dart';

/// 用户标签
class UserTag {
  final String id;
  final String name;
  final String color;
  final int useCount;

  UserTag({
    required this.id,
    required this.name,
    required this.color,
    required this.useCount,
  });

  factory UserTag.fromJson(Map<String, dynamic> json) {
    return UserTag(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '',
      useCount: json['useCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'useCount': useCount,
    };
  }
}

/// 用户标签服务
class UserTagService {
  final HttpClient _client = HttpClient();

  static final UserTagService _instance = UserTagService._internal();
  factory UserTagService() => _instance;
  UserTagService._internal();

  /// 获取用户常用标签
  Future<List<UserTag>?> getUserTags() async {
    final response = await _client.get(ApiConfig.userTags);

    if (response.isSuccess && response.data != null) {
      final list = (response.data as List? ?? [])
          .map((e) => UserTag.fromJson(e))
          .toList();
      return list;
    }

    return null;
  }
}
