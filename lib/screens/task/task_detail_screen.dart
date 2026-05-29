import 'dart:io';
import 'package:acmms/core/service/api_client.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:acmms/models/task_model.dart';
import 'package:acmms/core/service/task_service.dart';
import 'package:acmms/core/service/season_service.dart';
import 'package:acmms/core/service/bed_service.dart';
import 'package:acmms/core/service/plot_service.dart';
import 'package:acmms/core/service/farm_service.dart';
import 'package:acmms/core/service/plant_service.dart';
import 'package:acmms/screens/report/create_report_screen.dart';

import '../report/iot_info_card.dart';

const Color primaryTeal = Color(0xFF10B981);
const Color darkTeal = Color(0xFF059669);
const Color bgColor = Color(0xFFF8FAFC);
const Color surfaceColor = Colors.white;
const Color textPrimary = Color(0xFF1E293B);
const Color textSecondary = Color(0xFF64748B);

class TaskDisplayData {
  final TaskModel task;
  final String cropName;
  final String seasonName;
  final String farmName;
  final String plotName;
  final String bedName;

  TaskDisplayData(
      {required this.task,
      required this.cropName,
      required this.seasonName,
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
  bool _isUpdatingStatus = false;

  Map<String, Map<String, dynamic>> _seasonMap = {};
  Map<String, Map<String, dynamic>> _bedMap = {};
  Map<String, Map<String, dynamic>> _plotMap = {};
  Map<String, String> _farmMap = {};

  @override
  void initState() {
    super.initState();
    _taskDisplayFuture = _loadAndProcessTaskDetails();
  }

  Future<TaskDisplayData> _loadAndProcessTaskDetails() async {
    debugPrint(
        '[TaskDetailScreen] Loading and processing task details for ID: ${widget.taskId}');
    try {
      final results = await Future.wait([
        TaskService.getTaskById(widget.taskId),
        SeasonService.getSeasonMap(),
        BedService.getBedMap(),
        PlotService.getPlotMap(),
        FarmService.getFarmMap(),
      ], eagerError: true);

      final initialTask = results[0] as TaskModel;
      debugPrint(
          '[TaskDetailScreen] Initial Task fetched: ID=${initialTask.id}, Status=${initialTask.status}, Description=${initialTask.description}, BedIds=${initialTask.bedIds}, PlotIds=${initialTask.plotIds}, TimeRange=${initialTask.timeRange}');
      _seasonMap = results[1] as Map<String, Map<String, dynamic>>;
      _bedMap = results[2] as Map<String, Map<String, dynamic>>;
      _plotMap = results[3] as Map<String, Map<String, dynamic>>;
      _farmMap = results[4] as Map<String, String>;

      final safeSeasonMap = {
        for (var e in _seasonMap.entries) e.key.toLowerCase(): e.value
      };
      final safeBedMap = {
        for (var e in _bedMap.entries) e.key.toLowerCase(): e.value
      };
      final safePlotMap = {
        for (var e in _plotMap.entries) e.key.toLowerCase(): e.value
      };
      final safeFarmMap = {
        for (var e in _farmMap.entries) e.key.toLowerCase(): e.value
      };

      // Step 3: Process and resolve names from IDs. This logic is now centralized and safer.
      final seasonInfo = safeSeasonMap[initialTask.seasonId.toLowerCase()];
      final seasonName = seasonInfo?['seasonName']?.toString() ??
          (initialTask.season.isNotEmpty ? initialTask.season : 'Không rõ');
      final cropName = seasonInfo?['plantName']?.toString() ??
          seasonInfo?['cropName']?.toString() ??
          'Không rõ';

      String bedName = 'Không rõ';
      String plotName = 'Không rõ';
      String farmName = 'Không rõ';

      if (initialTask.bedIds.isNotEmpty) {
        final bedNames = initialTask.bedIds
            .map((bedId) {
              final bedData = safeBedMap[bedId.toLowerCase()];
              return bedData?['bedName']?.toString();
            })
            .where((name) => name != null && name.isNotEmpty)
            .toList();

        if (bedNames.isNotEmpty) {
          bedName = bedNames.join(', ');
        }

        // Lấy thông tin plot và farm từ bed đầu tiên (giả định tất cả beds trong 1 task thuộc cùng plot/farm)
        final firstBedId = initialTask.bedIds.first;
        final firstBedData = safeBedMap[firstBedId.toLowerCase()];
        if (firstBedData != null) {
          final currentPlotId = firstBedData['plotId']?.toString();
          final plotData = safePlotMap[currentPlotId?.toLowerCase() ?? ''];
          if (plotData != null) {
            plotName = plotData['plotName']?.toString() ?? 'Không rõ';

            final currentFarmId = plotData['farmId']?.toString();
            final currentFarmName =
                safeFarmMap[currentFarmId?.toLowerCase() ?? ''];
            if (currentFarmName != null) {
              farmName = currentFarmName;
            }
          }
        }
      } else if (initialTask.plotIds.isNotEmpty) {
        // Nếu không có bedIds nhưng có plotIds, cố gắng giải quyết tên từ plot đầu tiên
        final plotId = initialTask.plotIds.first;
        final plotData = safePlotMap[plotId.toLowerCase()];
        if (plotData != null) {
          plotName = plotData['plotName']?.toString() ?? 'Không rõ';

          final currentFarmId = plotData['farmId']?.toString();
          final currentFarmName =
              safeFarmMap[currentFarmId?.toLowerCase() ?? ''];
          if (currentFarmName != null) {
            farmName = currentFarmName;
          }
        }
      } else if (initialTask.seasonId.isNotEmpty) {
        // Nếu không có plotIds nhưng có seasonId, cố gắng giải quyết tên từ season
        final seasonInfo = safeSeasonMap[initialTask.seasonId.toLowerCase()];
        if (seasonInfo != null) {
          final currentFarmId = seasonInfo['farmId']?.toString();
          final currentFarmName =
              safeFarmMap[currentFarmId?.toLowerCase() ?? ''];
          if (currentFarmName != null) {
            farmName = currentFarmName;
          }
        }
      }

      debugPrint(
          '[TaskDetailScreen] Resolved Location: Farm=$farmName, Plot=$plotName, Bed=$bedName');
      // Step 4: Return a clean, ready-to-use data object.
      return TaskDisplayData(
        task: initialTask,
        cropName: cropName,
        seasonName: seasonName,
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop(_taskWasModified);
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text('Chi tiết nhiệm vụ',
              style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.black87, size: 20),
            onPressed: () => Navigator.of(context).pop(_taskWasModified),
          ),
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
                  // Chỉ hiển thị IotInfoCard nếu có bedIds và bedId đầu tiên hợp lệ
                  if (displayData.task.bedIds.isNotEmpty &&
                      displayData.task.bedIds.first.isNotEmpty) ...[
                    IotInfoCard(bedId: displayData.task.bedIds.first),
                    const SizedBox(height: 16),
                  ],
                  _buildUpdateSection(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
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
          // Hiển thị mô tả công việc (ghi chú)
          if (displayData.task.description.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.edit_note, color: Colors.amber.shade800, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ghi chú từ quản lý',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          displayData.task.description,
                          style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 14,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Mùa vụ: ${displayData.seasonName}',
            style: TextStyle(
                color: primaryTeal, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Chỉ hiển thị thông tin địa điểm nếu có dữ liệu hợp lệ
          if (displayData.farmName != 'Không rõ' ||
              displayData.plotName != 'Không rõ' ||
              displayData.bedName != 'Không rõ')
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
        ],
      ),
    );
  }

  Widget _buildUpdateSection() {
    final bool isCompleted = _task?.status == TaskStatus.completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCompleted ? 'Công việc đã chốt' : 'Cập nhật công việc hôm nay',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _updateController,
            maxLines: 3,
            readOnly: isCompleted,
            decoration: InputDecoration(
              hintText: isCompleted
                  ? 'Không thể cập nhật công việc đã hoàn thành.'
                  : 'Ví dụ: đã phun xong 2 luống đầu...',
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
          if (!isCompleted) ...[
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
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildImageThumbnails(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool isCompleted = _task?.status == TaskStatus.completed;

    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56), // Nút to hơn
            backgroundColor: isCompleted
                ? Colors.grey.shade400
                : Colors
                    .blue.shade600, // Đổi màu để phân biệt với nút Hoàn thành
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          onPressed: isCompleted || _isUpdatingStatus ? null : _saveUpdate,
          icon: const Icon(Icons.save),
          label: const Text('Ghi nhận cập nhật',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: isCompleted ? Colors.grey : primaryTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          onPressed: isCompleted || _isUpdatingStatus ? null : _markAsCompleted,
          icon: _isUpdatingStatus
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle),
          label: Text(
              isCompleted
                  ? 'Đã hoàn thành'
                  : (_isUpdatingStatus
                      ? 'Đang cập nhật...'
                      : 'Đánh dấu hoàn thành'),
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
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 12,
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

  Future<void> _markAsCompleted() async {
    if (_task == null) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await TaskService.updateTaskStatus(_task!.id, 'Completed');

      setState(() {
        _task!.status = TaskStatus.completed;
        _taskWasModified = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu hoàn thành')),
        );
        debugPrint('[TaskDetailScreen] Popping with true after completion.');
        // Pop immediately to refresh the previous screen and improve UX
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  String _formatTaskDuration(TaskModel task) {
    // task.startDate sẽ không bao giờ null vì đã được gán DateTime.now() nếu API trả về null
    String formatDate(DateTime dt) {
      final localDt = dt.toLocal();
      return '${localDt.day.toString().padLeft(2, '0')}/${localDt.month.toString().padLeft(2, '0')}/${localDt.year}';
    }

    if (task.startDate == null) {
      return 'Chưa xác định';
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
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (pickedFile == null) return;
    setState(() {
      _images.add(File(pickedFile.path));
      _taskWasModified = true;
    });
  }
}
