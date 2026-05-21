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
    _loadWorkerData();
  }

  void _loadWorkerData() {
    _workerFuture = WorkerService.getCurrentWorker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tài khoản',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: FutureBuilder<Worker>(
        future: _workerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 50),
                    const SizedBox(height: 16),
                    Text(
                      'Không thể tải thông tin người dùng.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _loadWorkerData();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    )
                  ],
                ),
              ),
            );
          }

          final worker = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(worker),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Worker worker) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.teal.shade100,
              child: Text(
                worker.fullName.isNotEmpty
                    ? worker.fullName[0].toUpperCase()
                    : 'W',
                style: TextStyle(fontSize: 40, color: Colors.teal.shade800),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              worker.fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              worker.email ?? 'Chưa cập nhật email',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            if (worker.phoneNumber != null &&
                worker.phoneNumber!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                worker.phoneNumber!,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
            const SizedBox(height: 12),
            Chip(
              label: Text(worker.role,
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ],
        ),
      ),
    );
  }
}
