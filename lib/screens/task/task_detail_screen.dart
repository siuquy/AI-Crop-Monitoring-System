import 'dart:io';
import 'package:acmms/core/service/api_client.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:acmms/models/task_model.dart';
import 'package:acmms/core/service/task_service.dart';
import 'package:acmms/core/service/season_detail_service.dart';
import 'package:acmms/core/service/bed_service.dart';
import 'package:acmms/core/service/plot_service.dart';
import 'package:acmms/core/service/farm_service.dart';

const Color primaryTeal = Color(0xFF4CAF50); 
const Color darkTeal = Color(0xFF388E3C); 
const Color bgColor = Color(0xFFF0F8F1); 

class TaskDisplayData {
  final TaskModel task;
  final String cropName;
  final String farmName;
  final String plotName;
  final String bedName;

  TaskDisplayData(
      {required this.task,
      required this.cropName,
      required this.farmName,
      required this.plotName,
      required this.bedName});
}

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
  late Future<TaskDisplayData> _taskDisplayFuture;
  TaskModel? _task;
  final TextEditingController _updateController = TextEditingController();
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _taskWasModified = false;

  // Store loaded data in state to be accessible by other methods like _scanWithAI
  Map<String, dynamic> _seasonDetailMap = {};
  Map<String, Map<String, dynamic>> _bedMap = {};
  Map<String, Map<String, dynamic>> _plotMap = {};
  Map<String, String> _farmMap = {};

  @override
  void initState() {
    super.initState();
    _taskDisplayFuture = _loadAndProcessTaskDetails();
  }

  /// This is the new, robust method to load and process all data needed for the screen.
  Future<TaskDisplayData> _loadAndProcessTaskDetails() async {
    try {
      // Step 1: Fetch all required data in parallel for performance.
      final results = await Future.wait([
        TaskService.getTaskById(widget.taskId),
        SeasonDetailService.getSeasonDetailMap(),
        BedService.getBedMap(),
        PlotService.getPlotMap(),
        FarmService.getFarmMap(),
      ], eagerError: true); // Stop immediately if any API call fails.

      // Step 2: Safely extract and cast results.
      final initialTask = results[0] as TaskModel;
      _seasonDetailMap = results[1] as Map<String, dynamic>;
      _bedMap = results[2] as Map<String, Map<String, dynamic>>;
      _plotMap = results[3] as Map<String, Map<String, dynamic>>;
      _farmMap = results[4] as Map<String, String>;

      // Step 3: Process and resolve names from IDs. This logic is now centralized and safer.
      final sd = _seasonDetailMap[initialTask.seasonId];
      final cropName = sd?['cropName']?.toString() ?? 'Không rõ';

      // Find the first valid location chain (Bed -> Plot -> Farm)
      String bedName = 'Không rõ';
      String plotName = 'Không rõ';
      String farmName = 'Không rõ';

      for (final bedId in initialTask.bedIds) {
        final bedData = _bedMap[bedId];
        if (bedData == null) continue;

        final currentPlotId = bedData['plotId']?.toString();
        final plotData = _plotMap[currentPlotId];
        if (plotData == null) continue;

        final currentFarmId = plotData['farmId']?.toString();
        final currentFarmName = _farmMap[currentFarmId];
        if (currentFarmName == null) continue;

        // Found a complete, valid location chain.
        bedName = bedData['bedName']?.toString() ?? 'Không rõ';
        plotName = plotData['plotName']?.toString() ?? 'Không rõ';
        farmName = currentFarmName;
        break; // Stop at the first valid location.
      }

      // Step 4: Return a clean, ready-to-use data object.
      return TaskDisplayData(
        task: initialTask,
        cropName: cropName,
        farmName: farmName,
        plotName: plotName,
        bedName: bedName,
      );
    } on ApiException {
      rethrow; // Re-throw API exceptions to be handled by FutureBuilder.
    } catch (e, stacktrace) {
      // Catch other errors (casting, null pointers) and provide a clear message.
      debugPrint('[TaskDetailScreen] Lỗi xử lý dữ liệu: $e');
      debugPrint(stacktrace.toString());
      throw ApiException(
          'Lỗi xử lý dữ liệu công việc. Vui lòng kiểm tra dữ liệu từ API.');
    }
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
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text('Chi tiết nhiệm vụ',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: FutureBuilder<TaskDisplayData>(
          future: _taskDisplayFuture,
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
            if (_task == null || _task!.id != snapshot.data!.task.id) {
              _task = snapshot.data!.task;
            }
            final displayData = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTaskHeader(displayData),
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

  Widget _buildTaskHeader(TaskDisplayData displayData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Icon(displayData.task.avatarIcon,
                    color: primaryTeal, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTags(displayData.task)),
                        _buildStatusBadge(displayData.task.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayData.task.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Hiển thị mô tả công việc
          if (displayData.task.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
              child: Text(
                displayData.task.description,
                style: TextStyle(
                    color: Colors.grey.shade700, fontSize: 15, height: 1.4),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Loại cây: ${displayData.cropName} – Mùa vụ: ${displayData.task.season}',
            style: TextStyle(
                color: primaryTeal, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _infoRow(
            icon: Icons.location_on_outlined,
            title: 'Địa điểm',
            value:
                '${displayData.farmName} - ${displayData.plotName} - ${displayData.bedName}',
          ),
          _infoRow(
            icon: Icons.access_time,
            title: 'Thời gian dự kiến',
            value: _formatTaskDuration(displayData.task),
          ),
          _infoRow(
            icon: Icons.person_outline,
            title: 'Người giao việc',
            value:
                '${displayData.task.assignedBy} – ${displayData.task.assignedRole}',
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
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _updateController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ví dụ: đã phun xong 2 luống đầu...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _showImageSourceActionSheet,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Thêm ảnh hiện trường',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryTeal,
              side: const BorderSide(color: primaryTeal, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          _buildImageThumbnails(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56), // Nút to hơn
            backgroundColor:
                Colors.blue.shade600, // Đổi màu để phân biệt với nút Hoàn thành
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          onPressed: _saveUpdate,
          icon: const Icon(Icons.save),
          label: const Text('Ghi nhận cập nhật',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: primaryTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          onPressed: _markAsCompleted,
          icon: const Icon(Icons.check_circle),
          label: const Text('Đánh dấu hoàn thành',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        _chip(task.taskType, primaryTeal),
        if (task.isUrgent) _chip('Khẩn cấp', Colors.red),
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
          Icon(icon, color: primaryTeal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.black87,
                    fontSize: 15,
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
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(TaskStatus status) {
    String text;
    Color bg;
    Color fg;
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
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
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
      _task!.status = TaskStatus.completed;
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
}
