import 'dart:convert';

/// 菜谱草稿状态
enum DraftStatus {
  /// 正在从 URL 提取中
  extracting,

  /// 提取成功，等待用户编辑
  ready,

  /// 提取失败
  failed,
}

/// 菜谱草稿
///
/// 用于保存两种类型的草稿：
/// - URL 提取草稿（从链接获取菜谱）：有 sourceUrl，提取完成后有 extractedData
/// - 手动草稿（暂未使用，预留扩展）
class RecipeDraft {
  final String id;

  /// 来源 URL（从链接获取时有值）
  final String? sourceUrl;

  /// 草稿名称（提取前显示 URL 域名，提取后显示菜名）
  final String name;

  final DraftStatus status;

  /// 提取失败的错误信息
  final String? errorMessage;

  /// 提取成功的菜谱数据（来自 extractor API 的原始 JSON）
  final Map<String, dynamic>? extractedData;

  final DateTime createdAt;

  const RecipeDraft({
    required this.id,
    this.sourceUrl,
    required this.name,
    required this.status,
    this.errorMessage,
    this.extractedData,
    required this.createdAt,
  });

  RecipeDraft copyWith({
    String? name,
    DraftStatus? status,
    String? errorMessage,
    Map<String, dynamic>? extractedData,
  }) {
    return RecipeDraft(
      id: id,
      sourceUrl: sourceUrl,
      name: name ?? this.name,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      extractedData: extractedData ?? this.extractedData,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceUrl': sourceUrl,
    'name': name,
    'status': status.name,
    'errorMessage': errorMessage,
    'extractedData': extractedData,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RecipeDraft.fromJson(Map<String, dynamic> json) => RecipeDraft(
    id: json['id'] as String,
    sourceUrl: json['sourceUrl'] as String?,
    name: json['name'] as String? ?? '草稿',
    status: DraftStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => DraftStatus.failed,
    ),
    errorMessage: json['errorMessage'] as String?,
    extractedData: json['extractedData'] != null
        ? Map<String, dynamic>.from(json['extractedData'] as Map)
        : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  /// 序列化列表
  static String encodeList(List<RecipeDraft> drafts) =>
      jsonEncode(drafts.map((d) => d.toJson()).toList());

  /// 反序列化列表
  static List<RecipeDraft> decodeList(String raw) {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => RecipeDraft.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
