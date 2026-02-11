import 'package:flutter/material.dart';
import 'package:acmms/models/task_model.dart';

class TaskDetailScreen extends StatelessWidget {
  final TaskModel task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTaskHeader(),
            const SizedBox(height: 16),
            _buildUpdateSection(),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTags()),
              const SizedBox(width: 12),
              _buildImage(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${task.cropName} – ${task.season}',
            style: const TextStyle(color: Colors.grey),
          ),
          const Divider(height: 24),
          _infoRow(
            icon: Icons.location_on,
            title: 'Địa điểm',
            value: task.fullLocation,
          ),
          _infoRow(
            icon: Icons.access_time,
            title: 'Thời gian dự kiến',
            value: '${task.timeRange}, ${task.date}',
          ),
          _infoRow(
            icon: Icons.person,
            title: 'Người giao việc',
            value: '${task.assignedBy} – ${task.assignedRole}',
          ),
          _infoRow(
            icon: Icons.info,
            title: 'Trạng thái',
            value: _statusLabel(task.status),
            valueColor: _statusColor(task.status),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cập nhật công việc hôm nay',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ví dụ: đã phun xong 2 luống đầu...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt),
            label: const Text('Thêm ảnh hiện trường'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: Colors.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {},
          icon: const Icon(Icons.save),
          label: const Text('Ghi nhận công việc'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {},
          icon: const Icon(Icons.check_circle),
          label: const Text('Đánh dấu hoàn thành'),
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      children: [
        _chip(task.taskType, Colors.teal),
        if (task.isUrgent) _chip('Khẩn cấp', Colors.redAccent),
      ],
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        task.imageAsset,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
        ),
      ],
    );
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.doing:
        return 'Đang thực hiện';
      case TaskStatus.pending:
        return 'Chưa bắt đầu';
      case TaskStatus.completed:
        return 'Hoàn thành';
      case TaskStatus.urgent:
        return 'Khẩn cấp';
    }
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.doing:
        return Colors.teal;
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.urgent:
        return Colors.red;
    }
  }
}
