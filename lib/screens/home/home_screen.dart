import 'package:acmms/screens/home/notification_screen.dart';
import 'package:acmms/screens/task/task_list_screen.dart';
import 'package:acmms/shared/app_bottom_navbar.dart';
import 'package:acmms/shared/bottom_tab.dart';
import 'package:flutter/material.dart';

import '../../core/service/bed_service.dart';
import '../../core/service/crop_service.dart';
import '../../core/service/plot_service.dart';
import '../../core/service/task_service.dart';
import '../../models/task_model.dart';

const Color primaryTeal = Color(0xFF1FCFC5);
const Color darkTeal = Color(0xFF14B8B0);
const Color bgColor = Color(0xFFF6F8F7);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TaskModel> tasks = [];
  bool isLoading = true;
  String? errorMessage;

  int todo = 0;
  int doing = 0;
  int done = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        TaskService.getTasks(forceRefresh: forceRefresh),
        CropService.getCropMap(),
        PlotService.getPlotMap(),
        BedService.getBedMap(),
      ]);

      final data = results[0] as List<TaskModel>;
      final cropMap = results[1] as Map<String, String>;
      final plotMap = results[2] as Map<String, Map<String, dynamic>>;
      final bedMap = results[3] as Map<String, Map<String, dynamic>>;

      for (final task in data) {
        final bedInfo = bedMap[task.bed];
        if (bedInfo != null) {
          task.bed = bedInfo['bedName']?.toString() ?? task.bed;
          final plotId = bedInfo['plotId']?.toString() ?? '';
          final plotInfo = plotMap[plotId];
          if (plotInfo != null) {
            task.area = plotInfo['plotName']?.toString() ?? task.area;
            task.field = plotInfo['farmName']?.toString() ?? task.field;
          }
        }
        final cropId = task.cropName;
        if (cropMap.containsKey(cropId)) {
          task.cropName = cropMap[cropId]!;
        }
      }

      final todoCount =
          data.where((e) => e.status == TaskStatus.pending).length;
      final doingCount = data.where((e) => e.status == TaskStatus.doing).length;
      final doneCount =
          data.where((e) => e.status == TaskStatus.completed).length;

      if (!mounted) return;
      setState(() {
        tasks = data;
        todo = todoCount;
        doing = doingCount;
        done = doneCount;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  String _mapStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.doing:
        return 'Đang làm';
      case TaskStatus.completed:
        return 'Hoàn thành';
      case TaskStatus.urgent:
        return 'Khẩn cấp';
      default:
        return 'Cần làm';
    }
  }

  Color _mapColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.doing:
        return primaryTeal;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.urgent:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _buildLocation(TaskModel t) {
    final parts = [t.field, t.area, t.bed]
        .where((e) => e.isNotEmpty && e != 'Chưa có dữ liệu')
        .toList();
    return parts.isEmpty ? 'Chưa có dữ liệu' : parts.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryTeal,
          onRefresh: () => _loadAll(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(),
                const SizedBox(height: 16),

                const _WeatherCard(),
                const SizedBox(height: 20),

                _TaskSummary(todo: todo, doing: doing, done: done),
                const SizedBox(height: 20),

                const Text(
                  'Nhiệm vụ hôm nay',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // TASK LIST
                _buildTaskList(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentTab: BottomTab.home),
    );
  }

  Widget _buildTaskList() {
    if (isLoading) {
      return Column(
        children: List.generate(3, (_) => const _TaskItemSkeleton()),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.wifi_off, color: Colors.grey, size: 40),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _loadAll(forceRefresh: true),
              icon: const Icon(Icons.refresh, color: primaryTeal),
              label:
                  const Text('Thử lại', style: TextStyle(color: primaryTeal)),
            ),
          ],
        ),
      );
    }

    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          'Không có nhiệm vụ nào hôm nay',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: tasks.take(3).map((t) {
        return _TaskItem(
          title: t.title,
          location: _buildLocation(t),
          time: t.timeRange,
          status: _mapStatus(t.status),
          color: _mapColor(t.status),
          icon: t.avatarIcon,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TaskListScreen()),
            );
          },
        );
      }).toList(),
    );
  }
}

class _TaskItemSkeleton extends StatefulWidget {
  const _TaskItemSkeleton();

  @override
  State<_TaskItemSkeleton> createState() => _TaskItemSkeletonState();
}

class _TaskItemSkeletonState extends State<_TaskItemSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      )),
                  const SizedBox(height: 8),
                  Container(
                      height: 12,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      )),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 70,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundImage: AssetImage('assets/avatar.png'),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chào buổi sáng, Minh!',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'TP. Hồ Chí Minh, District 6',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryTeal, darkTeal]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: const [
          Icon(Icons.wb_sunny, color: Colors.white, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '28°C - Nắng nhẹ\nThời tiết thuận lợi',
              style: TextStyle(color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _WeatherInfo(
                  icon: Icons.water_drop, label: 'Độ ẩm', value: '65%'),
              SizedBox(height: 4),
              _WeatherInfo(icon: Icons.air, label: 'Gió', value: '5 km/h'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text('$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

class _TaskSummary extends StatelessWidget {
  final int todo;
  final int doing;
  final int done;

  const _TaskSummary({
    required this.todo,
    required this.doing,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryItem('Cần làm', '$todo', Colors.orange),
        _SummaryItem('Đang làm', '$doing', primaryTeal),
        _SummaryItem('Hoàn thành', '$done', Colors.green),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryItem(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(bottom: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String title;
  final String location;
  final String time;
  final String status;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _TaskItem({
    required this.title,
    required this.location,
    required this.time,
    required this.status,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '$location • $time',
                    style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
