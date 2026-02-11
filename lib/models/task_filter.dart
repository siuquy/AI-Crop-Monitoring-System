import 'package:flutter/material.dart';

enum TaskFilter { all, urgent, doing, todo }

class TaskFilterHelper {
  static void show({
    required BuildContext context,
    required TaskFilter current,
    required Function(TaskFilter) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskFilter.values.map((filter) {
            return ListTile(
              title: Text(_label(filter)),
              trailing: current == filter
                  ? const Icon(Icons.check, color: Colors.teal)
                  : null,
              onTap: () {
                onSelected(filter);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  static String _label(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'Tất cả';
      case TaskFilter.urgent:
        return 'Khẩn cấp';
      case TaskFilter.doing:
        return 'Đang thực hiện';
      case TaskFilter.todo:
        return 'Chưa bắt đầu';
    }
  }
}
