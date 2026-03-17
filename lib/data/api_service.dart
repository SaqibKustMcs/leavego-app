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
