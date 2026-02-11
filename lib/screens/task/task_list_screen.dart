import 'package:acmms/shared/app_bottom_navbar.dart';
import 'package:acmms/shared/bottom_tab.dart';
import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../data/mock_task.dart';
import 'task_detail_screen.dart';

const Color primaryTeal = Color(0xFF1FCFC5);

enum TaskFilter { all, today, week }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  TaskFilter _currentFilter = TaskFilter.all;

  List<TaskModel> get _filteredTasks {
    List<TaskModel> tasks = mockTasks.where((task) {
      if (_currentFilter == TaskFilter.all) return true;
      if (_currentFilter == TaskFilter.today) return task.date == 'Hôm nay';
      if (_currentFilter == TaskFilter.week) return true;
      return false;
    }).toList();

    tasks.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return 0;
    });

    return tasks;
  }

  void _openDetail(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      bottomNavigationBar: const AppBottomNav(currentTab: BottomTab.task),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Danh sách nhiệm vụ',
              style: TextStyle(color: Colors.black),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _buildFilter(),
            ),
          ),
        ],
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _filteredTasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, index) {
            final task = _filteredTasks[index];
            return _buildTaskCard(task);
          },
        ),
      ),
    );
  }

  Widget _buildFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _filterItem('Tất cả', TaskFilter.all),
          _filterItem('Hôm nay', TaskFilter.today),
          _filterItem('Tuần này', TaskFilter.week),
        ],
      ),
    );
  }

  Widget _filterItem(String text, TaskFilter filter) {
    final active = _currentFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              color: active ? primaryTeal : Colors.grey,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          if (active)
            Container(
              width: 40,
              height: 2,
              color: primaryTeal,
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    if (task.isUrgent) {
      return _urgentCard(task);
    }
    return _normalCard(task);
  }

  Widget _urgentCard(TaskModel task) {
    return InkWell(
      onTap: () => _openDetail(task),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: Colors.red, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠ KHẨN CẤP',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            const SizedBox(height: 8),
            Text(task.title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(task.description, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            _infoRow(Icons.access_time,
                '${task.startTime}• ${task.endTime} • ${task.date}'),
            _infoRow(Icons.location_on,
                '${task.field} • ${task.area}${task.bed.isNotEmpty ? ' • ${task.bed}' : ''}'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () => _openDetail(task),
                child: const Text('Xử lý ngay'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _normalCard(TaskModel task) {
    return InkWell(
      onTap: () => _openDetail(task),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(task.avatarIcon, color: primaryTeal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(task.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          _statusBadge(task.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(task.description,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      _infoRow(Icons.access_time,
                          '${task.startTime}• ${task.endTime} • ${task.date}'),
                      _infoRow(Icons.location_on,
                          '${task.field} • ${task.area}${task.bed.isNotEmpty ? ' • ${task.bed}' : ''}'),
                      _infoRow(Icons.person, 'Giao bởi: ${task.assignedBy}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _openDetail(task),
                    child: const Text('Xem chi tiết'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                    onPressed: () => _openDetail(task),
                    child: const Text('Tiếp tục'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(TaskStatus status) {
    late String text;
    late Color bg;

    switch (status) {
      case TaskStatus.doing:
        text = 'ĐANG THỰC HIỆN';
        bg = Colors.blue.shade50;
        break;
      case TaskStatus.pending:
        text = 'CHƯA BẮT ĐẦU';
        bg = Colors.grey.shade200;
        break;
      case TaskStatus.completed:
        text = 'HOÀN THÀNH';
        bg = Colors.green.shade50;
        break;
      default:
        text = 'KHẨN CẤP';
        bg = Colors.red.shade50;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
