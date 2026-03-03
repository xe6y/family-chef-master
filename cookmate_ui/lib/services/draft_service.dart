import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe_draft.dart';

class DraftService extends ChangeNotifier {
  static final DraftService _instance = DraftService._internal();
  factory DraftService() => _instance;
  DraftService._internal();

  static const _storageKey = 'recipe_drafts';

  List<RecipeDraft> _drafts = [];
  List<RecipeDraft> get drafts => List.unmodifiable(_drafts);

  /// 从本地存储加载草稿
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _drafts = [];
    } else {
      try {
        _drafts = RecipeDraft.decodeList(raw);
      } catch (_) {
        _drafts = [];
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, RecipeDraft.encodeList(_drafts));
  }

  /// 创建一个"提取中"草稿，返回 id
  Future<String> createExtractingDraft(String url) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final draft = RecipeDraft(
      id: id,
      sourceUrl: url,
      name: _shortUrl(url),
      status: DraftStatus.extracting,
      createdAt: DateTime.now(),
    );
    _drafts.insert(0, draft);
    await _save();
    notifyListeners();
    return id;
  }

  /// 更新草稿为成功状态
  Future<void> markReady(String id, Map<String, dynamic> data) async {
    final idx = _drafts.indexWhere((d) => d.id == id);
    if (idx == -1) return;
    _drafts[idx] = _drafts[idx].copyWith(
      name: data['name'] as String? ?? _drafts[idx].name,
      status: DraftStatus.ready,
      extractedData: data,
    );
    await _save();
    notifyListeners();
  }

  /// 更新草稿为失败状态
  Future<void> markFailed(String id, String error) async {
    final idx = _drafts.indexWhere((d) => d.id == id);
    if (idx == -1) return;
    _drafts[idx] = _drafts[idx].copyWith(
      status: DraftStatus.failed,
      errorMessage: error,
    );
    await _save();
    notifyListeners();
  }

  /// 删除草稿
  Future<void> deleteDraft(String id) async {
    _drafts.removeWhere((d) => d.id == id);
    await _save();
    notifyListeners();
  }

  /// 从 URL 提取菜谱（异步，自动更新草稿状态）
  ///
  /// 调用链：createExtractingDraft → HTTP POST /extract → markReady / markFailed
  Future<void> extractFromUrl(String url, String extractorBaseUrl) async {
    final id = await createExtractingDraft(url);
    try {
      final response = await http
          .post(
            Uri.parse('$extractorBaseUrl/extract'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': url}),
          )
          .timeout(const Duration(minutes: 3));

      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true && body['data'] != null) {
        await markReady(id, Map<String, dynamic>.from(body['data'] as Map));
      } else {
        final error = body['error'] as String?
            ?? body['detail'] as String?
            ?? '提取失败（HTTP ${response.statusCode}）';
        await markFailed(id, error);
      }
    } catch (e) {
      await markFailed(id, e.toString());
    }
  }

  static String _shortUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url.length > 30 ? '${url.substring(0, 30)}...' : url;
    }
  }
}
