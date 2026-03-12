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

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final isRead = _toBool(json['is_read']);
    return AppNotificationItem(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      title: (json['title'] ?? json['subject'] ?? 'Notification').toString(),
      message: (json['message'] ?? json['body'] ?? '').toString(),
      type: (json['type'] ?? 'info').toString(),
      isRead: isRead,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      readAt: json['read_at']?.toString(),
    );
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return raw == '1' || raw == 'true' || raw == 'yes';
  }
}
