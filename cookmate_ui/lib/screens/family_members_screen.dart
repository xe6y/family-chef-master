import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/family_service.dart';
import 'family_preferences_screen.dart';

// --- Theme Constants ---
const Color _oatmeal = Color(0xFFF5F5F0);
const Color _sageGreen = Color(0xFFB2AC88);
const Color _persimmon = Color(0xFFE58A73);
const Color _textPrimary = Color(0xFF4A4F50);
const Color _textSecondary = Color(0xFF8C8F90);

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final FamilyService _familyService = FamilyService();
  Family? _family;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    setState(() => _isLoading = true);
    try {
      _family = await _familyService.getMyFamily();
    } catch (e) {
      debugPrint('加载家庭失败: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _oatmeal,
      appBar: AppBar(
        backgroundColor: _oatmeal,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '我的家庭',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: _textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _sageGreen))
          : _family == null
          ? _buildNoFamilyState()
          : _buildFamilyContent(),
    );
  }

  Widget _buildNoFamilyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _sageGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.home_rounded, size: 64, color: _sageGreen),
          ),
          const SizedBox(height: 24),
          const Text(
            "您还没有加入家庭",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text("创建一个或输入邀请码加入吧", style: TextStyle(color: _textSecondary)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _showCreateFamilyDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: _sageGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              "创建我的家庭",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _showJoinFamilyDialog,
            child: const Text(
              "输入邀请码加入家庭",
              style: TextStyle(color: _sageGreen, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Family Card (Name & Invite Code)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _sageGreen,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: _sageGreen.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _family!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(Icons.edit_note_rounded, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "家庭邀请码",
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: Colors.white.withValues(alpha: 0.2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _family!.inviteCode,
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: _family!.inviteCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('邀请码已复制到剪贴板 📋')),
                              );
                            },
                            child: const Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "家庭成员 (${_family!.members.length})",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FamilyPreferencesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu, size: 18),
                    label: const Text("偏好设置"),
                    style: TextButton.styleFrom(
                      foregroundColor: _sageGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add_alt_rounded, size: 18),
                    label: const Text("邀请"),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Member List
          ..._family!.members.map((m) => _buildMemberCard(m)),

          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: _showLeaveFamilyDialog,
              style: TextButton.styleFrom(foregroundColor: _persimmon),
              child: const Text(
                "退出家庭",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(FamilyMemberBrief member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _oatmeal,
            backgroundImage: member.avatar != null && member.avatar!.isNotEmpty
                ? NetworkImage(member.avatar!)
                : null,
            child: (member.avatar == null || member.avatar!.isEmpty)
                ? const Icon(Icons.person, color: _textSecondary)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.nickname,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  member.role == 'owner' ? '家庭创建者' : '家庭成员',
                  style: const TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ),
          if (member.role == 'owner')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _sageGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "OWNER",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: _sageGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 显示创建家庭对话框
  void _showCreateFamilyDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建家庭'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '家庭名称',
            hintText: '例如：张家大院',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入家庭名称')),
                );
                return;
              }

              Navigator.pop(context);
              await _createFamily(name);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  /// 显示加入家庭对话框
  void _showJoinFamilyDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加入家庭'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: '邀请码',
            hintText: '请输入6位邀请码',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入邀请码')),
                );
                return;
              }

              Navigator.pop(context);
              await _joinFamily(code);
            },
            child: const Text('加入'),
          ),
        ],
      ),
    );
  }

  /// 显示退出家庭确认对话框
  void _showLeaveFamilyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出家庭'),
        content: const Text('确定要退出当前家庭吗？退出后将无法查看家庭信息。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _leaveFamily();
            },
            style: TextButton.styleFrom(foregroundColor: _persimmon),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  /// 创建家庭
  Future<void> _createFamily(String name) async {
    try {
      await _familyService.createFamily(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('创建成功！')),
        );
        _loadFamily();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败：$e')),
        );
      }
    }
  }

  /// 加入家庭
  Future<void> _joinFamily(String inviteCode) async {
    try {
      await _familyService.joinFamily(inviteCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加入成功！')),
        );
        _loadFamily();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加入失败：$e')),
        );
      }
    }
  }

  /// 退出家庭
  Future<void> _leaveFamily() async {
    try {
      await _familyService.leaveFamily();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已退出家庭')),
        );
        _loadFamily();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('退出失败：$e')),
        );
      }
    }
  }
}
