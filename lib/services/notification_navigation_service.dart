import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/notifications_response.dart';
import 'package:leavego_app/ui/screens/leave_detail_screen.dart';
import 'package:leavego_app/ui/screens/my_leave_requests_screen.dart';
import 'package:leavego_app/ui/screens/my_today_tasks_screen.dart';
import 'package:leavego_app/ui/screens/news_detail_screen.dart';
import 'package:leavego_app/ui/screens/news_screen.dart';
import 'package:leavego_app/ui/screens/task_detail_screen.dart';

/// Where a notification payload should take the user.
enum NotificationDestination {
  taskDetail,
  leaveDetail,
  news,
  projectsTab,
  taskList,
  leaveList,
  notificationsTab,
}

class NotificationRoute {
  const NotificationRoute(this.destination, {this.id});

  final NotificationDestination destination;
  final String? id;
}

/// Routes users to the related screen from push or in-app notifications.
class NotificationNavigationService {
  NotificationNavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Map<String, dynamic>? _pendingPayload;

  static NavigatorState? get _navigator => navigatorKey.currentState;

  /// Call after login / main screen is ready to flush any cold-start notification.
  static Future<void> flushPending() async {
    final pending = _pendingPayload;
    if (pending == null) return;
    _pendingPayload = null;
    await openFromPayload(rawData: Map<String, dynamic>.from(pending));
  }

  static Future<void> openFromRemoteMessage(RemoteMessage message) async {
    await openFromPayload(rawData: payloadFromRemoteMessage(message));
  }

  /// FCM keeps the title/body outside the data block, but routing falls back to
  /// keyword matching on them, so they are merged in without shadowing data keys.
  static Map<String, dynamic> payloadFromRemoteMessage(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    final title = message.notification?.title;
    final body = message.notification?.body;
    if (title != null && title.trim().isNotEmpty) {
      data.putIfAbsent('title', () => title);
    }
    if (body != null && body.trim().isNotEmpty) {
      data.putIfAbsent('body', () => body);
    }
    return data;
  }

  static Future<void> openFromInAppNotification(AppNotificationItem item) async {
    final data = <String, dynamic>{
      ...item.data,
      'type': item.type,
      'notification_type': item.type,
      if (item.taskId != null) 'task_id': item.taskId,
      if (item.leaveRequestId != null) 'leave_request_id': item.leaveRequestId,
      if (item.relatedId != null) 'related_id': item.relatedId,
      'title': item.title,
      'message': item.message,
    };
    await openFromPayload(rawData: data);
  }

  static Future<void> openFromPayload({
    Map<String, dynamic>? rawData,
    String? type,
    String? entityId,
  }) async {
    final data = <String, dynamic>{...?rawData};
    if (type != null && type.trim().isNotEmpty) {
      data.putIfAbsent('type', () => type.trim());
    }
    if (entityId != null && entityId.trim().isNotEmpty) {
      data.putIfAbsent('related_id', () => entityId.trim());
    }

    // Cold start: the navigator only exists once the app shell is built.
    if (_navigator == null) {
      _pendingPayload = data;
      return;
    }

    final route = resolveRoute(data);
    switch (route.destination) {
      case NotificationDestination.taskDetail:
        await _push(TaskDetailScreen(taskId: route.id!));
      case NotificationDestination.leaveDetail:
        await _push(LeaveDetailScreen(leaveId: route.id!, enableActions: true));
      case NotificationDestination.news:
        await _push(_newsScreenFor(route.id));
      case NotificationDestination.taskList:
        await _push(const MyTodayTasksScreen());
      case NotificationDestination.leaveList:
        await _push(const MyLeaveRequestsScreen());
      case NotificationDestination.projectsTab:
        _openTab(_TabRequest.projects);
      case NotificationDestination.notificationsTab:
        _openTab(_TabRequest.notifications);
    }
  }

  /// Maps a payload to its destination. Kept free of navigation side effects so
  /// the routing rules can be unit tested.
  static NotificationRoute resolveRoute(Map<String, dynamic> data) {
    final taskId = _firstNonEmpty(data, const ['task_id', 'taskId']);
    if (taskId != null) {
      return NotificationRoute(NotificationDestination.taskDetail, id: taskId);
    }

    final leaveRequestId = _firstNonEmpty(data, const [
      'leave_request_id',
      'leaveRequestId',
      'leave_id',
      'leaveId',
    ]);
    if (leaveRequestId != null) {
      return NotificationRoute(NotificationDestination.leaveDetail, id: leaveRequestId);
    }

    final haystack = _haystack(data);

    // Checked before news so a project payload is never matched as an announcement.
    if (data.containsKey('project_id') || haystack.contains('project')) {
      return const NotificationRoute(NotificationDestination.projectsTab);
    }

    final newsId = _firstNonEmpty(data, const ['news_id', 'newsId']);
    if (newsId != null || haystack.contains('news') || haystack.contains('announcement')) {
      return NotificationRoute(NotificationDestination.news, id: newsId);
    }

    // No id to open a detail screen with, so fall back to the matching list.
    if (haystack.contains('task')) {
      return const NotificationRoute(NotificationDestination.taskList);
    }
    if (haystack.contains('leave') || haystack.contains('approval')) {
      return const NotificationRoute(NotificationDestination.leaveList);
    }

    return const NotificationRoute(NotificationDestination.notificationsTab);
  }

  /// Opens the news detail when the item is already loaded, otherwise the list.
  static Widget _newsScreenFor(String? newsId) {
    if (newsId != null && Get.isRegistered<AppController>()) {
      for (final item in Get.find<AppController>().newsItems) {
        if (item.id == newsId) return NewsDetailScreen(news: item);
      }
    }
    return const NewsScreen();
  }

  static Future<void> _push(Widget screen) async {
    final navigator = _navigator;
    if (navigator == null) return;
    await navigator.push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Bottom navigation tabs have no back button, so they are reached by
  /// clearing pushed routes and switching the tab instead of pushing them.
  static void _openTab(_TabRequest tab) {
    if (!Get.isRegistered<AppController>()) return;
    _navigator?.popUntil((route) => route.isFirst);
    final controller = Get.find<AppController>();
    switch (tab) {
      case _TabRequest.projects:
        controller.requestSwitchToTasksTab();
      case _TabRequest.notifications:
        controller.requestSwitchToNotificationsTab();
    }
  }

  static String? _resolveType(Map<String, dynamic> data) {
    for (final key in const [
      'type',
      'notification_type',
      'category',
      'module',
      'event',
      'entity_type',
    ]) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String _haystack(Map<String, dynamic> data) {
    return <String>[
      _resolveType(data) ?? '',
      data['title']?.toString() ?? '',
      data['message']?.toString() ?? '',
      data['body']?.toString() ?? '',
    ].join(' ').toLowerCase();
  }

  static String? _firstNonEmpty(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return null;
  }
}

enum _TabRequest { projects, notifications }
