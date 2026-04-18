import 'api_client.dart';
import '../../models/task_model.dart';

class TaskService {
  static Future<TaskModel> getTaskById(String taskId) async {
    // Tìm công việc trong WorkerSchedules hoặc TaskDetails
    final response = await ApiClient.instance.get('/api/TaskDetails');
    if (response['success'] == true && response['data'] != null) {
      final List data = response['data'];
      final taskData = data.firstWhere(
        (element) =>
            element['taskDetailId'] == taskId || element['taskId'] == taskId,
        orElse: () => null,
      );
      if (taskData != null) {
        return TaskModel.fromJson(taskData);
      }
    }
    throw Exception('Không tìm thấy công việc với ID: $taskId');
  }

  static Future<List<TaskModel>> getTasks({bool forceRefresh = false}) async {
    final response =
        await ApiClient.instance.get('/api/WorkerSchedules/my-schedule');
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => TaskModel.fromJson(json))
          .toList();
    }
    return [];
  }

  static Future<void> updateTaskStatus(String taskId, String status) async {
    await ApiClient.instance.patch(
      '/api/TaskDetails/$taskId/status',
      body: {'status': status},
    );
  }
}
