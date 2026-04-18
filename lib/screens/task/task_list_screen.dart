import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:acmms/shared/app_bottom_navbar.dart';
import 'package:acmms/shared/bottom_tab.dart';
import 'package:acmms/models/task_model.dart';
import 'package:acmms/core/service/task_service.dart';
import 'task_detail_screen.dart';

const Color primaryTeal = Color(0xFF4CAF50);
const Color darkTeal = Color(0xFF388E3C);
const Color bgColor = Color(0xFFF0F8F1);

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

enum TaskFilter { all, today, week }

Future<List<TaskModel>> _loadAll() async {
  // API /my-schedule không còn trả về chi tiết địa điểm,
  // nên ta chỉ cần tải danh sách công việc.
  // Thông tin chi tiết (bao gồm địa điểm) sẽ được tải trong TaskDetailScreen.
  final tasks = await TaskService.getTasks();
  debugPrint('[TaskListScreen] _loadAll completed with ${tasks.length} tasks.');
  return tasks;
}

String _formatTaskDateTime(DateTime? date) {
  if (date == null) return 'Chưa có';
  return DateFormat('dd/MM/yyyy, HH:mm').format(date.toLocal());
}

class _TaskListScreenState extends State<TaskListScreen> {
  TaskFilter _currentFilter = TaskFilter.all;
  late Future<List<TaskModel>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _loadAll();
  }

  void _refreshTasks() {
    debugPrint('[TaskListScreen] Refreshing tasks...');
    setState(() {
      _tasksFuture = _loadAll();
    });
  }

  List<TaskModel> _applyFilter(List<TaskModel> tasks) {
    List<TaskModel> filtered = tasks.where((task) {
      if (_currentFilter == TaskFilter.all) return true;

      final date = task.startDate?.toLocal();
      if (date == null) return false;

      if (_currentFilter == TaskFilter.today) {
        final now = DateTime.now();
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }

      if (_currentFilter == TaskFilter.week) {
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        return !date.isBefore(
              DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
            ) &&
            !date.isAfter(
              DateTime(
                  endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
            );
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return 0;
    });

    return filtered;
  }

  void _openDetail(TaskModel task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(taskId: task.id),
      ),
    );

    if (result == true) {
      _refreshTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: const AppBottomNav(currentTab: BottomTab.task),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false, // Ẩn mũi tên quay lại
            title: const Text(
              'Danh sách nhiệm vụ',
              style:
                  TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: _buildFilter(),
            ),
            actions: [
              IconButton(
                onPressed: _refreshTasks,
                icon: const Icon(Icons.refresh, color: Colors.black),
              )
            ],
          ),
        ],
        body: FutureBuilder<List<TaskModel>>(
          future: _tasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Lỗi tải dữ liệu:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final tasks = _applyFilter(snapshot.data ?? []);

            if (tasks.isEmpty) {
              return const Center(
                child: Text('Không có công việc nào'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, index) {
                final task = tasks[index];
                return _buildTaskCard(task);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _filterItem('Tất cả', TaskFilter.all),
          const SizedBox(width: 8),
          _filterItem('Hôm nay', TaskFilter.today),
          const SizedBox(width: 8),
          _filterItem('Tuần này', TaskFilter.week),
        ],
      ),
    );
  }

  Widget _filterItem(String text, TaskFilter filter) {
    final active = _currentFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? primaryTeal : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
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
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 28),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'NHIỆM VỤ KHẨN CẤP',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                _statusBadge(task.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(task.title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 6),
            Text(task.description,
                style: TextStyle(fontSize: 14, color: Colors.red.shade700)),
            const SizedBox(height: 16),
            _infoRow(Icons.access_time,
                'Thời gian: ${_formatTaskDateTime(task.startDate)}',
                color: Colors.red.shade700),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _openDetail(task),
                child: const Text('Xử Lý Ngay',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(task.avatarIcon, color: primaryTeal, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                          ),
                          _statusBadge(task.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      _infoRow(Icons.access_time,
                          'Thời gian: ${_formatTaskDateTime(task.startDate)}'),
                      _infoRow(
                          Icons.person_outline, 'Giao bởi: ${task.assignedBy}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _openDetail(task),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text('Xem chi tiết',
                        style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => _openDetail(task),
                    child: const Text('Bắt đầu ngay',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    final c = color ?? Colors.grey.shade600;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: c, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(TaskStatus status) {
    late String text;
    late Color bg;
    late Color fg;

    switch (status) {
      case TaskStatus.doing:
        text = 'ĐANG LÀM';
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      case TaskStatus.pending:
        text = 'CẦN LÀM';
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        break;
      case TaskStatus.completed:
        text = 'HOÀN THÀNH';
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case TaskStatus.urgent:
        text = 'KHẨN CẤP';
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
