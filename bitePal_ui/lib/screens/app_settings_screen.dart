import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// --- Theme Constants ---
const Color _oatmeal = Color(0xFFF5F5F0);
const Color _sageGreen = Color(0xFFB2AC88);
const Color _textPrimary = Color(0xFF4A4F50);
const Color _textSecondary = Color(0xFF8C8F90);

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _notificationEnabled = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _oatmeal,
      appBar: AppBar(
        backgroundColor: _oatmeal,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '应用设置',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "个性化",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingCard(
              Icons.notifications_active_rounded,
              "通知提醒",
              "接收食材过期与点餐提醒",
              Switch(
                value: _notificationEnabled,
                onChanged: (v) => setState(() => _notificationEnabled = v),
                activeThumbColor: _sageGreen,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              Icons.dark_mode_rounded,
              "深色模式",
              "让视力更舒适",
              Switch(
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
                activeThumbColor: _sageGreen,
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              "数据管理",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              Icons.storage_rounded,
              "清理缓存",
              "释放本地占用空间 (12.4 MB)",
            ),
            const SizedBox(height: 12),
            _buildActionCard(Icons.cloud_sync_rounded, "同步数据", "手动将数据备份至云端"),

            const SizedBox(height: 32),
            const Text(
              "关于",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              Icons.info_outline_rounded,
              "版本信息",
              "BitePal v1.0.0 (Stable)",
            ),
            _buildActionCard(Icons.description_outlined, "隐私协议", "我们如何保护您的数据"),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    IconData icon,
    String title,
    String sub,
    Widget trailing,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _sageGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _sageGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _sageGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _sageGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}
