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
    required this.total,
  });

  final int currentPage;
  final List<AppNotificationItem> items;
  final int total;

  factory NotificationsPageData.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = rawList is List
        ? rawList
              .whereType<Map<String, dynamic>>()
              .map(AppNotificationItem.fromJson)
              .toList()
        : <AppNotificationItem>[];

    return NotificationsPageData(
      currentPage: _toInt(json['current_page']),
      items: items,
      total: _toInt(json['total']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.readAt,
  });

  final String id;
  final String title;
  final String message;
  final String? createdAt;
  final String? readAt;

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['subject'] ?? 'Notification').toString(),
      message: (json['message'] ?? json['body'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
      readAt: json['read_at']?.toString(),
    );
  }
}
