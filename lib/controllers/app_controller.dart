import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:leavego_app/data/api_service.dart';
import 'package:leavego_app/models/apply_leave_response.dart';
import 'package:leavego_app/models/dashboard_response.dart';
import 'package:leavego_app/ui/models/today_glance_tab.dart';
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
import 'package:leavego_app/utils/app_roles.dart';
import 'package:leavego_app/config/google_calendar_config.dart';
import 'package:leavego_app/models/google_calendar_response.dart';
import 'package:leavego_app/services/google_calendar_auth_service.dart';
import 'package:leavego_app/services/google_calendar_direct_service.dart';
import 'package:leavego_app/services/google_calendar_session_storage.dart';
import 'package:leavego_app/services/session_storage.dart';

class AppController extends ChangeNotifier {
  AppController(this._apiService);

  static const String tokenStorageKey = SessionStorage.tokenKey;
  final ApiService _apiService;
  final GoogleCalendarDirectService _googleCalendarDirectService = GoogleCalendarDirectService();

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
  bool leaveReportLoading = false;
  bool leaveReportLoadingMore = false;
  String? leaveReportError;
  List<LeaveReportItem> leaveReportItems = <LeaveReportItem>[];
  int leaveReportCurrentPage = 1;
  int leaveReportLastPage = 1;
  int leaveReportTotal = 0;
  bool leaveReportHasMore = false;
  String? _leaveReportEmployeeId;
  String? _leaveReportDepartmentId;
  String? _leaveReportLeaveTypeId;
  String? _leaveReportStatus;
  String? _leaveReportFrom;
  String? _leaveReportTo;
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
  bool notificationsLoadingMore = false;
  String? notificationsError;
  List<AppNotificationItem> notifications = <AppNotificationItem>[];
  int notificationsCurrentPage = 1;
  int notificationsLastPage = 1;
  int notificationsTotal = 0;
  bool notificationsHasMore = false;

  bool usersLoading = false;
  String? usersError;
  List<AppUserItem> users = <AppUserItem>[];

  bool employeesLoading = false;
  bool employeesLoadingMore = false;
  String? employeesError;
  List<AppUserItem> employees = <AppUserItem>[];
  int employeesCurrentPage = 1;
  int employeesLastPage = 1;
  int employeesTotal = 0;
  bool employeesHasMore = false;

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

  bool myTodayTasksLoading = false;
  bool myTodayTasksLoadingMore = false;
  String? myTodayTasksError;
  List<TaskItem> myTodayTasks = <TaskItem>[];
  int myTodayTasksCurrentPage = 1;
  int myTodayTasksLastPage = 1;
  int myTodayTasksTotal = 0;
  bool myTodayTasksHasMore = false;
  String? myTodayTasksPriorityFilter;
  TodayGlanceTab todayGlanceTab = TodayGlanceTab.tasks;

  /// Highest open "due today" count seen today; used for completed/total progress.
  String? _myTodayTasksProgressDayKey;
  int _myTodayTasksOpenBaseline = 0;

  bool googleCalendarStatusLoading = false;
  bool googleCalendarConnectLoading = false;
  bool googleCalendarDisconnectLoading = false;
  bool googleCalendarEventsLoading = false;
  bool googleCalendarEventsLoadingMore = false;
  String? googleCalendarStatusError;
  String? googleCalendarConnectError;
  String? googleCalendarDisconnectError;
  String? googleCalendarEventsError;
  bool googleCalendarConnected = false;
  String? googleCalendarGoogleEmail;
  List<GoogleCalendarEventItem> googleCalendarEvents = <GoogleCalendarEventItem>[];
  String? _googleCalendarNextPageToken;
  bool googleCalendarEventsHasMore = false;
  DateTime? _googleCalendarEventsTimeMin;
  DateTime? _googleCalendarEventsTimeMax;

  List<GoogleCalendarEventItem> get googleCalendarEventsToday {
    final now = DateTime.now();
    return googleCalendarEvents.where((e) => e.occursOnLocalDay(now)).toList();
  }

  /// Meetings from now onward (includes in-progress), sorted by start time.
  List<GoogleCalendarEventItem> get googleCalendarUpcomingMeetings {
    final now = DateTime.now();
    final list =
        googleCalendarEvents.where((e) => e.isUpcomingFrom(now)).toList()
          ..sort(GoogleCalendarEventItem.compareByStart);
    return list;
  }

