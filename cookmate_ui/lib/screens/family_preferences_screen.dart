import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/preference_service.dart';
import 'member_preference_edit_screen.dart';

/// 家庭成员偏好设置界面
class FamilyPreferencesScreen extends StatefulWidget {
  const FamilyPreferencesScreen({super.key});

  @override
  State<FamilyPreferencesScreen> createState() =>
      _FamilyPreferencesScreenState();
}

class _FamilyPreferencesScreenState extends State<FamilyPreferencesScreen> {
  final _preferenceService = PreferenceService();
  List<FamilyMember> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// 加载家庭成员偏好
  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final members = await _preferenceService.getFamilyPreferences();
      setState(() {
        _members = members;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('家庭成员偏好'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3648),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _handleAddMember,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_members.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPreferences,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          return _buildMemberCard(_members[index]);
        },
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有添加成员偏好',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _handleAddMember,
            icon: const Icon(Icons.add),
            label: const Text('添加成员'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建成员卡片
  Widget _buildMemberCard(FamilyMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _handleEditMember(member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 成员名称和操作按钮
              Row(
                children: [
                  Expanded(
                    child: Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3648),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _handleEditMember(member),
                    color: const Color(0xFF4CAF50),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _handleDeleteMember(member),
                    color: const Color(0xFFFF6B6B),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 口味偏好
              if (member.preferences.tastes.isNotEmpty) ...[
                _buildPreferenceSection(
                  '口味偏好',
                  member.preferences.tastes,
                  const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 8),
              ],

              // 过敏食材
              if (member.preferences.allergies.isNotEmpty) ...[
                _buildPreferenceSection(
                  '过敏食材',
                  member.preferences.allergies,
                  const Color(0xFFFF6B6B),
                ),
                const SizedBox(height: 8),
              ],

              // 不喜欢的食材
              if (member.preferences.dislikes.isNotEmpty) ...[
                _buildPreferenceSection(
                  '不喜欢',
                  member.preferences.dislikes,
                  const Color(0xFFFFA726),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建偏好设置区域
  Widget _buildPreferenceSection(
    String title,
    List<String> items,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 处理添加成员
  Future<void> _handleAddMember() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const MemberPreferenceEditScreen(),
      ),
    );

    if (result == true) {
      _loadPreferences();
    }
  }

  /// 处理编辑成员
  Future<void> _handleEditMember(FamilyMember member) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MemberPreferenceEditScreen(member: member),
      ),
    );

    if (result == true) {
      _loadPreferences();
    }
  }

  /// 处理删除成员
  Future<void> _handleDeleteMember(FamilyMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 ${member.name} 的偏好设置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B6B),
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && member.id != null) {
      try {
        await _preferenceService.deleteFamilyMember(member.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
          _loadPreferences();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e')),
          );
        }
      }
    }
  }
}
