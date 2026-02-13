import 'package:flutter/material.dart';
import '../models/user.dart';
import '../components/ui/tag_selector/tag_selector.dart';
import '../services/preference_service.dart';

/// 成员偏好编辑界面
class MemberPreferenceEditScreen extends StatefulWidget {
  /// 要编辑的成员（null 表示新增）
  final FamilyMember? member;

  const MemberPreferenceEditScreen({
    super.key,
    this.member,
  });

  @override
  State<MemberPreferenceEditScreen> createState() =>
      _MemberPreferenceEditScreenState();
}

class _MemberPreferenceEditScreenState
    extends State<MemberPreferenceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _preferenceService = PreferenceService();

  // 偏好数据
  List<String> _selectedTastes = [];
  List<String> _selectedAllergies = [];
  List<String> _selectedDislikes = [];

  bool _isLoading = false;

  // 预设选项
  static const List<String> _tasteOptions = [
    '甜',
    '咸',
    '辣',
    '酸',
    '苦',
    '鲜',
    '清淡',
    '重口味',
  ];

  static const List<String> _commonAllergies = [
    '花生',
    '海鲜',
    '牛奶',
    '鸡蛋',
    '大豆',
    '小麦',
    '坚果',
    '芝麻',
  ];

  static const List<String> _commonDislikes = [
    '香菜',
    '葱',
    '姜',
    '蒜',
    '洋葱',
    '芹菜',
    '胡萝卜',
    '青椒',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 初始化数据
  void _initializeData() {
    if (widget.member != null) {
      _nameController.text = widget.member!.name;
      _selectedTastes = List.from(widget.member!.preferences.tastes);
      _selectedAllergies = List.from(widget.member!.preferences.allergies);
      _selectedDislikes = List.from(widget.member!.preferences.dislikes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(widget.member == null ? '添加成员' : '编辑成员偏好'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3648),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNameSection(),
            const SizedBox(height: 24),
            _buildTastesSection(),
            const SizedBox(height: 24),
            _buildAllergiesSection(),
            const SizedBox(height: 24),
            _buildDislikesSection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  /// 构建姓名输入区域
  Widget _buildNameSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '成员姓名',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3648),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: '请输入成员姓名',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入成员姓名';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// 构建口味偏好区域
  Widget _buildTastesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TagSelector(
        title: '口味偏好',
        availableTags: _tasteOptions,
        selectedTags: _selectedTastes,
        onChanged: (tags) {
          setState(() {
            _selectedTastes = tags;
          });
        },
        allowCustom: true,
        customHint: '例如：微辣、偏甜',
      ),
    );
  }

  /// 构建过敏食材区域
  Widget _buildAllergiesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TagSelector(
        title: '过敏食材',
        availableTags: _commonAllergies,
        selectedTags: _selectedAllergies,
        onChanged: (tags) {
          setState(() {
            _selectedAllergies = tags;
          });
        },
        allowCustom: true,
        customHint: '例如：芒果、菠萝',
      ),
    );
  }

  /// 构建不喜欢食材区域
  Widget _buildDislikesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TagSelector(
        title: '不喜欢的食材',
        availableTags: _commonDislikes,
        selectedTags: _selectedDislikes,
        onChanged: (tags) {
          setState(() {
            _selectedDislikes = tags;
          });
        },
        allowCustom: true,
        customHint: '例如：苦瓜、茄子',
      ),
    );
  }

  /// 构建保存按钮
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _handleSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: const Text(
        '保存',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 处理保存
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final member = FamilyMember(
        id: widget.member?.id,
        name: _nameController.text.trim(),
        preferences: MemberPreferences(
          tastes: _selectedTastes,
          allergies: _selectedAllergies,
          dislikes: _selectedDislikes,
        ),
      );

      await _preferenceService.updateFamilyPreferences([member]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
