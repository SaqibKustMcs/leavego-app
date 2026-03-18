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
import 'package:leavego_app/models/create_task_response.dart';
import 'package:leavego_app/models/departments_response.dart';
import 'package:leavego_app/models/task_action_response.dart';
import 'package:leavego_app/models/task_detail_response.dart';
import 'package:leavego_app/models/tasks_response.dart';
import 'package:leavego_app/models/users_response.dart';
import 'package:leavego_app/models/supporting_tasks_response.dart';
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
  bool notificationReadLoading = false;
  String? notificationReadError;
  bool unreadCountLoading = false;
  String? unreadCountError;
  int unreadCount = 0;
  bool notificationsLoading = false;
  String? notificationsError;
  List<AppNotificationItem> notifications = <AppNotificationItem>[];

  bool usersLoading = false;
  String? usersError;
  List<AppUserItem> users = <AppUserItem>[];

  bool departmentsLoading = false;
  String? departmentsError;
  List<DepartmentItem> departments = <DepartmentItem>[];

  bool createTaskLoading = false;
  String? createTaskError;
  bool updateTaskLoading = false;
  String? updateTaskError;
  bool updateTaskStatusLoading = false;
  String? updateTaskStatusError;
  bool addTaskCommentLoading = false;
  String? addTaskCommentError;
  bool createSupportingTaskLoading = false;
  String? createSupportingTaskError;
  bool outgoingSupportingTasksLoading = false;
  String? outgoingSupportingTasksError;
  List<SupportingTaskItem> outgoingSupportingTasks = <SupportingTaskItem>[];
  bool incomingSupportingTasksLoading = false;
  String? incomingSupportingTasksError;
  List<SupportingTaskItem> incomingSupportingTasks = <SupportingTaskItem>[];
  bool acceptSupportingTaskLoading = false;
  String? acceptSupportingTaskError;
  bool declineSupportingTaskLoading = false;
  String? declineSupportingTaskError;
  bool tasksLoading = false;
  bool tasksLoadingMore = false;
  String? tasksError;
  List<TaskItem> tasks = <TaskItem>[];
  int tasksCurrentPage = 1;
  int tasksLastPage = 1;
  bool tasksHasMore = false;

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

  Future<void> loadRequestsByRole() async {
    myLeavesLoading = true;
    myLeavesError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }

      MeData? profile = meData;
      if (profile == null) {
        profile = await _apiService.me(token: token);
        meData = profile;
      }

      final role = (profile.role).trim().toLowerCase();
      final page = (role == 'hod' || role == 'hr')
          ? await _apiService.pendingApprovals(token: token)
          : await _apiService.myLeaves(token: token);
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
      final msg = await _apiService.readAllNotifications(token: token);
      unreadCount = 0;
      await loadNotifications();
      return msg;
    } catch (e) {
      notificationsReadAllError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      notificationsReadAllLoading = false;
      notifyListeners();
    }
  }

  void _markNotificationReadLocal(String notificationId) {
    final updated = notifications
        .map(
          (n) => n.id == notificationId
              ? AppNotificationItem(
                  id: n.id,
                  userId: n.userId,
                  title: n.title,
                  message: n.message,
                  type: n.type,
                  isRead: true,
                  createdAt: n.createdAt,
                  updatedAt: n.updatedAt,
                  readAt: n.readAt,
                )
              : n,
        )
        .toList();
    notifications = updated;
  }

  Future<String?> readNotification({required String notificationId}) async {
    notificationReadLoading = true;
    notificationReadError = null;
    _markNotificationReadLocal(notificationId);
    if (unreadCount > 0) unreadCount -= 1;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final msg = await _apiService.readNotification(
        token: token,
        notificationId: notificationId,
      );
      await loadUnreadCount();
      return msg;
    } catch (e) {
      notificationReadError = e.toString().replaceFirst('Exception: ', '');
      await loadNotifications();
      await loadUnreadCount();
      return null;
    } finally {
      notificationReadLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount() async {
    unreadCountLoading = true;
    unreadCountError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      unreadCount = await _apiService.unreadNotificationsCount(token: token);
    } catch (e) {
      unreadCountError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      unreadCountLoading = false;
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
      unreadCount = notifications.where((n) => !n.isRead).length;
    } catch (e) {
      notificationsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      notificationsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers() async {
    usersLoading = true;
    usersError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      users = await _apiService.users(token: token);
    } catch (e) {
      usersError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      usersLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDepartments() async {
    departmentsLoading = true;
    departmentsError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      departments = await _apiService.departments(token: token);
    } catch (e) {
      departmentsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      departmentsLoading = false;
      notifyListeners();
    }
  }

  Future<CreateTaskResponse?> createTask({
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
    createTaskLoading = true;
    createTaskError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final response = await _apiService.createTask(
        token: token,
        title: title,
        description: description,
        taskType: taskType,
        priority: priority,
        assignedTo: assignedTo,
        departmentId: departmentId,
        startDate: startDate,
        dueDate: dueDate,
        estimatedHours: estimatedHours,
      );
      await loadTasks(refresh: true);
      return response;
    } catch (e) {
      createTaskError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      createTaskLoading = false;
      notifyListeners();
    }
  }

  Future<TaskActionResponse?> updateTask({
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
    updateTaskLoading = true;
    updateTaskError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final response = await _apiService.updateTask(
        token: token,
        taskId: taskId,
        title: title,
        description: description,
        priority: priority,
        status: status,
        assignedTo: assignedTo,
        departmentId: departmentId,
        startDate: startDate,
        dueDate: dueDate,
        estimatedHours: estimatedHours,
      );
      await loadTasks(refresh: true);
      return response;
    } catch (e) {
      updateTaskError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      updateTaskLoading = false;
      notifyListeners();
    }
  }

  Future<TaskActionResponse?> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    updateTaskStatusLoading = true;
    updateTaskStatusError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final response = await _apiService.updateTaskStatus(
        token: token,
        taskId: taskId,
        status: status,
      );
      await loadTasks(refresh: true);
      return response;
    } catch (e) {
      updateTaskStatusError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      updateTaskStatusLoading = false;
      notifyListeners();
    }
  }

  Future<TaskActionResponse?> addTaskComment({
    required String taskId,
    required String comment,
  }) async {
    addTaskCommentLoading = true;
    addTaskCommentError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      return await _apiService.addTaskComment(
        token: token,
        taskId: taskId,
        comment: comment,
      );
    } catch (e) {
      addTaskCommentError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      addTaskCommentLoading = false;
      notifyListeners();
    }
  }

  Future<TaskActionResponse?> createSupportingTask({
    required String taskId,
    required String requestedTo,
    required String timelineNote,
  }) async {
    createSupportingTaskLoading = true;
    createSupportingTaskError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final response = await _apiService.createSupportingTask(
        token: token,
        taskId: taskId,
        requestedTo: requestedTo,
        timelineNote: timelineNote,
      );
      await loadTasks(refresh: true);
      return response;
    } catch (e) {
      createSupportingTaskError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      createSupportingTaskLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOutgoingSupportingTasks() async {
    outgoingSupportingTasksLoading = true;
    outgoingSupportingTasksError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final page = await _apiService.outgoingSupportingTasks(token: token);
      outgoingSupportingTasks = page.items;
    } catch (e) {
      outgoingSupportingTasksError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      outgoingSupportingTasksLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadIncomingSupportingTasks() async {
    incomingSupportingTasksLoading = true;
    incomingSupportingTasksError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final page = await _apiService.incomingSupportingTasks(token: token);
      incomingSupportingTasks = page.items;
    } catch (e) {
      incomingSupportingTasksError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      incomingSupportingTasksLoading = false;
      notifyListeners();
    }
  }

  Future<TaskActionResponse?> acceptSupportingTask({
    required String supportingTaskId,
    required String responseComment,
    required String timelineNote,
  }) async {
    acceptSupportingTaskLoading = true;
    acceptSupportingTaskError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final response = await _apiService.acceptSupportingTask(
        token: token,
        supportingTaskId: supportingTaskId,
        responseComment: responseComment,
        timelineNote: timelineNote,
      );
      await Future.wait(<Future<void>>[
        loadIncomingSupportingTasks(),
        loadOutgoingSupportingTasks(),
      ]);
      return response;
    } catch (e) {
      acceptSupportingTaskError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      acceptSupportingTaskLoading = false;
      notifyListeners();
    }
  }

  Future<TaskActionResponse?> declineSupportingTask({
    required String supportingTaskId,
    required String responseComment,
  }) async {
    declineSupportingTaskLoading = true;
    declineSupportingTaskError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final response = await _apiService.declineSupportingTask(
        token: token,
        supportingTaskId: supportingTaskId,
        responseComment: responseComment,
      );
      await Future.wait(<Future<void>>[
        loadIncomingSupportingTasks(),
        loadOutgoingSupportingTasks(),
      ]);
      return response;
    } catch (e) {
      declineSupportingTaskError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      declineSupportingTaskLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTasks({bool refresh = false}) async {
    if (refresh) {
      tasksCurrentPage = 1;
      tasksLastPage = 1;
      tasksHasMore = false;
    }

    tasksLoading = true;
    tasksError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final page = await _apiService.tasks(token: token, page: 1);
      tasks = page.items;
      tasksCurrentPage = page.currentPage;
      tasksLastPage = page.lastPage;
      tasksHasMore = page.hasMore;
    } catch (e) {
      tasksError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      tasksLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreTasks() async {
    if (tasksLoadingMore || tasksLoading || !tasksHasMore) return;

    tasksLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = tasksCurrentPage + 1;
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final page = await _apiService.tasks(token: token, page: nextPage);
      tasks = <TaskItem>[...tasks, ...page.items];
      tasksCurrentPage = page.currentPage;
      tasksLastPage = page.lastPage;
      tasksHasMore = page.hasMore;
    } catch (e) {
      tasksError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      tasksLoadingMore = false;
      notifyListeners();
    }
  }

  Future<TaskDetailData?> loadTaskDetail({required String taskId}) async {
    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      return await _apiService.taskDetail(token: token, taskId: taskId);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
