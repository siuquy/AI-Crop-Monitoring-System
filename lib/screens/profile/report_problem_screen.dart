import 'package:flutter/material.dart';

class ReportProblemScreen extends StatelessWidget {
  const ReportProblemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo lỗi / Góp ý')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField(
              items: const [
                DropdownMenuItem(value: 'task', child: Text('Lỗi công việc')),
                DropdownMenuItem(value: 'app', child: Text('Lỗi ứng dụng')),
                DropdownMenuItem(value: 'other', child: Text('Khác')),
              ],
              onChanged: (_) {},
              decoration: const InputDecoration(labelText: 'Loại vấn đề'),
            ),
            const SizedBox(height: 16),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Mô tả ngắn gọn vấn đề...',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Gửi phản hồi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
