import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';
import 'family_members_screen.dart';
import 'app_settings_screen.dart';

// --- Theme Constants ---
const Color _oatmeal = Color(0xFFF5F5F0);
const Color _sageGreen = Color(0xFFB2AC88);
const Color _persimmon = Color(0xFFE58A73);
const Color _textPrimary = Color(0xFF4A4F50);
const Color _textSecondary = Color(0xFF8C8F90);

// --- Helper Components ---

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;

  const GlassContainer({
    super.key,
    required this.child, // Added required
    this.borderRadius = 24,
    this.blur = 12,
    this.opacity = 0.4,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }
}

class BouncyCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? color;

  const BouncyCard({super.key, required this.child, required this.onTap, this.color});

  @override
  State<BouncyCard> createState() => _BouncyCardState();
}

class _BouncyCardState extends State<BouncyCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap(); },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: widget.color ?? Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _user;
  UserStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([_authService.getUserInfo(), _authService.getUserStats()]);
      _user = results[0] as User?;
      _stats = results[1] as UserStats?;
    } catch (e) {
      debugPrint('加载用户数据失败: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('退出登录', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('确定要暂时离开吗？您的厨房数据会被妥善保存。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消', style: TextStyle(color: _textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _persimmon, foregroundColor: Colors.white, elevation: 0),
            child: const Text('确认退出'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen(onLoginSuccess: () => Navigator.of(context).pop())),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: _oatmeal, body: Center(child: CircularProgressIndicator(color: _sageGreen)));

    return Scaffold(
      backgroundColor: _oatmeal,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Immersive Profile Header
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Top decoration blob
                Positioned(
                  top: -50, right: -20,
                  child: Container(width: 200, height: 200, decoration: BoxDecoration(color: _sageGreen.withOpacity(0.1), shape: BoxShape.circle)),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Back Button
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: GlassContainer(
                                borderRadius: 50,
                                padding: const EdgeInsets.all(10),
                                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _textPrimary),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _buildAvatar(),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_user?.nickname ?? _user?.username ?? '游客用户', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textPrimary)),
                                  const SizedBox(height: 2),
                                  GlassContainer(
                                    borderRadius: 8, opacity: 0.5, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Text('ID: ${_user?.userId?.substring(0, 8) ?? "---"}', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.bold, color: _textSecondary)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.qr_code_scanner_rounded, color: _textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Bento Stats
                        Row(
                          children: [
                            Expanded(child: _buildBentoStat("本月做饭", "${_stats?.monthlyCookingCount ?? 0}", "次", _sageGreen)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildBentoStat("浪费减少", "${((_stats?.wasteReductionRate ?? 0) * 100).toInt()}", "%", _persimmon)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Function Matrix
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                const Text("家庭管理", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textSecondary)),
                const SizedBox(height: 16),
                _buildMenuCard(Icons.people_alt_rounded, "家庭成员偏好", "管理口味与禁忌", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyMembersScreen()))),
                const SizedBox(height: 12),
                _buildMenuCard(Icons.receipt_long_rounded, "购物订单历史", "回顾往期采购记录", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()))),
                
                const SizedBox(height: 32),
                const Text("系统设置", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textSecondary)),
                const SizedBox(height: 16),
                _buildMenuCard(Icons.settings_suggest_rounded, "应用个性化", "主题与通知提醒", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSettingsScreen()))),
                const SizedBox(height: 12),
                _buildMenuCard(Icons.help_outline_rounded, "帮助与反馈", "遇见问题点这里", () {}),
                
                const SizedBox(height: 48),
                TextButton(
                  onPressed: _handleLogout,
                  style: TextButton.styleFrom(foregroundColor: _persimmon, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text("退出当前账号", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: _sageGreen.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Image.asset('assets/cartoon-avatar.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildBentoStat(String label, String value, String unit, Color color) {
    return BouncyCard(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(width: 4),
                Text(unit, style: TextStyle(fontSize: 12, color: color.withOpacity(0.6), fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, String sub, VoidCallback onTap) {
    return BouncyCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _sageGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: _sageGreen, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textPrimary)),
                  Text(sub, style: const TextStyle(fontSize: 11, color: _textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}