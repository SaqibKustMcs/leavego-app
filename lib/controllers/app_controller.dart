import 'package:flutter/foundation.dart';
import 'package:leavego_app/data/api_service.dart';
import 'package:leavego_app/models/apply_leave_response.dart';
import 'package:leavego_app/models/dashboard_response.dart';
import 'package:leavego_app/models/leave_type_response.dart';
import 'package:leavego_app/models/login_response.dart';
import 'package:leavego_app/models/leave_detail_response.dart';
import 'package:leavego_app/models/logout_response.dart';
import 'package:leavego_app/models/my_leaves_response.dart';
import 'package:leavego_app/models/me_response.dart';
import 'package:leavego_app/models/notifications_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppController extends ChangeNotifier {
  AppController(this._apiService);

  static const String tokenStorageKey = 'auth_token';
  final ApiService _apiService;

  bool isLoading = false;
  String? errorMessage;
  bool dashboardLoading = false;
  String? dashboardError;
  DashboardData? dashboardData;
  bool meLoading = false;
  String? meError;
  MeData? meData;
  bool leaveTypesLoading = false;
  String? leaveTypesError;
  List<LeaveTypeItem> leaveTypes = <LeaveTypeItem>[];
  bool applyLeaveLoading = false;
  String? applyLeaveError;
  bool myLeavesLoading = false;
  String? myLeavesError;
  List<MyLeaveItem> myLeaves = <MyLeaveItem>[];
  bool approvalActionLoading = false;
  String? approvalActionError;
  bool logoutLoading = false;
  String? logoutError;
  bool notificationsReadAllLoading = false;
  String? notificationsReadAllError;
  bool notificationsLoading = false;
  String? notificationsError;
  List<AppNotificationItem> notifications = <AppNotificationItem>[];

  Future<LoginResponse?> login({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );
      final token = response.data.token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenStorageKey, token);
      meData = MeData(
        id: response.data.user.id,
        name: response.data.user.name,
        email: response.data.user.email,
        role: response.data.user.role,
        departmentId: response.data.user.departmentId,
        isActive: true,
      );
      return response;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenStorageKey);
  }

  Future<void> loadDashboard() async {
    dashboardLoading = true;
    dashboardError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      dashboardData = await _apiService.dashboard(token: token);
    } catch (e) {
      dashboardError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      dashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMe() async {
    meLoading = true;
    meError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      meData = await _apiService.me(token: token);
    } catch (e) {
      meError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      meLoading = false;
      notifyListeners();
    }
  }

  Future<LogoutResponse?> logout() async {
    logoutLoading = true;
    logoutError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token != null && token.isNotEmpty) {
        await _apiService.logout(token: token);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenStorageKey);
      dashboardData = null;
      meData = null;
      leaveTypes = <LeaveTypeItem>[];
      myLeaves = <MyLeaveItem>[];
      dashboardError = null;
      meError = null;
      leaveTypesError = null;
      myLeavesError = null;
      errorMessage = null;
      return const LogoutResponse(success: true, message: 'Logged out');
    } catch (e) {
      logoutError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      logoutLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLeaveTypes() async {
    leaveTypesLoading = true;
    leaveTypesError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      leaveTypes = await _apiService.leaveTypes(token: token);
    } catch (e) {
      leaveTypesError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      leaveTypesLoading = false;
      notifyListeners();
    }
  }

  Future<ApplyLeaveResponse?> applyLeave({
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? attachmentPath,
  }) async {
    applyLeaveLoading = true;
    applyLeaveError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      var userId = meData?.id.toString() ?? '';
      if (userId.isEmpty) {
        meData = await _apiService.me(token: token);
        userId = meData?.id.toString() ?? '';
      }
      if (userId.isEmpty) {
        throw Exception('User id not found. Please login again.');
      }

      return await _apiService.applyLeave(
        token: token,
        userId: userId,
        leaveTypeId: leaveTypeId,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        attachmentPath: attachmentPath,
      );
    } catch (e) {
      applyLeaveError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      applyLeaveLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyLeaves() async {
    myLeavesLoading = true;
    myLeavesError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final page = await _apiService.myLeaves(token: token);
      myLeaves = page.items;
    } catch (e) {
      myLeavesError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      myLeavesLoading = false;
      notifyListeners();
    }
  }

  Future<LeaveDetailData?> loadLeaveDetail({required String leaveId}) async {
    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      return await _apiService.leaveDetail(token: token, leaveId: leaveId);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<String?> approveLeaveRequest({
    required String approvalId,
    required String remarks,
  }) async {
    approvalActionLoading = true;
    approvalActionError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      return await _apiService.approveLeaveRequest(
        token: token,
        approvalId: approvalId,
        remarks: remarks,
      );
    } catch (e) {
      approvalActionError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      approvalActionLoading = false;
      notifyListeners();
    }
  }

  Future<String?> rejectLeaveRequest({
    required String approvalId,
    required String remarks,
  }) async {
    approvalActionLoading = true;
    approvalActionError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      return await _apiService.rejectLeaveRequest(
        token: token,
        approvalId: approvalId,
        remarks: remarks,
      );
    } catch (e) {
      approvalActionError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      approvalActionLoading = false;
      notifyListeners();
    }
  }

  Future<String?> readAllNotifications() async {
    notificationsReadAllLoading = true;
    notificationsReadAllError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      return await _apiService.readAllNotifications(token: token);
    } catch (e) {
      notificationsReadAllError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      notificationsReadAllLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNotifications() async {
    notificationsLoading = true;
    notificationsError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final page = await _apiService.notifications(token: token);
      notifications = page.items;
    } catch (e) {
      notificationsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      notificationsLoading = false;
      notifyListeners();
    }
  }
}
