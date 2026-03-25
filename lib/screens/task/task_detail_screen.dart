import 'dart:io';
import 'package:acmms/screens/task/scan_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:acmms/models/task_model.dart';
import 'package:acmms/core/service/task_service.dart';
import 'package:acmms/core/service/season_detail_service.dart';
import 'package:acmms/core/service/bed_service.dart';
import 'package:acmms/core/service/plot_service.dart';
import 'package:acmms/core/service/farm_service.dart';
import 'ai_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Future<TaskModel> _taskFuture;
  TaskModel? _task;
  final TextEditingController _updateController = TextEditingController();
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _taskWasModified = false;

  @override
  void initState() {
    super.initState();
    _taskFuture = _loadTaskDetails();
  }

  Future<TaskModel> _loadTaskDetails() async {
    final task = await TaskService.getTaskById(widget.taskId);
    final results = await Future.wait([
      SeasonDetailService.getSeasonDetailMap(),
      BedService.getBedMap(),
      PlotService.getPlotMap(),
      FarmService.getFarmMap(),
    ]);

    final seasonDetailMap = results[0] as Map<String, dynamic>;
    final bedMap = results[1] as Map<String, Map<String, dynamic>>;
    final plotMap = results[2] as Map<String, Map<String, dynamic>>;
    final farmMap = results[3] as Map<String, String>;

    final sd = seasonDetailMap[task.seasonId];
    if (sd != null) {
      task.cropName = sd['cropName'] ?? 'Không rõ';
    } else {
      task.cropName = 'Không rõ';
    }

    final allPlotIds = <String>{};
    allPlotIds.addAll(task.plotIds);
    for (final bedId in task.bedIds) {
      final plotId = bedMap[bedId]?['plotId'] as String?;
      if (plotId != null) {
        allPlotIds.add(plotId);
      }
    }

    final bedNames = task.bedIds
        .map((id) => bedMap[id]?['bedName'] as String?)
        .whereType<String>()
        .toList();
    task.bed = bedNames.join(', ');

    final plotNames = allPlotIds
        .map((id) => plotMap[id]?['plotName'] as String?)
        .whereType<String>()
        .toList();
    task.area = plotNames.join(', ');

    final farmIds = allPlotIds
        .map((plotId) => plotMap[plotId]?['farmId'] as String?)
        .whereType<String>();

    final farmNames = farmIds
        .map((farmId) => farmMap[farmId])
        .whereType<String>()
        .toSet()
        .toList();

    task.field = farmNames.join(', ');

    return task;
  }

  @override
  void dispose() {
    _updateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.of(context).pop(_taskWasModified);
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8F7),
        appBar: AppBar(
          title: const Text('Chi tiết công việc'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
        ),
        body: FutureBuilder<TaskModel>(
          future: _taskFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('Không tìm thấy công việc.'));
            }

            // Use a state variable to allow for mutations.
            if (_task == null || _task!.id != snapshot.data!.id) {
              _task = snapshot.data!;
            }
            final task = _task!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTaskHeader(task),
                  const SizedBox(height: 16),
                  _buildUpdateSection(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskHeader(TaskModel task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTags(task)),
              const SizedBox(width: 12),
              _buildImage(task),
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
          // Hiển thị mô tả công việc
          if (task.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
              child: Text(
                task.description,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ),
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
            value: _formatTaskDuration(task),
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
            controller: _updateController,
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
            onPressed: _showImageSourceActionSheet,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Thêm ảnh hiện trường'),
          ),
          const SizedBox(height: 12),
          _buildImageThumbnails(),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // AI Scan Button
          ElevatedButton.icon(
            onPressed: _scanWithAI,
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Quét bệnh bằng AI'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: const Color(0xFF3A5A40),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
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
          onPressed: _saveUpdate,
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
          onPressed: _markAsCompleted,
          icon: const Icon(Icons.check_circle),
          label: const Text('Đánh dấu hoàn thành'),
        ),
      ],
    );
  }

  Widget _buildImageThumbnails() {
    if (_images.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _images[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _images.removeAt(index);
                        _taskWasModified = true;
                      });
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTags(TaskModel task) {
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

  Widget _buildImage(TaskModel task) {
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

  void _saveUpdate() {
    if (_updateController.text.trim().isEmpty && _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập nội dung hoặc thêm ảnh cập nhật')),
      );
      return;
    }

    _taskWasModified = true;
    // TODO: Implement API call to upload text and images
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã ghi nhận cập nhật')),
    );
    setState(() {
      _updateController.clear();
      _images.clear();
    });
  }

  void _markAsCompleted() {
    if (_task == null) return;
    setState(() {
      _task = _task!.copyWith(status: TaskStatus.completed);
      _taskWasModified = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đánh dấu hoàn thành')),
    );
  }

  String _formatTaskDuration(TaskModel task) {
    if (task.startDate == null) {
      return '${task.timeRange}, ${task.date}';
    }

    String formatDate(DateTime dt) {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }

    final start = formatDate(task.startDate!);
    if (task.endDate == null) {
      return start;
    }

    final end = formatDate(task.endDate!);
    final isSameDay = task.startDate!.year == task.endDate!.year &&
        task.startDate!.month == task.endDate!.month &&
        task.startDate!.day == task.endDate!.day;

    if (isSameDay) return start;

    return 'Từ $start đến $end';
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile == null) return;
    setState(() {
      _images.add(File(pickedFile.path));
      _taskWasModified = true;
    });
  }

  Future<void> _scanWithAI() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Đang phân tích bằng AI..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final result = await AIService.analyzePlantImage(File(pickedFile.path));
      Navigator.of(context).pop(); 

      final bool isHealthy = result['isHealthy'] ?? false;

      if (!mounted) return;

      if (isHealthy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ AI xác nhận: Cây trồng khỏe mạnh.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ScanResultScreen(
            imagePath: pickedFile.path,
            analysisResult: result,
          ),
        ));
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi phân tích: $e')),
      );
    }
  }
}