  GoogleCalendarEventItem? get googleCalendarNextMeeting {
    final upcoming = googleCalendarUpcomingMeetings;
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// Today's meetings from now (home glance).
  List<GoogleCalendarEventItem> get googleCalendarTodayUpcomingMeetings {
    final now = DateTime.now();
    final list =
        googleCalendarEvents
            .where((e) => e.occursOnLocalDay(now) && e.isUpcomingFrom(now))
            .toList()
          ..sort(GoogleCalendarEventItem.compareByStart);
    return list;
  }

  GoogleCalendarEventItem? get googleCalendarNextMeetingToday {
    final today = googleCalendarTodayUpcomingMeetings;
    return today.isEmpty ? null : today.first;
  }

  void setTodayGlanceTab(TodayGlanceTab tab) {
    if (todayGlanceTab == tab) return;
    todayGlanceTab = tab;
    notifyListeners();
  }

  void _resetGoogleCalendarState() {
    googleCalendarConnected = false;
    googleCalendarGoogleEmail = null;
    googleCalendarEvents = <GoogleCalendarEventItem>[];
    _googleCalendarNextPageToken = null;
    googleCalendarEventsHasMore = false;
    googleCalendarStatusError = null;
    googleCalendarConnectError = null;
    googleCalendarDisconnectError = null;
    googleCalendarEventsError = null;
    _googleCalendarEventsTimeMin = null;
    _googleCalendarEventsTimeMax = null;
  }

  Future<bool> _readGoogleCalendarLinkedFromStorage() async {
    return await GoogleCalendarSessionStorage.readConnected() == true;
  }

  /// Keeps Calendar linked until TaskBulls logout; loads events when linked.
  Future<void> ensureGoogleCalendarReady({bool refreshEvents = true}) async {
    final linked = await _readGoogleCalendarLinkedFromStorage();
    if (!linked) {
      googleCalendarConnected = false;
      return;
    }

    googleCalendarConnected = true;
    googleCalendarGoogleEmail ??= await GoogleCalendarSessionStorage.readGoogleEmail();
    googleCalendarStatusError = null;
    notifyListeners();

    await GoogleCalendarAuthService.instance.restoreSessionIfConnected();

    if (refreshEvents && !googleCalendarEventsLoading) {
      await loadGoogleCalendarEvents(refresh: true);
    }
  }

  Future<void> restoreGoogleCalendarSession() async {
    googleCalendarStatusLoading = true;
    googleCalendarStatusError = null;
    notifyListeners();

    try {
      final linked = await _readGoogleCalendarLinkedFromStorage();
      googleCalendarGoogleEmail = await GoogleCalendarSessionStorage.readGoogleEmail();
      if (!linked) {
        googleCalendarConnected = false;
        return;
      }

      googleCalendarConnected = true;
      await GoogleCalendarAuthService.instance.restoreSessionIfConnected();
      if (!googleCalendarEventsLoading) {
        await loadGoogleCalendarEvents(refresh: true);
      }
    } catch (e) {
      googleCalendarStatusError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      googleCalendarStatusLoading = false;
      notifyListeners();
    }
  }

  Future<bool> connectGoogleCalendar() async {
    googleCalendarConnectLoading = true;
    googleCalendarConnectError = null;
    notifyListeners();

    try {
      final result = await GoogleCalendarAuthService.instance.connect();
      googleCalendarConnected = true;
      googleCalendarGoogleEmail = result.googleEmail;
      await loadGoogleCalendarEvents(refresh: true);
      return true;
    } catch (e) {
      googleCalendarConnectError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      googleCalendarConnectLoading = false;
      notifyListeners();
    }
  }

  Future<bool> disconnectGoogleCalendar() async {
    googleCalendarDisconnectLoading = true;
    googleCalendarDisconnectError = null;
    notifyListeners();

    try {
      await GoogleCalendarAuthService.instance.disconnect();
      _resetGoogleCalendarState();
      return true;
    } catch (e) {
      googleCalendarDisconnectError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      googleCalendarDisconnectLoading = false;
      notifyListeners();
    }
  }

  ({DateTime min, DateTime max}) googleCalendarDefaultRange({
    int pastDays = GoogleCalendarConfig.defaultPastDays,
    int futureDays = GoogleCalendarConfig.defaultFutureDays,
  }) {
    final now = DateTime.now();
    final min = DateTime(now.year, now.month, now.day).subtract(Duration(days: pastDays));
    final max = DateTime(now.year, now.month, now.day).add(Duration(days: futureDays + 1));
    return (min: min, max: max);
  }

  Future<void> loadGoogleCalendarEvents({
    bool refresh = false,
    int pastDays = GoogleCalendarConfig.defaultPastDays,
    int futureDays = GoogleCalendarConfig.defaultFutureDays,
    bool allowInteractiveAuth = false,
  }) async {
    final linked = googleCalendarConnected || await _readGoogleCalendarLinkedFromStorage();
    if (!linked) return;
    googleCalendarConnected = true;
    googleCalendarGoogleEmail ??= await GoogleCalendarSessionStorage.readGoogleEmail();
    if (googleCalendarEventsLoading || googleCalendarEventsLoadingMore) return;

    if (refresh) {
      googleCalendarEventsLoading = true;
      googleCalendarEventsError = null;
      _googleCalendarNextPageToken = null;
      googleCalendarEventsHasMore = false;
    } else {
      googleCalendarEventsLoadingMore = true;
    }
    notifyListeners();

    try {
      final range = googleCalendarDefaultRange(pastDays: pastDays, futureDays: futureDays);
      _googleCalendarEventsTimeMin = range.min;
      _googleCalendarEventsTimeMax = range.max;

      final page = await _googleCalendarDirectService.fetchEvents(
        timeMin: range.min,
        timeMax: range.max,
        pageToken: refresh ? null : _googleCalendarNextPageToken,
        allowInteractiveAuth: allowInteractiveAuth,
      );

      if (refresh) {
        googleCalendarEvents = page.items;
      } else {
        googleCalendarEvents = <GoogleCalendarEventItem>[...googleCalendarEvents, ...page.items];
      }
      _googleCalendarNextPageToken = page.nextPageToken;
      googleCalendarEventsHasMore = page.hasMore;
    } on GoogleCalendarAuthException catch (e) {
      googleCalendarEventsError = _googleCalendarAuthMessage(e);
    } catch (e) {
      googleCalendarEventsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      googleCalendarEventsLoading = false;
      googleCalendarEventsLoadingMore = false;
      notifyListeners();
    }
  }

  String _googleCalendarAuthMessage(GoogleCalendarAuthException e) {
    if (e.detail != null && e.detail!.trim().isNotEmpty) {
      return e.detail!.trim();
    }
    switch (e.code) {
      case GoogleCalendarAuthException.codePermissionRevoked:
        return 'Google Calendar access was revoked. Connect again from Profile.';
      case GoogleCalendarAuthException.codeSessionExpired:
        return 'Google Calendar session expired. Connect again from Profile.';
      case GoogleCalendarAuthException.codeNotConnected:
        return 'Google Calendar is not connected.';
      default:
        return 'Could not access Google Calendar.';
    }
  }

  Future<void> loadMoreGoogleCalendarEvents() async {
    if (!googleCalendarEventsHasMore || googleCalendarEventsLoadingMore) return;
    final min = _googleCalendarEventsTimeMin;
    final max = _googleCalendarEventsTimeMax;
    if (min == null || max == null) {
      await loadGoogleCalendarEvents(refresh: false);
      return;
    }

    googleCalendarEventsLoadingMore = true;
    notifyListeners();

    try {
      final page = await _googleCalendarDirectService.fetchEvents(
        timeMin: min,
        timeMax: max,
        pageToken: _googleCalendarNextPageToken,
      );
      googleCalendarEvents = <GoogleCalendarEventItem>[...googleCalendarEvents, ...page.items];
      _googleCalendarNextPageToken = page.nextPageToken;
      googleCalendarEventsHasMore = page.hasMore;
    } on GoogleCalendarAuthException catch (e) {
      googleCalendarEventsError = _googleCalendarAuthMessage(e);
    } catch (e) {
      googleCalendarEventsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      googleCalendarEventsLoadingMore = false;
      notifyListeners();
    }
  }

  int get myTodayTasksProgressTotal {
    if (_myTodayTasksOpenBaseline > 0) return _myTodayTasksOpenBaseline;
    return myTodayTasksTotal;
  }

  int get myTodayTasksProgressCompleted {
    final inList = myTodayTasks
        .where((task) => task.status.trim().toLowerCase() == 'completed')
        .length;
    if (_myTodayTasksOpenBaseline <= 0) return inList;
    final fromOpenDelta = (_myTodayTasksOpenBaseline - myTodayTasksTotal).clamp(
      0,
      _myTodayTasksOpenBaseline,
    );
    return inList > fromOpenDelta ? inList : fromOpenDelta;
  }

  double get myTodayTasksProgressFraction {
    final total = myTodayTasksProgressTotal;
    if (total <= 0) return 0;
    return (myTodayTasksProgressCompleted / total).clamp(0.0, 1.0);
  }

  void _syncMyTodayTasksProgressTotals() {
    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    if (_myTodayTasksProgressDayKey != dayKey) {
      _myTodayTasksProgressDayKey = dayKey;
      _myTodayTasksOpenBaseline = 0;
    }
    if (myTodayTasksTotal > _myTodayTasksOpenBaseline) {
      _myTodayTasksOpenBaseline = myTodayTasksTotal;
    }
  }

  void _resetMyTodayTasksProgressTotals() {
    _myTodayTasksProgressDayKey = null;
    _myTodayTasksOpenBaseline = 0;
  }

  List<TaskItem> _filterTasksAssignedToMe(List<TaskItem> items) {
    final userId = meData?.id;
    if (userId == null || userId <= 0) return const <TaskItem>[];
    return items.where((task) => task.isAssignedToUserId(userId)).toList();
  }

  void _applyMyTodayTasksPage(TasksPageData page, {required bool append}) {
    final assignedOnly = _filterTasksAssignedToMe(page.items);
    myTodayTasks = append ? <TaskItem>[...myTodayTasks, ...assignedOnly] : assignedOnly;
    myTodayTasksCurrentPage = page.currentPage;
    myTodayTasksLastPage = page.lastPage;
    myTodayTasksHasMore = page.hasMore || page.currentPage < page.lastPage;
    myTodayTasksTotal = myTodayTasks.length;
    _syncMyTodayTasksProgressTotals();
  }

  /// Next Up on homepage: earliest due date/time among open tasks.
  TaskItem? get homePriorityTask {
    if (myTodayTasks.isEmpty) return null;

    bool isOpen(TaskItem task) {
      switch (task.status.trim().toLowerCase()) {
        case 'completed':
        case 'cancelled':
        case 'rejected':
          return false;
        default:
          return true;
      }
    }

    DateTime? parseDue(TaskItem task) {
      final dateRaw = task.dueDate;
      if (dateRaw == null || dateRaw.trim().isEmpty) return null;

      DateTime? dateOnly;
      try {
        final normalized = dateRaw.contains(' ') ? dateRaw.replaceFirst(' ', 'T') : dateRaw;
        dateOnly = DateTime.parse(normalized).toLocal();
      } catch (_) {
        try {
          final head = dateRaw.split(' ').first.split('T').first;
          dateOnly = DateTime.parse(head).toLocal();
        } catch (_) {
          return null;
        }
      }

      final timeRaw = task.dueTime?.trim();
      if (timeRaw != null && timeRaw.isNotEmpty) {
        final parts = timeRaw.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null) {
            return DateTime(dateOnly.year, dateOnly.month, dateOnly.day, hour, minute);
          }
        }
      }

      if (dateRaw.contains(':') &&
          (dateRaw.toUpperCase().contains('AM') || dateRaw.toUpperCase().contains('PM'))) {
        return dateOnly;
      }

      return DateTime(dateOnly.year, dateOnly.month, dateOnly.day, 23, 59);
    }

