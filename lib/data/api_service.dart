import 'package:leavego_app/data/data_service.dart';
import 'package:leavego_app/models/apply_leave_response.dart';
import 'package:leavego_app/models/dashboard_response.dart';
import 'package:leavego_app/models/leave_type_response.dart';
import 'package:leavego_app/models/login_response.dart';
import 'package:leavego_app/models/leave_detail_response.dart';
import 'package:leavego_app/models/logout_response.dart';
import 'package:leavego_app/models/my_leaves_response.dart';
import 'package:leavego_app/models/me_response.dart';
import 'package:leavego_app/models/notifications_response.dart';
import 'package:leavego_app/models/create_task_response.dart';
import 'package:leavego_app/models/departments_response.dart';
import 'package:leavego_app/models/task_action_response.dart';
import 'package:leavego_app/models/task_detail_response.dart';
import 'package:leavego_app/models/tasks_response.dart';
import 'package:leavego_app/models/users_response.dart';
import 'package:leavego_app/models/supporting_tasks_response.dart';

class ApiService {
  ApiService(this._dataService);

  static const String baseUrl = 'https://office.friendselectronics.com/api/v1';
  final DataService _dataService;

  Future<LoginResponse> login({required String email, required String password}) async {
    final result = await _dataService.post(
      url: '$baseUrl/auth/login',
      body: <String, dynamic>{'email': email, 'password': password},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Login failed ($statusCode)');
    }

    final response = LoginResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(response.message.isNotEmpty ? response.message : 'Login failed');
    }
    if (response.data.token.isEmpty) {
      throw Exception('Token not found in login response');
    }
    return response;
  }

  Future<DashboardData> dashboard({required String token}) async {
    final result = await _dataService.get(
      url: '$baseUrl/dashboard',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load dashboard');
    }

    final response = DashboardResponse.fromJson(payload);
    if (!response.success) {
      throw Exception('Failed to load dashboard');
    }

    return response.data;
  }

  Future<MeData> me({required String token}) async {
    final result = await _dataService.get(
      url: '$baseUrl/auth/me',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load profile');
    }

    final response = MeResponse.fromJson(payload);
    if (!response.success) {
      throw Exception('Failed to load profile');
    }

    return response.data;
  }

  Future<List<LeaveTypeItem>> leaveTypes({required String token}) async {
    final result = await _dataService.get(
      url: '$baseUrl/leave-types',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load leave types');
    }

    final response = LeaveTypeResponse.fromJson(payload);
    if (!response.success) {
      throw Exception('Failed to load leave types');
    }

    return response.data;
  }

  Future<ApplyLeaveResponse> applyLeave({
    required String token,
    required String userId,
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? attachmentPath,
  }) async {
    final result = await _dataService.postMultipart(
      url: '$baseUrl/leaves',
      fields: <String, String>{
        'user_id': userId,
        'leave_type_id': leaveTypeId,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
      },
      filePath: attachmentPath,
      fileFieldName: 'attachment',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to apply leave');
    }

    final response = ApplyLeaveResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(response.message.isNotEmpty ? response.message : 'Failed to apply leave');
    }
    return response;
  }

  Future<MyLeavesPageData> myLeaves({required String token}) async {
    final result = await _dataService.get(
      url: '$baseUrl/leaves/my',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load leaves');
    }

    final response = MyLeavesResponse.fromJson(payload);
    if (!response.success) {
      throw Exception('Failed to load leaves');
    }
    return response.data;
  }

  Future<MyLeavesPageData> pendingApprovals({required String token}) async {
    final result = await _dataService.get(
      url: '$baseUrl/approvals/pending',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load pending approvals');
    }

    final response = MyLeavesResponse.fromJson(payload);
    if (!response.success) {
      throw Exception('Failed to load pending approvals');
    }
    return response.data;
  }

  Future<LeaveDetailData> leaveDetail({required String token, required String leaveId}) async {
    final result = await _dataService.get(
      url: '$baseUrl/leaves/$leaveId',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load leave detail');
    }

    final response = LeaveDetailResponse.fromJson(payload);
    if (!response.success) {
      throw Exception('Failed to load leave detail');
    }
    return response.data;
  }

  Future<String> approveLeaveRequest({
    required String token,
    required String approvalId,
    required String remarks,
  }) async {
    final result = await _dataService.post(
      url: '$baseUrl/approvals/$approvalId/approve',
      body: <String, dynamic>{'remarks': remarks},
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to approve request');
    }

    final success = payload['success'] == true;
    if (!success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to approve request');
    }

    return (payload['message'] ?? 'Request approved').toString();
  }

  Future<String> rejectLeaveRequest({
    required String token,
    required String approvalId,
    required String remarks,
  }) async {
    final result = await _dataService.post(
      url: '$baseUrl/approvals/$approvalId/reject',
      body: <String, dynamic>{'remarks': remarks},
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to reject request');
    }

    final success = payload['success'] == true;
    if (!success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to reject request');
    }

    return (payload['message'] ?? 'Request rejected').toString();
  }

  Future<String> readAllNotifications({required String token}) async {
    final result = await _dataService.post(
      url: '$baseUrl/notifications/read-all',
      body: const <String, dynamic>{},
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to mark notifications as read');
    }

    final success = payload['success'] == true;
    if (!success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to mark notifications as read');
    }

    return (payload['message'] ?? 'Notifications marked as read').toString();
  }

  Future<String> readNotification({
    required String token,
    required String notificationId,
  }) async {
    final result = await _dataService.post(
      url: '$baseUrl/notifications/$notificationId/read',
      body: const <String, dynamic>{},
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to mark notification as read');
    }

    final success = payload['success'] == true;
    if (!success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to mark notification as read');
    }

    return (payload['message'] ?? 'Notification marked as read').toString();
  }

  Future<NotificationsPageData> notifications({required String token}) async {
    final result = await _dataService.get(
      url: '$baseUrl/notifications',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load notifications');
    }
    final response = NotificationsResponse.fromJson(payload);
    if (!response.success) {
      throw Exception('Failed to load notifications');
    }
    return response.data;
  }

  Future<int> unreadNotificationsCount({required String token}) async {
    final result = await _dataService.get(
      url: '$baseUrl/notifications/unread-count',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load unread count');
    }

    final success = payload['success'] == true;
    if (!success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load unread count');
    }

    final unread = payload['unread'];
    if (unread is int) return unread;
    if (unread is String) return int.tryParse(unread) ?? 0;
    return 0;
  }

  Future<List<AppUserItem>> users({required String token}) async {
    final result = await _dataService.get(
      url: '$baseUrl/users',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load users');
    }

    final response = UsersResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load users');
    }
    return response.data;
  }

  Future<List<DepartmentItem>> departments({required String token}) async {
    final result = await _dataService.get(
      url: '$baseUrl/departments',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load departments');
    }

    final response = DepartmentsResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load departments');
    }
    return response.data;
  }

  Future<CreateTaskResponse> createTask({
    required String token,
    required String title,
    required String description,
    required String taskType,
    required String priority,
    required String assignedTo,
    required String departmentId,
    required String startDate,
    required String dueDate,
    required int estimatedHours,
  }) async {
    final result = await _dataService.post(
      url: '$baseUrl/tasks',
      body: <String, dynamic>{
        'title': title,
        'description': description,
        'task_type': taskType,
        'priority': priority,
        'assigned_to': assignedTo,
        'department_id': departmentId,
        'start_date': startDate,
        'due_date': dueDate,
        'estimated_hours': estimatedHours,
      },
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to create task');
    }

    final response = CreateTaskResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(
        response.message.isNotEmpty ? response.message : 'Failed to create task',
      );
    }
    return response;
  }

  Future<TaskActionResponse> updateTask({
    required String token,
    required String taskId,
    required String title,
    required String description,
    required String priority,
    required String status,
    required String assignedTo,
    required String departmentId,
    required String startDate,
    required String dueDate,
    required int estimatedHours,
  }) async {
    final result = await _dataService.put(
      url: '$baseUrl/tasks/$taskId',
      body: <String, dynamic>{
        'title': title,
        'description': description,
        'priority': priority,
        'status': status,
        'assigned_to': assignedTo,
        'department_id': departmentId,
        'start_date': startDate,
        'due_date': dueDate,
        'estimated_hours': estimatedHours,
      },
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to update task');
    }

    final response = TaskActionResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(
        response.message.isNotEmpty ? response.message : 'Failed to update task',
      );
    }
    return response;
  }

  Future<TaskActionResponse> updateTaskStatus({
    required String token,
    required String taskId,
    required String status,
  }) async {
    final result = await _dataService.put(
      url: '$baseUrl/tasks/$taskId/status',
      body: <String, dynamic>{'status': status},
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to update task status');
    }

    final response = TaskActionResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(
        response.message.isNotEmpty
            ? response.message
            : 'Failed to update task status',
      );
    }
    return response;
  }

  Future<TaskActionResponse> addTaskComment({
    required String token,
    required String taskId,
    required String comment,
  }) async {
    final result = await _dataService.post(
      url: '$baseUrl/tasks/$taskId/comments',
      body: <String, dynamic>{'comment': comment},
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to add task comment');
    }

    final response = TaskActionResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(
        response.message.isNotEmpty
            ? response.message
            : 'Failed to add task comment',
      );
    }
    return response;
  }

  Future<TaskActionResponse> createSupportingTask({
    required String token,
    required String taskId,
    required String requestedTo,
    required String timelineNote,
  }) async {
    final result = await _dataService.post(
      url: '$baseUrl/supporting-tasks',
      body: <String, dynamic>{
        'task_id': taskId,
        'requested_to': requestedTo,
        'timeline_note': timelineNote,
      },
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(
        _extractMessage(payload) ?? 'Failed to create supporting task',
      );
    }

    final response = TaskActionResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(
        response.message.isNotEmpty
            ? response.message
            : 'Failed to create supporting task',
      );
    }
    return response;
  }

  Future<SupportingTasksPageData> outgoingSupportingTasks({
    required String token,
  }) async {
    final result = await _dataService.get(
      url: '$baseUrl/supporting-tasks/outgoing',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(
        _extractMessage(payload) ?? 'Failed to load outgoing supporting tasks',
      );
    }

    final response = SupportingTasksResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(
        _extractMessage(payload) ?? 'Failed to load outgoing supporting tasks',
      );
    }
    return response.data;
  }

  Future<SupportingTasksPageData> incomingSupportingTasks({
    required String token,
  }) async {
    final result = await _dataService.get(
      url: '$baseUrl/supporting-tasks/incoming',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(
        _extractMessage(payload) ?? 'Failed to load incoming supporting tasks',
      );
    }

    final response = SupportingTasksResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(
        _extractMessage(payload) ?? 'Failed to load incoming supporting tasks',
      );
    }
    return response.data;
  }

  Future<TaskActionResponse> acceptSupportingTask({
    required String token,
    required String supportingTaskId,
    required String responseComment,
    required String timelineNote,
  }) async {
    final result = await _dataService.post(
      url: '$baseUrl/supporting-tasks/$supportingTaskId/accept',
      body: <String, dynamic>{
        'response_comment': responseComment,
        'timeline_note': timelineNote,
      },
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(
        _extractMessage(payload) ?? 'Failed to accept supporting task',
      );
    }

    final response = TaskActionResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(
        response.message.isNotEmpty
            ? response.message
            : 'Failed to accept supporting task',
      );
    }
    return response;
  }

  Future<TaskActionResponse> declineSupportingTask({
    required String token,
    required String supportingTaskId,
    required String responseComment,
  }) async {
    final result = await _dataService.post(
      url: '$baseUrl/supporting-tasks/$supportingTaskId/decline',
      body: <String, dynamic>{
        'response_comment': responseComment,
      },
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(
        _extractMessage(payload) ?? 'Failed to decline supporting task',
      );
    }

    final response = TaskActionResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(
        response.message.isNotEmpty
            ? response.message
            : 'Failed to decline supporting task',
      );
    }
    return response;
  }

  Future<TasksPageData> tasks({
    required String token,
    int page = 1,
  }) async {
    final result = await _dataService.get(
      url: '$baseUrl/tasks?page=$page',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load tasks');
    }

    final response = TasksResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load tasks');
    }
    return response.data;
  }

  Future<TaskDetailData> taskDetail({
    required String token,
    required String taskId,
  }) async {
    final result = await _dataService.get(
      url: '$baseUrl/tasks/$taskId',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load task detail');
    }

    final response = TaskDetailResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load task detail');
    }
    return response.data;
  }

  Future<LogoutResponse> logout({required String token}) async {
    final result = await _dataService.post(
      url: '$baseUrl/auth/logout',
      body: const <String, dynamic>{},
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to logout');
    }

    final response = LogoutResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(response.message.isNotEmpty ? response.message : 'Failed to logout');
    }
    return response;
  }

  String? _extractMessage(Map<String, dynamic> payload) {
    final message = payload['message'];
    if (message is String && message.isNotEmpty) return message;
    final error = payload['error'];
    if (error is String && error.isNotEmpty) return error;
    return null;
  }
}
