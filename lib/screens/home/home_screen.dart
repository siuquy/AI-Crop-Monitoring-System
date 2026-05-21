import 'package:acmms/screens/home/notification_screen.dart';
import 'package:acmms/shared/app_bottom_navbar.dart';
import 'package:acmms/shared/bottom_tab.dart';
import 'package:flutter/material.dart';

import '../../core/service/task_service.dart';
import '../../screens/task/task_detail_screen.dart';
import '../../core/service/worker_service.dart';
import '../../core/service/farm_service.dart';
import '../../core/service/weather_service.dart';
import '../../models/task_model.dart';
import '../../models/worker.dart';
import 'harvest_screen.dart';
import 'growth_tracking_screen.dart';

const Color primaryTeal = Color(0xFF10B981); // Mint Green
const Color darkTeal = Color(0xFF059669);
const Color bgColor = Color(0xFFF8FAFC); // Clean light slate
const Color surfaceColor = Colors.white;
const Color textPrimary = Color(0xFF1E293B);
const Color textSecondary = Color(0xFF64748B);

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

  Map<String, String> _farmMap = {};
  String? _selectedFarmId;
  String? _selectedFarmName;

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
        WorkerService.getCurrentWorker(),
        FarmService.getFarmMap(),
      ]);

      final data = results[0] as List<TaskModel>;
      final worker = results[1] as Worker;
      final farmMap = results[2] as Map<String, String>;

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
        _farmMap = farmMap;
        if (_farmMap.isNotEmpty && _selectedFarmId == null) {
          _selectedFarmId = _farmMap.keys.first;
          _selectedFarmName = _farmMap.values.first;
        }
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

  void _showFarmPicker() {
    if (_farmMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có dữ liệu trang trại')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Chọn trang trại',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _farmMap.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 20, endIndent: 20),
                  itemBuilder: (context, index) {
                    final key = _farmMap.keys.elementAt(index);
                    final value = _farmMap.values.elementAt(index);
                    final isSelected = key == _selectedFarmId;
                    return ListTile(
                      title: Text(
                        value,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? primaryTeal : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: primaryTeal)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedFarmId = key;
                          _selectedFarmName = value;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
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
                    20, MediaQuery.of(context).padding.top + 24, 20, 32),
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
                    _Header(
                      worker: _currentWorker,
                      farmName: _selectedFarmName,
                      onAvatarTap: _showFarmPicker,
                    ),
                    const SizedBox(height: 24),
                    _WeatherCard(farmId: _selectedFarmId),
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
                    const SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const GrowthTrackingScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.spoke_rounded,
                                  color: Colors.blue.shade700,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Theo dõi sinh trưởng',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text('Kiểm tra tiến độ và tình trạng cây',
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HarvestScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryTeal.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  color: primaryTeal,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Báo cáo Thu hoạch',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text('Ghi nhận sản lượng nông sản',
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
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
          time: t.timeRange,
          status: _mapStatus(t.status),
          color: _mapColor(t.status),
          icon: t.avatarIcon,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t.id)),
            );
            if (result == true) {
              _loadAll(forceRefresh: true);
            }
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
  final String? farmName;
  final VoidCallback? onAvatarTap;
  const _Header({this.worker, this.farmName, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    // Use worker's last name for a more personal greeting. Default to 'bạn'.
    final workerName = worker?.fullName.split(' ').last ?? 'bạn';
    final avatarUrl = worker?.avatarUrl;

    return Row(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: CircleAvatar(
            radius: 26, // Tăng kích thước avatar
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : const AssetImage('assets/avatar.png') as ImageProvider,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chào buổi sáng, $workerName!',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              if (farmName != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        farmName!,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                      const Icon(Icons.arrow_drop_down,
                          color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ],
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
  final String? farmId;
  const _WeatherCard({this.farmId});

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

  @override
  void didUpdateWidget(covariant _WeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Gọi lại API nếu Worker đổi lựa chọn farmId
    if (oldWidget.farmId != widget.farmId) {
      _fetchWeather();
    }
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Gọi API Weather kết hợp với farmId
      final data = await WeatherService.fetchWeather(farmId: widget.farmId);
      if (mounted) {
        setState(() {
          _weatherData = data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    final windSpeed = _weatherData!['windSpeed'] is num
        ? (_weatherData!['windSpeed'] as num).toStringAsFixed(1)
        : _weatherData!['windSpeed'] ?? 'N/A';
    final iconUrl = _weatherData!['icon'] ??
        'https://cdn.weatherapi.com/weather/64x64/day/113.png';
    final cityName = _weatherData!['cityName'] ?? 'Vị trí của bạn';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
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
  final String time;
  final String status;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _TaskItem({
    required this.title,
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
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textPrimary)),
                  const SizedBox(height: 6),
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
