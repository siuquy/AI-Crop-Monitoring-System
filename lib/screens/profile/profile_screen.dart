import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.teal.shade100,
              child: const Icon(Icons.person, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nguyễn Văn A',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text('Nhân công nông trại'),
            const SizedBox(height: 24),
            _infoRow('Số điện thoại', '0909 123 456'),
            _infoRow('Tên Nông trại', 'Nông trại ABC'),
            _infoRow('Khu làm việc', 'Ruộng A – Khu 2 - Luống 5 '),
            _infoRow('Tài khoản cấp bởi', 'Chủ nông trại'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
