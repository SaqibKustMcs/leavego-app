import 'package:leavego_app/models/tasks_response.dart';

class TaskDetailResponse {
  const TaskDetailResponse({required this.success, required this.data});

  final bool success;
  final TaskDetailData data;

  factory TaskDetailResponse.fromJson(Map<String, dynamic> json) {
    return TaskDetailResponse(
      success: json['success'] == true,
      data: TaskDetailData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}

class TaskDetailData {
  const TaskDetailData({
    required this.task,
    required this.comments,
    required this.activityLogs,
    required this.attachments,
  });

  final TaskItem task;
  final List<TaskCommentItem> comments;
  final List<TaskActivityLogItem> activityLogs;
  final List<TaskAttachmentItem> attachments;

  factory TaskDetailData.fromJson(Map<String, dynamic> json) {
    final commentsRaw = json['comments'];
    final activityLogsRaw = json['activity_logs'];
    final attachmentsRaw = json['attachments'];

    return TaskDetailData(
      task: TaskItem.fromJson(json),
      comments: commentsRaw is List
          ? commentsRaw
                .whereType<Map<String, dynamic>>()
                .map(TaskCommentItem.fromJson)
                .toList()
          : <TaskCommentItem>[],
      activityLogs: activityLogsRaw is List
          ? activityLogsRaw
                .whereType<Map<String, dynamic>>()
                .map(TaskActivityLogItem.fromJson)
                .toList()
          : <TaskActivityLogItem>[],
      attachments: attachmentsRaw is List
          ? attachmentsRaw
                .whereType<Map<String, dynamic>>()
                .map(TaskAttachmentItem.fromJson)
                .toList()
          : <TaskAttachmentItem>[],
    );
  }
}

class TaskCommentItem {
  const TaskCommentItem({
    required this.id,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  final int id;
  final String comment;
  final String? createdAt;
  final String? updatedAt;
  final TaskActivityUser? user;

  factory TaskCommentItem.fromJson(Map<String, dynamic> json) {
    return TaskCommentItem(
      id: _toInt(json['id']),
      comment: (json['comment'] ?? json['message'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      user: json['user'] is Map<String, dynamic>
          ? TaskActivityUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TaskActivityLogItem {
  const TaskActivityLogItem({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.event,
    required this.oldValueJson,
    required this.newValueJson,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  final int id;
  final String? taskId;
  final String? userId;
  final String event;
  final Map<String, dynamic>? oldValueJson;
  final Map<String, dynamic>? newValueJson;
  final String? createdAt;
  final String? updatedAt;
  final TaskActivityUser? user;

  factory TaskActivityLogItem.fromJson(Map<String, dynamic> json) {
    return TaskActivityLogItem(
      id: _toInt(json['id']),
      taskId: json['task_id']?.toString(),
      userId: json['user_id']?.toString(),
      event: (json['event'] ?? '').toString(),
      oldValueJson: json['old_value_json'] is Map<String, dynamic>
          ? json['old_value_json'] as Map<String, dynamic>
          : null,
      newValueJson: json['new_value_json'] is Map<String, dynamic>
          ? json['new_value_json'] as Map<String, dynamic>
          : null,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      user: json['user'] is Map<String, dynamic>
          ? TaskActivityUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TaskActivityUser {
  const TaskActivityUser({
    required this.id,
    required this.name,
    required this.email,
  });

  final int id;
  final String name;
  final String email;

  factory TaskActivityUser.fromJson(Map<String, dynamic> json) {
    return TaskActivityUser(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}

class TaskAttachmentItem {
  const TaskAttachmentItem({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.createdAt,
  });

  final int id;
  final String fileName;
  final String? fileUrl;
  final String? createdAt;

  factory TaskAttachmentItem.fromJson(Map<String, dynamic> json) {
    return TaskAttachmentItem(
      id: _toInt(json['id']),
      fileName: (json['file_name'] ?? json['name'] ?? 'Attachment').toString(),
      fileUrl: json['file_url']?.toString() ?? json['url']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
