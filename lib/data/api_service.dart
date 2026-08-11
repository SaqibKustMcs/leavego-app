import 'package:leavego_app/data/data_service.dart';
import 'package:leavego_app/models/apply_leave_response.dart';
import 'package:leavego_app/models/dashboard_response.dart';
import 'package:leavego_app/models/leave_type_response.dart';
import 'package:leavego_app/models/login_response.dart';
import 'package:leavego_app/models/leave_detail_response.dart';
import 'package:leavego_app/models/leave_report_response.dart';
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
import 'package:leavego_app/models/news_action_response.dart';
import 'package:leavego_app/models/news_response.dart';
import 'package:leavego_app/models/projects_response.dart';

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
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? userId,
    String? attachmentPath,
    bool useSimpleJsonBody = false,
  }) async {
    final Map<String, dynamic> result;
    if (useSimpleJsonBody) {
      // OPM / CEO: JSON body only (approval goes to CEO for OPM).
      result = await _dataService.post(
        url: '$baseUrl/leaves',
        body: <String, dynamic>{
          'leave_type_id': int.tryParse(leaveTypeId) ?? leaveTypeId,
          'start_date': startDate,
          'end_date': endDate,
          'reason': reason,
        },
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );
    } else {
      result = await _dataService.postMultipart(
        url: '$baseUrl/leaves',
        fields: <String, String>{
          if (userId != null && userId.isNotEmpty) 'user_id': userId,
          'leave_type_id': leaveTypeId,
          'start_date': startDate,
          'end_date': endDate,
          'reason': reason,
        },
        filePath: attachmentPath,
        fileFieldName: 'attachment',
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );
    }

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

  Future<NewsActionResponse> createNews({
    required String token,
    required String title,
    required String content,
  }) async {
    final result = await _dataService.postMultipart(
      url: '$baseUrl/news',
      fields: <String, String>{
        'title': title,
        'content': content,
        'target_audience': 'all',
      },
      filePath: null,
      fileFieldName: 'image',
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to create news');
    }

    final response = NewsActionResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(response.message.isNotEmpty ? response.message : 'Failed to create news');
    }
    return response;
  }

  Future<NewsPageData> news({required String token, int page = 1}) async {
    final result = await _dataService.get(
      url: '$baseUrl/news?page=$page',
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load news');
    }

    final response = NewsResponse.fromJson(payload);
    if (!response.success) {
      throw Exception('Failed to load news');
    }

    return response.data;
  }

  Future<NewsActionResponse> updateNews({
    required String token,
    required String newsId,
    required String title,
    required String content,
    required String status,
  }) async {
    final result = await _dataService.put(
      url: '$baseUrl/news/$newsId',
      body: <String, dynamic>{
        'title': title,
        'content': content,
        'status': status,
      },
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to update news');
    }

    final response = NewsActionResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(response.message.isNotEmpty ? response.message : 'Failed to update news');
    }
    return response;
  }

  Future<NewsActionResponse> deleteNews({
    required String token,
    required String newsId,
  }) async {
    final result = await _dataService.delete(
      url: '$baseUrl/news/$newsId',
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to delete news');
    }

    final response = NewsActionResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(response.message.isNotEmpty ? response.message : 'Failed to delete news');
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

  Future<LeaveReportPageData> leaveReport({
    required String token,
    String? employeeId,
    String? departmentId,
    String? leaveTypeId,
    String? status,
    String? from,
    String? to,
    int page = 1,
    int perPage = 20,
  }) async {
    final query = <String>['page=$page', 'per_page=$perPage'];
    if (employeeId != null && employeeId.trim().isNotEmpty) {
      query.add('employee_id=${Uri.encodeQueryComponent(employeeId.trim())}');
    }
    if (departmentId != null && departmentId.trim().isNotEmpty) {
      query.add('department_id=${Uri.encodeQueryComponent(departmentId.trim())}');
    }
    if (leaveTypeId != null && leaveTypeId.trim().isNotEmpty) {
      query.add('leave_type_id=${Uri.encodeQueryComponent(leaveTypeId.trim())}');
    }
    if (status != null && status.trim().isNotEmpty) {
      query.add('status=${Uri.encodeQueryComponent(status.trim())}');
    }
    if (from != null && from.trim().isNotEmpty) {
      query.add('from=${Uri.encodeQueryComponent(from.trim())}');
    }
    if (to != null && to.trim().isNotEmpty) {
      query.add('to=${Uri.encodeQueryComponent(to.trim())}');
    }

    final result = await _dataService.get(
      url: '$baseUrl/leaves/report?${query.join('&')}',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load leave report');
    }

    final response = LeaveReportResponse.fromJson(payload);
    if (!response.success) {
      throw Exception('Failed to load leave report');
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

  Future<String> readNotification({required String token, required String notificationId}) async {
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

  /// Registers an FCM device token with the backend so the server can deliver
  /// push notifications to this device. Best-effort: returns whether the call
  /// succeeded and never throws so it can be fired without blocking the UI.
  Future<bool> registerFcmDeviceToken({
    required String token,
    required String fcmToken,
    required String platform,
    required String deviceName,
  }) async {
    try {
      final result = await _dataService.post(
        url: '$baseUrl/device-tokens/fcm',
        body: <String, dynamic>{
          'token': fcmToken,
          'platform': platform,
          'device_name': deviceName,
        },
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );
      final statusCode = result['statusCode'] as int? ?? 500;
      return statusCode >= 200 && statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Removes an FCM device token from the backend on logout. Best-effort.
  Future<bool> unregisterFcmDeviceToken({
    required String token,
    required String fcmToken,
  }) async {
    try {
      final result = await _dataService.delete(
        url: '$baseUrl/device-tokens/fcm',
        body: <String, dynamic>{'token': fcmToken},
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );
      final statusCode = result['statusCode'] as int? ?? 500;
      return statusCode >= 200 && statusCode < 300;
    } catch (_) {
      return false;
    }
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

  Future<EmployeesPageData> employees({
    required String token,
    int page = 1,
    int perPage = 20,
  }) async {
    final result = await _dataService.get(
      url: '$baseUrl/employees?page=$page&per_page=$perPage',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load employees');
    }

    final response = EmployeesResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load employees');
    }
    return response.data;
  }

  Future<Map<String, dynamic>> createEmployee({
    required String token,
    required String name,
    required String email,
    required String password,
    required String role,
    required int departmentId,
    String? phone,
    required bool isActive,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'department_id': departmentId,
      'is_active': isActive,
    };
    final trimmedPhone = phone?.trim();
    if (trimmedPhone != null && trimmedPhone.isNotEmpty) {
      body['phone'] = trimmedPhone;
    }

    final result = await _dataService.post(
      url: '$baseUrl/employees',
      body: body,
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to create employee');
    }

    if (payload['success'] == false) {
      throw Exception(_extractMessage(payload) ?? 'Failed to create employee');
    }
    return payload;
  }

  Future<Map<String, dynamic>> updateEmployee({
    required String token,
    required int employeeId,
    required String name,
    required String role,
    required int departmentId,
    String? phone,
    required bool isActive,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'role': role,
      'department_id': departmentId,
      'is_active': isActive,
    };
    final trimmedPhone = phone?.trim();
    if (trimmedPhone != null && trimmedPhone.isNotEmpty) {
      body['phone'] = trimmedPhone;
    } else {
      body['phone'] = null;
    }

    final result = await _dataService.put(
      url: '$baseUrl/employees/$employeeId',
      body: body,
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to update employee');
    }

    if (payload['success'] == false) {
      throw Exception(_extractMessage(payload) ?? 'Failed to update employee');
    }
    return payload;
  }

  Future<Map<String, dynamic>> deleteEmployee({
    required String token,
    required int employeeId,
  }) async {
    final result = await _dataService.delete(
      url: '$baseUrl/employees/$employeeId',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to delete employee');
    }

    if (payload['success'] == false) {
      throw Exception(_extractMessage(payload) ?? 'Failed to delete employee');
    }
    return payload;
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
    required String startTime,
    required String dueDate,
    required String dueTime,
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
        'start_time': startTime,
        'due_date': dueDate,
        'due_time': dueTime,
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
      throw Exception(response.message.isNotEmpty ? response.message : 'Failed to create task');
    }
    return response;
  }

  Future<CreateTaskResponse> createProjectTask({
    required String token,
    required int projectId,
    required String title,
    required String description,
    required String priority,
    required String assignedTo,
    required String startDate,
    required String startTime,
    required String dueDate,
    required String dueTime,
    required int estimatedHours,
  }) async {
    final result = await _dataService.post(
      url: '$baseUrl/projects/$projectId/tasks',
      body: <String, dynamic>{
        'title': title,
        'description': description,
        'priority': priority,
        'task_type': null,
        'assigned_to': assignedTo,
        'department_id': null,
        'start_date': startDate,
        'start_time': startTime,
        'due_date': dueDate,
        'due_time': dueTime,
        'estimated_hours': estimatedHours,
      },
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to create project task');
    }

    final response = CreateTaskResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(response.message.isNotEmpty ? response.message : 'Failed to create project task');
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
      throw Exception(response.message.isNotEmpty ? response.message : 'Failed to update task');
    }
    return response;
  }

  Future<TaskActionResponse> updateTaskStatus({
    required String token,
    required String taskId,
    required String status,
  }) async {
    print("update task======> ${'$baseUrl/tasks/$taskId/status'}  + $status");

    final result = await _dataService.post(
      url: '$baseUrl/tasks/$taskId/status',
      body: {'status': status},
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
        response.message.isNotEmpty ? response.message : 'Failed to update task status',
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
        response.message.isNotEmpty ? response.message : 'Failed to add task comment',
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
        'message': timelineNote,
      },
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to create supporting task');
    }

    final response = TaskActionResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(
        response.message.isNotEmpty ? response.message : 'Failed to create supporting task',
      );
    }
    return response;
  }

  Future<SupportingTasksPageData> outgoingSupportingTasks({required String token}) async {
    final result = await _dataService.get(
      url: '$baseUrl/supporting-tasks/outgoing',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load outgoing supporting tasks');
    }

    final response = SupportingTasksResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load outgoing supporting tasks');
    }
    return response.data;
  }

  Future<SupportingTasksPageData> incomingSupportingTasks({required String token}) async {
    final result = await _dataService.get(
      url: '$baseUrl/supporting-tasks/incoming',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load incoming supporting tasks');
    }

    final response = SupportingTasksResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load incoming supporting tasks');
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
      body: {},
      // body: <String, dynamic>{'response_message': responseComment, 'timeline_note': timelineNote},
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to accept supporting task');
    }

    final response = TaskActionResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(
        response.message.isNotEmpty ? response.message : 'Failed to accept supporting task',
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
      body: {},
      // body: <String, dynamic>{'response_comment': responseComment},
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to decline supporting task');
    }

    final response = TaskActionResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(
        response.message.isNotEmpty ? response.message : 'Failed to decline supporting task',
      );
    }
    return response;
  }

  Future<ProjectsPageData> projects({required String token, int page = 1}) async {
    final result = await _dataService.get(
      url: '$baseUrl/projects?page=$page',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load projects');
    }

    final response = ProjectsResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load projects');
    }
    return response.data;
  }

  Future<Map<String, dynamic>> createProject({
    required String token,
    required String name,
    required String description,
    required String status,
    required String startDate,
    required String dueDate,
    required List<int> memberIds,
  }) async {
    final result = await _dataService.post(
      url: '$baseUrl/projects',
      body: <String, dynamic>{
        'name': name,
        'description': description,
        'status': status,
        'start_date': startDate,
        'due_date': dueDate,
        'member_ids': memberIds,
      },
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to create project');
    }

    if (payload['success'] == false) {
      throw Exception(_extractMessage(payload) ?? 'Failed to create project');
    }
    return payload;
  }

  Future<Map<String, dynamic>> updateProject({
    required String token,
    required int projectId,
    required String name,
    required String description,
    required String status,
    required String startDate,
    required String dueDate,
    required List<int> memberIds,
  }) async {
    final result = await _dataService.put(
      url: '$baseUrl/projects/$projectId',
      body: <String, dynamic>{
        'name': name,
        'description': description,
        'status': status,
        'start_date': startDate,
        'due_date': dueDate,
        'member_ids': memberIds,
      },
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to update project');
    }

    if (payload['success'] == false) {
      throw Exception(_extractMessage(payload) ?? 'Failed to update project');
    }
    return payload;
  }

  Future<List<ProjectMember>> projectMembers({
    required String token,
    required int projectId,
  }) async {
    final result = await _dataService.get(
      url: '$baseUrl/projects/$projectId/members',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load project members');
    }

    final response = ProjectMembersResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load project members');
    }
    return response.data;
  }

  Future<TasksPageData> projectTasks({
    required String token,
    required int projectId,
    int page = 1,
    bool myTasks = false,
    String? status,
  }) async {
    final query = <String>['page=$page'];
    if (myTasks) query.add('my_tasks=1');
    if (status != null && status.trim().isNotEmpty) {
      query.add('status=${Uri.encodeQueryComponent(status.trim())}');
    }

    final result = await _dataService.get(
      url: '$baseUrl/projects/$projectId/tasks?${query.join('&')}',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load project tasks');
    }

    final response = TasksResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load project tasks');
    }
    return response.data;
  }

  Future<TasksPageData> myPendingDueTasks({
    required String token,
    int page = 1,
    int perPage = 20,
    String? priority,
  }) async {
    final query = <String>['page=$page', 'per_page=$perPage'];
    if (priority != null && priority.trim().isNotEmpty) {
      query.add('priority=${Uri.encodeQueryComponent(priority.trim())}');
    }

    final result = await _dataService.get(
      url: '$baseUrl/tasks/my-pending-due?${query.join('&')}',
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final statusCode = result['statusCode'] as int? ?? 500;
    final payload = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load pending due tasks');
    }

    final response = TasksResponse.fromJson(payload);
    if (!response.success) {
      throw Exception(_extractMessage(payload) ?? 'Failed to load pending due tasks');
    }
    return response.data;
  }

  Future<TasksPageData> tasks({
    required String token,
    int page = 1,
    bool myTasks = false,
    String? dueDateLte,
  }) async {
    final query = <String>['page=$page'];
    if (myTasks) query.add('my_tasks=1');
    if (dueDateLte != null && dueDateLte.trim().isNotEmpty) {
      query.add('due_date_lte=${Uri.encodeQueryComponent(dueDateLte.trim())}');
    }

    final result = await _dataService.get(
      url: '$baseUrl/tasks?${query.join('&')}',
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

  Future<TaskDetailData> taskDetail({required String token, required String taskId}) async {
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
