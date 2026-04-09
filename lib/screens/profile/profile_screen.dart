import 'package:flutter/material.dart';
import '../../core/service/worker_service.dart';
import '../../models/worker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Worker> _workerFuture;

  @override
  void initState() {
    super.initState();
    _workerFuture = WorkerService.getCurrentWorker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
      body: FutureBuilder<Worker>(
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

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.teal.shade100,
                  backgroundImage:
                      (worker.avatarUrl != null && worker.avatarUrl!.isNotEmpty)
                          ? NetworkImage(worker.avatarUrl!)
                          : null,
                  child: (worker.avatarUrl == null || worker.avatarUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 48, color: Colors.teal)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  worker.fullName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(worker.role),
                const SizedBox(height: 24),
                if (worker.phoneNumber != null &&
                    worker.phoneNumber!.isNotEmpty)
                  _infoRow('Số điện thoại', worker.phoneNumber!),
                if (worker.email != null && worker.email!.isNotEmpty)
                  _infoRow('Email', worker.email!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
