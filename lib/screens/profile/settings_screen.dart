import 'package:acmms/screens/features/auth/worker_login.dart';
import 'package:acmms/shared/app_bottom_navbar.dart';
import 'package:acmms/shared/bottom_tab.dart';
import 'package:flutter/material.dart';
import '../../core/service/worker_service.dart';
import '../../models/worker.dart';
import 'profile_screen.dart';
import 'change_password_screen.dart';
import 'help_screen.dart';
import 'about_app_screen.dart';
import 'report_problem_screen.dart';

const Color primaryTeal = Color(0xFF1FCFC5);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<Worker> _workerFuture;

  @override
  void initState() {
    super.initState();
    _workerFuture = WorkerService.getCurrentWorker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text('Cài đặt'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _profileCard(),
          const SizedBox(height: 24),
          _sectionTitle('TÀI KHOẢN'),
          _settingItem(
            icon: Icons.person,
            title: 'Hồ sơ cá nhân',
            onTap: () => _go(context, const ProfileScreen()),
          ),
          _settingItem(
            icon: Icons.lock,
            title: 'Đổi mật khẩu',
            onTap: () => _go(context, const ChangePasswordScreen()),
          ),
          const SizedBox(height: 24),
          _sectionTitle('CHUNG'),
          _settingItem(
            icon: Icons.help_outline,
            title: 'Trợ giúp',
            onTap: () => _go(context, const HelpScreen()),
          ),
          _settingItem(
            icon: Icons.info_outline,
            title: 'Thông tin ứng dụng',
            onTap: () => _go(context, const AboutAppScreen()),
          ),
          _settingItem(
            icon: Icons.bug_report_outlined,
            title: 'Báo lỗi / Góp ý',
            onTap: () => _go(context, const ReportProblemScreen()),
          ),
          const SizedBox(height: 24),
          _logoutButton(context),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentTab: BottomTab.setting),
    );
  }

  Widget _profileCard() {
    return FutureBuilder<Worker>(
        future: _workerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải hồ sơ: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Không có dữ liệu người dùng.'));
          }

          final worker = snapshot.data!;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: (worker.avatarUrl != null &&
                          worker.avatarUrl!.isNotEmpty)
                      ? NetworkImage(worker.avatarUrl!)
                      : const AssetImage('assets/avatar.png') as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(worker.role,
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _settingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryTeal.withOpacity(0.1),
          child: Icon(icon, color: primaryTeal),
        ),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFE5E5),
          child: Icon(Icons.logout, color: Colors.red),
        ),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
        onTap: () {
          _showLogoutDialog(context);
        },
      ),
    );
  }

  void _go(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
