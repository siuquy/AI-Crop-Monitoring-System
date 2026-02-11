import 'package:acmms/screens/home/notification_screen.dart';
import 'package:acmms/screens/task/task_list_screen.dart';
import 'package:acmms/shared/app_bottom_navbar.dart';
import 'package:acmms/shared/bottom_tab.dart';
import 'package:acmms/core/service/service.dart';
import 'package:flutter/material.dart';

const Color primaryTeal = Color(0xFF1FCFC5);
const Color darkTeal = Color(0xFF14B8B0);
const Color bgColor = Color(0xFFF6F8F7);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(),
                  SizedBox(height: 16),
                  _WeatherCard(),
                  SizedBox(height: 20),
                  _TaskSummary(),
                  SizedBox(height: 20),
                  Text(
                    'Nhiệm vụ hôm nay',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  _TaskItem(
                    title: 'Tưới nước Khu C',
                    location: 'Khu C - Luống 2',
                    time: '08:00 - 09:30',
                    status: 'Đang làm',
                    color: primaryTeal,
                    icon: Icons.water_drop,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TaskListScreen()),
                      );
                    },
                  ),
                  _TaskItem(
                    title: 'Kiểm tra sâu bệnh',
                    location: 'Nhà kính B - Dãy 4',
                    time: '10:00 - 11:30',
                    status: 'Cần làm',
                    color: Colors.orange,
                    icon: Icons.bug_report,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TaskListScreen()),
                      );
                    },
                  ),
                  _TaskItem(
                    title: 'Bón phân hữu cơ',
                    location: 'Khu A - Luống 5',
                    time: '14:00 - 16:00',
                    status: 'Cần làm',
                    color: Colors.deepOrange,
                    icon: Icons.eco,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TaskListScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(
        currentTab: BottomTab.home,
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
              MaterialPageRoute(
                builder: (_) => const NotificationScreen(),
              ),
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
  final WeatherService _weatherService = WeatherService();

  double? temp;
  String? description;
  int? humidity;
  double? windSpeed;

  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final data = await _weatherService.getWeather(
        lat: 10.8231,
        lon: 106.6297,
      );

      if (!mounted) return;

      setState(() {
        temp = (data['main']['temp'] as num).toDouble();
        description = data['weather'][0]['description'];
        humidity = data['main']['humidity'];
        windSpeed = (data['wind']['speed'] as num).toDouble();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _loading();
    if (hasError) return _error();
    return _content();
  }

  Widget _content() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thời tiết hôm nay',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${temp!.round()}°C',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  description!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: darkTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud,
                  size: 26,
                  color: primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _WeatherInfo(
                icon: Icons.water_drop,
                label: 'Độ ẩm',
                value: '$humidity%',
              ),
              const SizedBox(width: 20),
              _WeatherInfo(
                icon: Icons.air,
                label: 'Gió',
                value: '${(windSpeed! * 3.6).toStringAsFixed(1)} km/h',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loading() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: primaryTeal,
        ),
      ),
    );
  }

  Widget _error() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('Không thể tải dữ liệu thời tiết'),
        ],
      ),
    );
  }
}

class _TaskSummary extends StatelessWidget {
  const _TaskSummary();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Tóm tắt công việc hôm nay',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TaskListScreen(),
                  ),
                );
              },
              child: const Text(
                'Xem tất cả',
                style: TextStyle(color: primaryTeal, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            _SummaryItem(title: 'Cần làm', value: '3', color: Colors.orange),
            _SummaryItem(
                title: 'Đang thực hiện', value: '1', color: primaryTeal),
            _SummaryItem(title: 'Hoàn thành', value: '0', color: Colors.green),
          ],
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(bottom: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
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
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
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
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
