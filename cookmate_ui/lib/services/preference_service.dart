import '../config/api_config.dart';
import '../models/user.dart';
import 'http_client.dart';

/// 家庭成员偏好设置服务
class PreferenceService {
  final HttpClient _client = HttpClient();

  /// 获取家庭成员偏好列表
  ///
  /// 返回当前用户家庭的所有成员及其偏好设置
  Future<List<FamilyMember>> getFamilyPreferences() async {
    final response = await _client.get(ApiConfig.userPreferences);

    if (response.isSuccess && response.data != null) {
      final List<dynamic> membersJson = response.data is List
          ? response.data
          : (response.data['members'] ?? []);
      return membersJson.map((json) => FamilyMember.fromJson(json)).toList();
    } else {
      throw Exception(response.message.isEmpty ? '获取偏好设置失败' : response.message);
    }
  }

  /// 更新家庭成员偏好设置
  ///
  /// [members] 要更新的成员列表（支持批量更新）
  /// 返回更新后的完整成员列表
  Future<List<FamilyMember>> updateFamilyPreferences(
    List<FamilyMember> members,
  ) async {
    final response = await _client.put(
      ApiConfig.userPreferences,
      data: {
        'members': members.map((m) => m.toJson()).toList(),
      },
    );

    if (response.isSuccess && response.data != null) {
      final List<dynamic> membersJson = response.data is List
          ? response.data
          : (response.data['members'] ?? []);
      return membersJson.map((json) => FamilyMember.fromJson(json)).toList();
    } else {
      throw Exception(response.message.isEmpty ? '更新偏好设置失败' : response.message);
    }
  }

  /// 删除家庭成员
  ///
  /// [memberId] 要删除的成员 ID
  Future<void> deleteFamilyMember(String memberId) async {
    final response = await _client.delete(
      '${ApiConfig.userPreferences}/$memberId',
    );

    if (!response.isSuccess) {
      throw Exception(response.message.isEmpty ? '删除成员失败' : response.message);
    }
  }
}
