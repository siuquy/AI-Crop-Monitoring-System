import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin ứng dụng')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'AI Crop Monitoring System',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Phiên bản 1.0.2'),
            SizedBox(height: 8),
            Text('Ứng dụng hỗ trợ nông dân quản lý công việc'),
          ],
        ),
      ),
    );
  }
}
