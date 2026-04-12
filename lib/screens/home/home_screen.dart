import 'package:acmms/screens/home/notification_screen.dart';
import 'package:acmms/screens/task/task_list_screen.dart';
import 'package:acmms/shared/app_bottom_navbar.dart';
import 'package:acmms/shared/bottom_tab.dart';
import 'package:flutter/material.dart';

import '../../core/service/bed_service.dart';
import '../../core/service/crop_service.dart';
import '../../core/service/plot_service.dart';
import '../../core/service/task_service.dart';
import '../../core/service/worker_service.dart';
import '../../core/service/weather_service.dart';
import '../../models/task_model.dart';
import '../../models/worker.dart';

const Color primaryTeal = Color(0xFF4CAF50); // Chuyển sang xanh lá tươi
const Color darkTeal = Color(0xFF388E3C); // Màu xanh lá đậm
const Color bgColor = Color(0xFFF0F8F1); // Màu nền ám xanh nhẹ

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TaskModel> tasks = [];
  bool isLoading = true;
  String? errorMessage;
  Worker? _currentWorker;

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
        WorkerService.getCurrentWorker(),
      ]);

      final data = results[0] as List<TaskModel>;
      final cropMap = results[1] as Map<String, String>;
      final plotMap = results[2] as Map<String, Map<String, dynamic>>;
      final bedMap = results[3] as Map<String, Map<String, dynamic>>;
      final worker = results[4] as Worker;

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
        _currentWorker = worker;
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
        return Colors.blue.shade600; 
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
      body: RefreshIndicator(
        color: primaryTeal,
        onRefresh: () => _loadAll(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 20, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryTeal, darkTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    _Header(worker: _currentWorker),
                    const SizedBox(height: 24),
                    const _WeatherCard(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TaskSummary(todo: todo, doing: doing, done: done),
                    const SizedBox(height: 32),
                    const Text('Nhiệm vụ hôm nay',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 16),
                    _buildTaskList(),
                  ],
                ),
              ),
            ],
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      )),
                  const SizedBox(height: 8),
                  Container(
                      height: 12,
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      )),
                  const SizedBox(height: 8),
                  Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Worker? worker;
  const _Header({this.worker});

  @override
  Widget build(BuildContext context) {
    // Use worker's last name for a more personal greeting. Default to 'bạn'.
    final workerName = worker?.fullName.split(' ').last ?? 'bạn';
    final avatarUrl = worker?.avatarUrl;

    return Row(
      children: [
        CircleAvatar(
          radius: 26, // Tăng kích thước avatar
          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
              ? NetworkImage(avatarUrl)
              : const AssetImage('assets/avatar.png') as ImageProvider,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chào buổi sáng, $workerName!',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_active_outlined,
              color: Colors.white, size: 28),
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

class _WeatherCard extends StatefulWidget {
  const _WeatherCard();

  @override
  State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard> {
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await WeatherService.fetchWeather();
      setState(() {
        _weatherData = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingOrErrorCard(
          const CircularProgressIndicator(color: Colors.white));
    }

    if (_error != null) {
      return _buildLoadingOrErrorCard(
          Text(_error!, style: const TextStyle(color: Colors.white)));
    }

    if (_weatherData == null) {
      return _buildLoadingOrErrorCard(const Text('Không có dữ liệu thời tiết',
          style: TextStyle(color: Colors.white)));
    }

    final temperature = _weatherData!['temperature']?.round() ?? 'N/A';
    final description = _weatherData!['description'] ?? 'Không rõ';
    final humidity = _weatherData!['humidity'] ?? 'N/A';
    final windSpeed = _weatherData!['windSpeed'] ?? 'N/A';
    final iconCode = _weatherData!['icon'] ?? '01d'; // Default icon
    final cityName = _weatherData!['cityName'] ?? 'Vị trí của bạn';

    // OpenWeatherMap icon URL
    final iconUrl = 'https://openweathermap.org/img/wn/$iconCode@2x.png';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Image.network(iconUrl, width: 56, height: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$temperature°C - ${description[0].toUpperCase()}${description.substring(1)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  cityName,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _WeatherInfo(
                  icon: Icons.water_drop, label: 'Độ ẩm', value: '$humidity%'),
              const SizedBox(height: 4),
              _WeatherInfo(
                  icon: Icons.air, label: 'Gió', value: '$windSpeed m/s'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOrErrorCard(Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: SizedBox(
        height: 80, // Chiều cao cố định để tránh nhảy layout
        child: Center(child: content),
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
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
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
        _SummaryItem('Cần làm', '$todo', Colors.orange.shade600,
            Icons.assignment_outlined),
        const SizedBox(width: 12),
        _SummaryItem(
            'Đang làm', '$doing', Colors.blue.shade600, Icons.autorenew),
        const SizedBox(width: 12),
        _SummaryItem(
            'Hoàn thành', '$done', primaryTeal, Icons.check_circle_outline),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryItem(this.title, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600)),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style:
                              const TextStyle(fontSize: 13, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