    TaskItem? nearestTask;
    DateTime? nearestDue;

    for (final task in myTodayTasks) {
      if (!isOpen(task)) continue;
      final due = parseDue(task);
      if (due == null) continue;
      if (nearestDue == null || due.isBefore(nearestDue)) {
        nearestDue = due;
        nearestTask = task;
      }
    }

    if (nearestTask != null) return nearestTask;

    for (final task in myTodayTasks) {
      if (isOpen(task)) return task;
    }

    return myTodayTasks.first;
  }

  bool projectsLoading = false;
  bool projectsLoadingMore = false;
  String? projectsError;
  List<ProjectItem> projects = <ProjectItem>[];
  int projectsCurrentPage = 1;
  int projectsLastPage = 1;
  bool projectsHasMore = false;
  bool createProjectLoading = false;
  String? createProjectError;
  bool updateProjectLoading = false;
  String? updateProjectError;

  int? selectedProjectId;
  bool projectTasksMyTasksOnly = false;
  String? projectTasksStatusFilter;
  bool projectMembersLoading = false;
  String? projectMembersError;
  List<ProjectMember> projectMembers = <ProjectMember>[];
  bool projectTasksLoading = false;
  bool projectTasksLoadingMore = false;
  String? projectTasksError;
  List<TaskItem> projectTasks = <TaskItem>[];
  int projectTasksCurrentPage = 1;
  int projectTasksLastPage = 1;
  bool projectTasksHasMore = false;

  bool createNewsLoading = false;
  String? createNewsError;

  bool newsLoading = false;
  bool newsLoadingMore = false;
  String? newsError;
  List<NewsItem> newsItems = <NewsItem>[];
  int newsCurrentPage = 1;
  int newsLastPage = 1;
  bool newsHasMore = false;

  bool updateNewsLoading = false;
  String? updateNewsError;
  bool deleteNewsLoading = false;
  String? deleteNewsError;

  bool createEmployeeLoading = false;
  String? createEmployeeError;
  bool updateEmployeeLoading = false;
  String? updateEmployeeError;
  bool deleteEmployeeLoading = false;
  String? deleteEmployeeError;

  /// When set, [MainScreen] switches bottom navigation to this index (1 = Projects tab).
  int? pendingMainTabIndex;

  void requestSwitchToTasksTab() {
    pendingMainTabIndex = 1;
    notifyListeners();
  }

  /// Requests [MainScreen] to switch to the My Leave Requests bottom tab.
  void requestSwitchToLeaveTab() {
    pendingMainTabIndex = 2;
    notifyListeners();
  }

  /// Requests [MainScreen] to switch to the notifications bottom tab.
  void requestSwitchToNotificationsTab() {
    pendingMainTabIndex = 3;
    notifyListeners();
  }

  void clearPendingMainTabIndex() {
    pendingMainTabIndex = null;
  }

  String? lastFcmToken;

  /// Sends the FCM device token to the backend (best-effort, never throws).
  bool changePasswordLoading = false;
  String? changePasswordError;

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    changePasswordLoading = true;
    changePasswordError = null;
    notifyListeners();

    try {
      final token = await _token();

      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }

      final response = await _apiService.changePassword(
        token: token,
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      return response;
    } catch (e) {
      changePasswordError = e.toString().replaceFirst('Exception: ', '');

      return false;
    } finally {
      changePasswordLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerFcmToken(
    String fcmToken, {
    required String platform,
    required String deviceName,
  }) async {
    lastFcmToken = fcmToken;
    try {
      final token = await _token();
      if (token == null || token.isEmpty) return;
      await _apiService.registerFcmDeviceToken(
        token: token,
        fcmToken: fcmToken,
        platform: platform,
        deviceName: deviceName,
      );
    } catch (_) {
      // Ignore: push registration should not disrupt app flow.
    }
  }

  /// Removes the FCM device token from the backend (best-effort, never throws).
  Future<void> unregisterFcmToken([String? fcmToken]) async {
    final tokenToRemove = fcmToken ?? lastFcmToken;
    if (tokenToRemove == null || tokenToRemove.isEmpty) return;

    try {
      final token = await _token();
      if (token == null || token.isEmpty) return;
      await _apiService.unregisterFcmDeviceToken(token: token, fcmToken: tokenToRemove);
    } catch (_) {
      // Ignore: push unregistration should not block logout.
    } finally {
      if (fcmToken == null || fcmToken == lastFcmToken) {
        lastFcmToken = null;
      }
    }
  }

  Future<LoginResponse?> login({required String email, required String password}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email: email, password: password);
      final token = response.data.token;
      await SessionStorage.writeToken(token);
      meData = MeData(
        id: response.data.user.id,
        name: response.data.user.name,
        email: response.data.user.email,
        role: response.data.user.role,
        departmentId: response.data.user.departmentId,
        isActive: true,
        department: null,
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

  Future<String?> _token() => SessionStorage.readToken();

  Future<NewsActionResponse?> createNews({required String title, required String content}) async {
    if (!AppRoles.canCreateNews(meData?.role)) {
      createNewsError = 'You do not have permission to create news.';
      notifyListeners();
      return null;
    }

    createNewsLoading = true;
    createNewsError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final response = await _apiService.createNews(token: token, title: title, content: content);
      return response;
    } catch (e) {
      createNewsError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      createNewsLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createEmployee({
    required String name,
    required String email,
    required String password,
    required String role,
    required int departmentId,
    String? phone,
    required bool isActive,
  }) async {
    if (!AppRoles.canCreateEmployee(meData?.role)) {
      createEmployeeError = 'You do not have permission to create employees.';
      notifyListeners();
      return null;
    }

    createEmployeeLoading = true;
    createEmployeeError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final response = await _apiService.createEmployee(
        token: token,
        name: name,
        email: email,
        password: password,
        role: role,
        departmentId: departmentId,
        phone: phone,
        isActive: isActive,
      );
      await loadUsers();
      await loadEmployees(refresh: true);
      return response;
    } catch (e) {
      createEmployeeError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      createEmployeeLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> updateEmployee({
    required int employeeId,
    required String name,
    required String role,
    required int departmentId,
    String? phone,
    required bool isActive,
  }) async {
    if (!AppRoles.canCreateEmployee(meData?.role)) {
      updateEmployeeError = 'You do not have permission to update employees.';
      notifyListeners();
      return null;
    }

    updateEmployeeLoading = true;
    updateEmployeeError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final response = await _apiService.updateEmployee(
        token: token,
        employeeId: employeeId,
        name: name,
        role: role,
        departmentId: departmentId,
        phone: phone,
        isActive: isActive,
      );
      await loadUsers();
      await loadEmployees(refresh: true);
      return response;
    } catch (e) {
      updateEmployeeError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      updateEmployeeLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> deleteEmployee({required int employeeId}) async {
    if (!AppRoles.canCreateEmployee(meData?.role)) {
      deleteEmployeeError = 'You do not have permission to delete employees.';
      notifyListeners();
      return null;
    }

    deleteEmployeeLoading = true;
    deleteEmployeeError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final response = await _apiService.deleteEmployee(token: token, employeeId: employeeId);
      await loadUsers();
      await loadEmployees(refresh: true);
      return response;
    } catch (e) {
      deleteEmployeeError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      deleteEmployeeLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboard({bool silent = false}) async {
    if (!silent) {
      dashboardLoading = true;
      dashboardError = null;
      notifyListeners();
    }

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      dashboardData = await _apiService.dashboard(token: token);
    } catch (e) {
      if (!silent) {
        dashboardError = e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      if (!silent) {
        dashboardLoading = false;
      }
      notifyListeners();
    }
  }

  /// Updates Work Pulse, leave balances, Today's glance, and Next Up without blocking UI.
  Future<void> refreshHomeScreenDataInBackground() async {
    await Future.wait<void>([
      loadMe(),
      loadDashboard(silent: true),
      loadMyTodayTasks(refresh: true, applyPriorityFilter: false, silent: true),
    ]);
  }

  void _scheduleHomeScreenRefresh() {
    unawaited(refreshHomeScreenDataInBackground());
  }

  Future<void> loadNews({bool refresh = false}) async {
    if (newsLoading) return;
    newsLoading = true;
    if (refresh) {
      newsError = null;
      newsCurrentPage = 1;
      newsLastPage = 1;
      newsHasMore = false;
    }
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }

      final page = await _apiService.news(token: token, page: 1);
      newsItems = page.items;
      newsCurrentPage = page.currentPage;
      newsLastPage = page.lastPage;
      newsHasMore = newsCurrentPage < newsLastPage;
    } catch (e) {
      newsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      newsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreNews() async {
    if (newsLoadingMore || newsLoading || !newsHasMore) return;
    newsLoadingMore = true;
    newsError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }

      final nextPage = newsCurrentPage + 1;
      final page = await _apiService.news(token: token, page: nextPage);
      newsItems = <NewsItem>[...newsItems, ...page.items];
      newsCurrentPage = page.currentPage;
      newsLastPage = page.lastPage;
      newsHasMore = newsCurrentPage < newsLastPage;
    } catch (e) {
      newsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      newsLoadingMore = false;
      notifyListeners();
    }
  }

  Future<NewsActionResponse?> updateNews({
    required String newsId,
    required String title,
    required String content,
    required String status,
  }) async {
    if (!AppRoles.canEditNews(meData?.role)) {
      updateNewsError = 'You do not have permission to edit news.';
      notifyListeners();
      return null;
    }

    updateNewsLoading = true;
    updateNewsError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }

      final response = await _apiService.updateNews(
        token: token,
        newsId: newsId,
        title: title,
        content: content,
        status: status,
      );

      await loadNews(refresh: true);
      return response;
    } catch (e) {
      updateNewsError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      updateNewsLoading = false;
      notifyListeners();
    }
  }

  Future<NewsActionResponse?> deleteNews({required String newsId}) async {
    if (!AppRoles.canDeleteNews(meData?.role)) {
      deleteNewsError = 'You do not have permission to delete news.';
      notifyListeners();
      return null;
    }

    deleteNewsLoading = true;
    deleteNewsError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }

      final response = await _apiService.deleteNews(token: token, newsId: newsId);
      await loadNews(refresh: true);
      return response;
    } catch (e) {
      deleteNewsError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      deleteNewsLoading = false;
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
        await unregisterFcmToken();
        await _apiService.logout(token: token);
      }

      await SessionStorage.clearToken();
      await GoogleCalendarAuthService.instance.disconnect();
      await GoogleCalendarSessionStorage.clear();
      _resetGoogleCalendarState();
      _resetMyTodayTasksProgressTotals();
      dashboardData = null;
      meData = null;
      todayGlanceTab = TodayGlanceTab.tasks;
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

      final useSimpleJsonBody = AppRoles.usesSimpleLeaveApply(meData?.role);
      String? userId;
      if (!useSimpleJsonBody) {
        userId = meData?.id.toString() ?? '';
        if (userId.isEmpty) {
          meData = await _apiService.me(token: token);
          userId = meData?.id.toString() ?? '';
        }
        if (userId.isEmpty) {
          throw Exception('User id not found. Please login again.');
        }
      }

      return await _apiService.applyLeave(
        token: token,
        userId: userId,
        leaveTypeId: leaveTypeId,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        attachmentPath: useSimpleJsonBody ? null : attachmentPath,
        useSimpleJsonBody: useSimpleJsonBody,
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
      final page = AppRoles.isCeoOrHrLike(role)
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

  Future<void> loadLeaveReport({
    bool refresh = true,
    String? employeeId,
    String? departmentId,
    String? leaveTypeId,
    String? status,
    String? from,
    String? to,
  }) async {
    if (!AppRoles.canViewLeaveReport(meData?.role)) {
      leaveReportError = 'You do not have permission to view leave reports.';
      notifyListeners();
      return;
    }
    if (leaveReportLoading) return;

    leaveReportLoading = true;
    leaveReportError = null;
    if (refresh) {
      leaveReportItems = <LeaveReportItem>[];
      leaveReportCurrentPage = 1;
      leaveReportLastPage = 1;
      leaveReportTotal = 0;
      leaveReportHasMore = false;
    }

    _leaveReportEmployeeId = employeeId;
    _leaveReportDepartmentId = departmentId;
    _leaveReportLeaveTypeId = leaveTypeId;
    _leaveReportStatus = status;
    _leaveReportFrom = from;
    _leaveReportTo = to;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final page = await _apiService.leaveReport(
        token: token,
        employeeId: employeeId,
        departmentId: departmentId,
        leaveTypeId: leaveTypeId,
        status: status,
        from: from,
        to: to,
        page: 1,
      );
      leaveReportItems = page.items;
      leaveReportCurrentPage = page.currentPage;
      leaveReportLastPage = page.lastPage;
      leaveReportTotal = page.total;
      leaveReportHasMore = page.hasMore;
    } catch (e) {
      leaveReportError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      leaveReportLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreLeaveReport() async {
    if (leaveReportLoadingMore || leaveReportLoading || !leaveReportHasMore) return;
    leaveReportLoadingMore = true;
    leaveReportError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final nextPage = leaveReportCurrentPage + 1;
      final page = await _apiService.leaveReport(
        token: token,
        employeeId: _leaveReportEmployeeId,
        departmentId: _leaveReportDepartmentId,
        leaveTypeId: _leaveReportLeaveTypeId,
        status: _leaveReportStatus,
        from: _leaveReportFrom,
        to: _leaveReportTo,
        page: nextPage,
      );
      leaveReportItems = <LeaveReportItem>[...leaveReportItems, ...page.items];
      leaveReportCurrentPage = page.currentPage;
      leaveReportLastPage = page.lastPage;
      leaveReportTotal = page.total;
      leaveReportHasMore = page.hasMore;
    } catch (e) {
      leaveReportError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      leaveReportLoadingMore = false;
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

  Future<String?> approveLeaveRequest({required String approvalId, required String remarks}) async {
    approvalActionLoading = true;
    approvalActionError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final message = await _apiService.approveLeaveRequest(
        token: token,
        approvalId: approvalId,
        remarks: remarks,
      );
      await loadDashboard();
      return message;
    } catch (e) {
      approvalActionError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      approvalActionLoading = false;
      notifyListeners();
    }
  }

  Future<String?> rejectLeaveRequest({required String approvalId, required String remarks}) async {
    approvalActionLoading = true;
    approvalActionError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final message = await _apiService.rejectLeaveRequest(
        token: token,
        approvalId: approvalId,
        remarks: remarks,
      );
      await loadDashboard();
      return message;
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
      await loadNotifications(refresh: true);
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
                  relatedId: n.relatedId,
                  taskId: n.taskId,
                  leaveRequestId: n.leaveRequestId,
                  data: n.data,
                )
              : n,
        )
        .toList();
    notifications = updated;
  }

  Future<String?> readNotification({required String notificationId}) async {
    // Avoid duplicate API calls if already marked read.
    final alreadyRead = notifications.any((n) => n.id == notificationId && n.isRead);
    if (alreadyRead) return 'Already read';

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
      final msg = await _apiService.readNotification(token: token, notificationId: notificationId);
      await loadUnreadCount();
      return msg;
    } catch (e) {
      notificationReadError = e.toString().replaceFirst('Exception: ', '');
      await loadNotifications(refresh: true);
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

  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      notificationsCurrentPage = 1;
      notificationsLastPage = 1;
      notificationsTotal = 0;
      notificationsHasMore = false;
      notifications = <AppNotificationItem>[];
    }

    notificationsLoading = true;
    notificationsError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final page = await _apiService.notifications(token: token, page: 1, perPage: 10);
      notifications = page.items;
      notificationsCurrentPage = page.currentPage;
      notificationsLastPage = page.lastPage;
      notificationsTotal = page.total;
      notificationsHasMore = page.hasMore;
      await loadUnreadCount();
    } catch (e) {
      notificationsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      notificationsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreNotifications() async {
    if (notificationsLoadingMore || notificationsLoading || !notificationsHasMore) return;

    notificationsLoadingMore = true;
    notificationsError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final nextPage = notificationsCurrentPage + 1;
      final page = await _apiService.notifications(token: token, page: nextPage, perPage: 10);
      notifications = <AppNotificationItem>[...notifications, ...page.items];
      notificationsCurrentPage = page.currentPage;
      notificationsLastPage = page.lastPage;
      notificationsTotal = page.total;
      notificationsHasMore = page.hasMore;
    } catch (e) {
      notificationsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      notificationsLoadingMore = false;
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

  Future<void> loadEmployees({bool refresh = false}) async {
    if (employeesLoading) return;
    employeesLoading = true;
    if (refresh) {
      employeesError = null;
      employeesCurrentPage = 1;
      employeesLastPage = 1;
      employeesTotal = 0;
      employeesHasMore = false;
    }
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final page = await _apiService.employees(token: token, page: 1, perPage: 20);
      employees = page.items;
      employeesCurrentPage = page.currentPage;
      employeesLastPage = page.lastPage;
      employeesTotal = page.total;
      employeesHasMore = page.hasMore;
    } catch (e) {
      employeesError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      employeesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreEmployees() async {
    if (employeesLoadingMore || employeesLoading || !employeesHasMore) return;
    employeesLoadingMore = true;
    employeesError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final nextPage = employeesCurrentPage + 1;
      final page = await _apiService.employees(token: token, page: nextPage, perPage: 20);
      employees = <AppUserItem>[...employees, ...page.items];
      employeesCurrentPage = page.currentPage;
      employeesLastPage = page.lastPage;
      employeesTotal = page.total;
      employeesHasMore = page.hasMore;
    } catch (e) {
      employeesError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      employeesLoadingMore = false;
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
    required List<int> assignedUserIds,
    required String departmentId,
    required String startDate,
    required String startTime,
    required String dueDate,
    required String dueTime,
    required int estimatedHours,
    List<String> links = const <String>[],
    List<String> attachmentFilePaths = const <String>[],
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
        assignedUserIds: assignedUserIds,
        departmentId: departmentId,
        startDate: startDate,
        startTime: startTime,
        dueDate: dueDate,
        dueTime: dueTime,
        estimatedHours: estimatedHours,
        links: links,
        attachmentFilePaths: attachmentFilePaths,
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

  Future<CreateTaskResponse?> createProjectTask({
    required int projectId,
    required String title,
    required String description,
    required String priority,
    required List<int> assignedUserIds,
    required String startDate,
    required String startTime,
    required String dueDate,
    required String dueTime,
    required int estimatedHours,
    List<String> links = const <String>[],
    List<String> attachmentFilePaths = const <String>[],
  }) async {
    createTaskLoading = true;
    createTaskError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final response = await _apiService.createProjectTask(
        token: token,
        projectId: projectId,
        title: title,
        description: description,
        priority: priority,
        assignedUserIds: assignedUserIds,
        startDate: startDate,
        startTime: startTime,
        dueDate: dueDate,
        dueTime: dueTime,
        estimatedHours: estimatedHours,
        links: links,
        attachmentFilePaths: attachmentFilePaths,
      );
      await loadProjectTasks(projectId: projectId, refresh: true);
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
      _scheduleHomeScreenRefresh();
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
      return await _apiService.addTaskComment(token: token, taskId: taskId, comment: comment);
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
      await Future.wait(<Future<void>>[
        loadTasks(refresh: true),
        loadOutgoingSupportingTasks(),
        loadIncomingSupportingTasks(),
      ]);
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

  Future<void> setMyTodayTasksPriorityFilter(String? priority) async {
    myTodayTasksPriorityFilter = priority;
    notifyListeners();
    await loadMyTodayTasks(refresh: true);
  }

  Future<void> loadMyTodayTasks({
    bool refresh = false,
    bool applyPriorityFilter = true,
    bool silent = false,
  }) async {
    if (refresh) {
      myTodayTasksCurrentPage = 1;
      myTodayTasksLastPage = 1;
      myTodayTasksTotal = 0;
      myTodayTasksHasMore = false;
      if (!silent) {
        myTodayTasks = <TaskItem>[];
      }
    }

    if (!silent) {
      myTodayTasksLoading = true;
      myTodayTasksError = null;
      notifyListeners();
    }

    try {
      if (meData == null) {
        await loadMe();
      }
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final page = await _apiService.myPendingDueTasks(
        token: token,
        page: 1,
        priority: applyPriorityFilter ? myTodayTasksPriorityFilter : null,
        myTasksOnly: true,
      );
      _applyMyTodayTasksPage(page, append: false);
    } catch (e) {
      if (!silent) {
        myTodayTasksError = e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      if (!silent) {
        myTodayTasksLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> loadMoreMyTodayTasks() async {
    if (myTodayTasksLoadingMore || myTodayTasksLoading || !myTodayTasksHasMore) return;

    myTodayTasksLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = myTodayTasksCurrentPage + 1;
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      if (meData == null) {
        await loadMe();
      }
      final page = await _apiService.myPendingDueTasks(
        token: token,
        page: nextPage,
        priority: myTodayTasksPriorityFilter,
        myTasksOnly: true,
      );
      _applyMyTodayTasksPage(page, append: true);
    } catch (e) {
      myTodayTasksError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      myTodayTasksLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadProjects({bool refresh = false}) async {
    if (refresh) {
      projectsCurrentPage = 1;
      projectsLastPage = 1;
      projectsHasMore = false;
    }

    projectsLoading = true;
    projectsError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final page = await _apiService.projects(token: token, page: 1);
      projects = page.items;
      projectsCurrentPage = page.currentPage;
      projectsLastPage = page.lastPage;
      projectsHasMore = page.hasMore;
    } catch (e) {
      projectsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      projectsLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createProject({
    required String name,
    required String description,
    required String status,
    required String startDate,
    required String dueDate,
    required List<int> memberIds,
  }) async {
    if (!AppRoles.canManageProjects(meData?.role)) {
      createProjectError = 'You do not have permission to create projects.';
      notifyListeners();
      return null;
    }

    createProjectLoading = true;
    createProjectError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final response = await _apiService.createProject(
        token: token,
        name: name,
        description: description,
        status: status,
        startDate: startDate,
        dueDate: dueDate,
        memberIds: memberIds,
      );
      await loadProjects(refresh: true);
      return response;
    } catch (e) {
      createProjectError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      createProjectLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> updateProject({
    required int projectId,
    required String name,
    required String description,
    required String status,
    required String startDate,
    required String dueDate,
    required List<int> memberIds,
  }) async {
    if (!AppRoles.canManageProjects(meData?.role)) {
      updateProjectError = 'You do not have permission to edit projects.';
      notifyListeners();
      return null;
    }

    updateProjectLoading = true;
    updateProjectError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final response = await _apiService.updateProject(
        token: token,
        projectId: projectId,
        name: name,
        description: description,
        status: status,
        startDate: startDate,
        dueDate: dueDate,
        memberIds: memberIds,
      );
      await loadProjects(refresh: true);
      return response;
    } catch (e) {
      updateProjectError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      updateProjectLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreProjects() async {
    if (projectsLoadingMore || projectsLoading || !projectsHasMore) return;

    projectsLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = projectsCurrentPage + 1;
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final page = await _apiService.projects(token: token, page: nextPage);
      projects = <ProjectItem>[...projects, ...page.items];
      projectsCurrentPage = page.currentPage;
      projectsLastPage = page.lastPage;
      projectsHasMore = page.hasMore;
    } catch (e) {
      projectsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      projectsLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadProjectMembers({required int projectId}) async {
    projectMembersLoading = true;
    projectMembersError = null;
    projectMembers = <ProjectMember>[];
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      projectMembers = await _apiService.projectMembers(token: token, projectId: projectId);
    } catch (e) {
      projectMembersError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      projectMembersLoading = false;
      notifyListeners();
    }
  }

  Future<void> setProjectTasksFilter({required int projectId, required String filter}) async {
    switch (filter) {
      case 'my_tasks':
        projectTasksMyTasksOnly = true;
        projectTasksStatusFilter = null;
        break;
      case 'all':
        projectTasksMyTasksOnly = false;
        projectTasksStatusFilter = null;
        break;
      default:
        // Any other value is passed through as a `status` query param.
        projectTasksMyTasksOnly = false;
        projectTasksStatusFilter = filter;
        break;
    }
    await loadProjectTasks(projectId: projectId, refresh: true);
  }

  Future<void> loadProjectTasks({required int projectId, bool refresh = false}) async {
    if (refresh) {
      projectTasksCurrentPage = 1;
      projectTasksLastPage = 1;
      projectTasksHasMore = false;
      projectTasks = <TaskItem>[];
    }

    selectedProjectId = projectId;
    projectTasksLoading = true;
    projectTasksError = null;
    notifyListeners();

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final page = await _apiService.projectTasks(
        token: token,
        projectId: projectId,
        page: 1,
        myTasks: projectTasksMyTasksOnly,
        status: projectTasksStatusFilter,
      );
      projectTasks = page.items;
      projectTasksCurrentPage = page.currentPage;
      projectTasksLastPage = page.lastPage;
      projectTasksHasMore = page.hasMore;
    } catch (e) {
      projectTasksError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      projectTasksLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreProjectTasks() async {
    if (projectTasksLoadingMore ||
        projectTasksLoading ||
        !projectTasksHasMore ||
        selectedProjectId == null) {
      return;
    }

    projectTasksLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = projectTasksCurrentPage + 1;
      final token = await _token();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final page = await _apiService.projectTasks(
        token: token,
        projectId: selectedProjectId!,
        page: nextPage,
        myTasks: projectTasksMyTasksOnly,
        status: projectTasksStatusFilter,
      );
      projectTasks = <TaskItem>[...projectTasks, ...page.items];
      projectTasksCurrentPage = page.currentPage;
      projectTasksLastPage = page.lastPage;
      projectTasksHasMore = page.hasMore;
    } catch (e) {
      projectTasksError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      projectTasksLoadingMore = false;
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
