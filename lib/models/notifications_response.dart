class NotificationsResponse {
  const NotificationsResponse({required this.success, required this.data});

  final bool success;
  final NotificationsPageData data;

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      success: json['success'] == true,
      data: NotificationsPageData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}

class NotificationsPageData {
  const NotificationsPageData({
    required this.currentPage,
    required this.items,
    required this.from,
    required this.lastPage,
    required this.perPage,
    required this.to,
    required this.total,
    required this.firstPageUrl,
    required this.lastPageUrl,
    required this.nextPageUrl,
    required this.prevPageUrl,
    required this.path,
    required this.links,
  });

  final int currentPage;
  final List<AppNotificationItem> items;
  final int? from;
  final int lastPage;
  final int perPage;
  final int? to;
  final int total;
  final String firstPageUrl;
  final String lastPageUrl;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final String path;
  final List<NotificationPageLink> links;

  factory NotificationsPageData.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = rawList is List
        ? rawList
              .whereType<Map<String, dynamic>>()
              .map(AppNotificationItem.fromJson)
              .toList()
        : <AppNotificationItem>[];
    final linksRaw = json['links'];

    return NotificationsPageData(
      currentPage: _toInt(json['current_page']),
      items: items,
      from: _toNullableInt(json['from']),
      lastPage: _toInt(json['last_page']),
      perPage: _toInt(json['per_page']),
      to: _toNullableInt(json['to']),
      total: _toInt(json['total']),
      firstPageUrl: (json['first_page_url'] ?? '').toString(),
      lastPageUrl: (json['last_page_url'] ?? '').toString(),
      nextPageUrl: json['next_page_url']?.toString(),
      prevPageUrl: json['prev_page_url']?.toString(),
      path: (json['path'] ?? '').toString(),
      links: linksRaw is List
          ? linksRaw
                .whereType<Map<String, dynamic>>()
                .map(NotificationPageLink.fromJson)
                .toList()
          : <NotificationPageLink>[],
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class NotificationPageLink {
  const NotificationPageLink({
    required this.url,
    required this.label,
    required this.active,
  });

  final String? url;
  final String label;
  final bool active;

  factory NotificationPageLink.fromJson(Map<String, dynamic> json) {
    return NotificationPageLink(
      url: json['url']?.toString(),
      label: (json['label'] ?? '').toString(),
      active: json['active'] == true,
    );
  }
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    required this.readAt,
    required this.relatedId,
    required this.taskId,
    required this.leaveRequestId,
    required this.data,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? createdAt;
  final String? updatedAt;
  final String? readAt;
  final String? relatedId;
  final String? taskId;
  final String? leaveRequestId;
  final Map<String, dynamic> data;

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final isRead = _toBool(json['is_read']);
    final dataRaw = json['data'];
    Map<String, dynamic> data = <String, dynamic>{};
    if (dataRaw is Map<String, dynamic>) {
      data = Map<String, dynamic>.from(dataRaw);
    } else if (dataRaw is Map) {
      data = dataRaw.map((key, value) => MapEntry(key.toString(), value));
    }

    final taskId = _firstNonEmpty(<dynamic>[
      json['task_id'],
      json['taskId'],
      data['task_id'],
      data['taskId'],
    ]);
    final leaveRequestId = _firstNonEmpty(<dynamic>[
      json['leave_request_id'],
      json['leaveRequestId'],
      json['leave_id'],
      json['leaveId'],
      data['leave_request_id'],
      data['leaveRequestId'],
      data['leave_id'],
      data['leaveId'],
    ]);
    final relatedId = _firstNonEmpty(<dynamic>[
      taskId,
      leaveRequestId,
      json['related_id'],
      json['entity_id'],
      json['notifiable_id'],
      json['reference_id'],
      data['related_id'],
      data['entity_id'],
      data['id'],
    ]);

    return AppNotificationItem(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      title: (json['title'] ?? json['subject'] ?? 'Notification').toString(),
      message: (json['message'] ?? json['body'] ?? '').toString(),
      type: (json['type'] ?? data['type'] ?? data['notification_type'] ?? 'info').toString(),
      isRead: isRead,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      readAt: json['read_at']?.toString(),
      relatedId: relatedId,
      taskId: taskId,
      leaveRequestId: leaveRequestId,
      data: data,
    );
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return null;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return raw == '1' || raw == 'true' || raw == 'yes';
  }
}
