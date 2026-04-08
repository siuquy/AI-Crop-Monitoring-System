import 'package:acmms/core/service/season_detail_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:acmms/shared/app_bottom_navbar.dart';
import 'package:acmms/shared/bottom_tab.dart';
import 'package:acmms/models/task_model.dart';
import 'package:acmms/core/service/task_service.dart';
import 'task_detail_screen.dart';
import 'package:acmms/core/service/bed_service.dart';
import 'package:acmms/core/service/plot_service.dart';
import 'package:acmms/core/service/farm_service.dart';

const Color primaryTeal = Color(0xFF1FCFC5);

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

enum TaskFilter { all, today, week }

Future<List<TaskModel>> _loadAll() async {
  final results = await Future.wait([
    TaskService.getTasks(),
    BedService.getBedMap(),
    PlotService.getPlotMap(),
    SeasonDetailService.getSeasonDetailMap(),
    FarmService.getFarmMap(),
  ]);

  final tasks = results[0] as List<TaskModel>;
  final bedMap = results[1] as Map<String, Map<String, dynamic>>;
  final plotMap = results[2] as Map<String, Map<String, dynamic>>;
  final seasonDetailMap = results[3] as Map<String, dynamic>;
  final farmMap = results[4] as Map<String, String>;

  for (var t in tasks) {
    final sd = seasonDetailMap[t.seasonId];

    if (sd != null) {
      t.cropName = sd['cropName'] ?? 'Không rõ';
    } else {
      t.cropName = 'Không rõ';
    }

    final allPlotIds = <String>{};
    allPlotIds.addAll(t.plotIds);
    for (final bedId in t.bedIds) {
      final plotId = bedMap[bedId]?['plotId']?.toString();
      if (plotId != null) {
        allPlotIds.add(plotId);
      }
    }

    final bedNames = t.bedIds
        .map((id) => bedMap[id]?['bedName'] as String?)
        .whereType<String>()
        .toList();
    t.bed = bedNames.join(', ');

    final plotNames = allPlotIds
        .map((id) => plotMap[id]?['plotName'] as String?)
        .whereType<String>()
        .toList();
    t.area = plotNames.join(', ');

    final farmIds = allPlotIds
        .map((plotId) => plotMap[plotId]?['farmId']?.toString())
        .whereType<String>();

    final farmNames = farmIds
        .map((farmId) => farmMap[farmId])
        .whereType<String>()
        .toSet()
        .toList();

    t.field = farmNames.join(', ');
  }

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
    setState(() {
      _tasksFuture = _loadAll();
    });
  }

  List<TaskModel> _applyFilter(List<TaskModel> tasks) {
    List<TaskModel> filtered = tasks.where((task) {
      if (_currentFilter == TaskFilter.all) return true;

      final date = task.taskScheduledAt?.toLocal();
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
      backgroundColor: const Color(0xFFF6F8F7),
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
              style: TextStyle(color: Colors.black),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
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
          border: const Border(
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
            const Text(
              '⚠ KHẨN CẤP',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              task.description,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.play_circle_outline,
                'Bắt đầu: ${_formatTaskDateTime(task.taskScheduledAt)}'),
            if (task.field.isNotEmpty)
              _infoRow(Icons.business, 'Trang trại: ${task.field}'),
            if (task.area.isNotEmpty)
              _infoRow(Icons.map_outlined, 'Khu/Ruộng: ${task.area}'),
            if (task.bed.isNotEmpty)
              _infoRow(Icons.view_day_outlined, 'Luống: ${task.bed}'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
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
                            child: Text(
                              task.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          _statusBadge(task.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _infoRow(Icons.play_circle_outline,
                          'Bắt đầu: ${_formatTaskDateTime(task.taskScheduledAt)}'),
                      if (task.field.isNotEmpty)
                        _infoRow(Icons.business, 'Trang trại: ${task.field}'),
                      if (task.area.isNotEmpty)
                        _infoRow(Icons.map_outlined, 'Khu/Ruộng: ${task.area}'),
                      if (task.bed.isNotEmpty)
                        _infoRow(Icons.view_day_outlined, 'Luống: ${task.bed}'),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                    ),
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
    late Color fg;

    switch (status) {
      case TaskStatus.doing:
        text = 'ĐANG THỰC HIỆN';
        bg = Colors.blue.shade50;
        fg = Colors.blue;
        break;
      case TaskStatus.pending:
        text = 'CHƯA BẮT ĐẦU';
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        break;
      case TaskStatus.completed:
        text = 'HOÀN THÀNH';
        bg = Colors.green.shade50;
        fg = Colors.green;
        break;
      case TaskStatus.urgent:
        text = 'KHẨN CẤP';
        bg = Colors.red.shade50;
        fg = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
