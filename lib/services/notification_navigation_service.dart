import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:leavego_app/models/notifications_response.dart';
import 'package:leavego_app/ui/screens/leave_detail_screen.dart';
import 'package:leavego_app/ui/screens/news_screen.dart';
import 'package:leavego_app/ui/screens/task_detail_screen.dart';

/// Routes users to task / leave / news screens from push or in-app notifications.
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
    await openFromPayload(rawData: Map<String, dynamic>.from(message.data));
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

    final taskId = _firstNonEmpty(data, const [
      'task_id',
      'taskId',
    ]);
    final leaveRequestId = _firstNonEmpty(data, const [
      'leave_request_id',
      'leaveRequestId',
      'leave_id',
      'leaveId',
    ]);
    final resolvedType = (_resolveType(data) ?? '').toLowerCase();

    if (_navigator == null) {
      _pendingPayload = data;
      return;
    }

    // 1) Task notification with task id -> task detail
    if (taskId != null) {
      await _push(TaskDetailScreen(taskId: taskId));
      return;
    }

    // 2) Leave request notification with leave request id -> leave detail
    if (leaveRequestId != null) {
      await _push(LeaveDetailScreen(leaveId: leaveRequestId, enableActions: true));
      return;
    }

    // 3) Company news related -> news screen
    if (_isNewsNotification(resolvedType, data)) {
      await _push(const NewsScreen());
      return;
    }

    // Fallback by type keywords when ids are missing.
    if (resolvedType.contains('task') ||
        resolvedType.contains('project_task') ||
        resolvedType.contains('supporting_task')) {
      // No task id available — do not guess incorrectly.
      return;
    }
    if (resolvedType.contains('leave') || resolvedType.contains('approval')) {
      // Prefer detail only when leave request id exists; handled above.
      return;
    }
  }

  static Future<void> _push(Widget screen) async {
    final navigator = _navigator;
    if (navigator == null) return;
    await navigator.push(MaterialPageRoute(builder: (_) => screen));
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

  static bool _isNewsNotification(String type, Map<String, dynamic> data) {
    final haystack = <String>[
      type,
      data['title']?.toString().toLowerCase() ?? '',
      data['message']?.toString().toLowerCase() ?? '',
      data['body']?.toString().toLowerCase() ?? '',
    ].join(' ');

    return data.containsKey('news_id') ||
        haystack.contains('news') ||
        haystack.contains('announcement') ||
        haystack.contains('company news');
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
