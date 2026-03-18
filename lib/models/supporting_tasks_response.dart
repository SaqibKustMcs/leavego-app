class SupportingTasksResponse {
  const SupportingTasksResponse({
    required this.success,
    required this.data,
  });

  final bool success;
  final SupportingTasksPageData data;

  factory SupportingTasksResponse.fromJson(Map<String, dynamic> json) {
    return SupportingTasksResponse(
      success: json['success'] == true,
      data: SupportingTasksPageData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}

class SupportingTasksPageData {
  const SupportingTasksPageData({
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
  final List<SupportingTaskItem> items;
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
  final List<SupportingTasksPageLink> links;

  factory SupportingTasksPageData.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = rawList is List
        ? rawList
              .whereType<Map<String, dynamic>>()
              .map(SupportingTaskItem.fromJson)
              .toList()
        : <SupportingTaskItem>[];
    final linksRaw = json['links'];

    return SupportingTasksPageData(
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
                .map(SupportingTasksPageLink.fromJson)
                .toList()
          : <SupportingTasksPageLink>[],
    );
  }
}

class SupportingTaskItem {
  const SupportingTaskItem({
    required this.id,
    required this.taskId,
    required this.requestedBy,
    required this.requestedTo,
    required this.message,
    required this.timelineNote,
    required this.status,
    required this.responseMessage,
    required this.acceptedAt,
    required this.declinedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.task,
    required this.receiver,
    required this.requester,
  });

  final int id;
  final String? taskId;
  final String? requestedBy;
  final String? requestedTo;
  final String? message;
  final String timelineNote;
  final String status;
  final String? responseMessage;
  final String? acceptedAt;
  final String? declinedAt;
  final String? createdAt;
  final String? updatedAt;
  final SupportingTaskSummary? task;
  final SupportingTaskUserSummary? receiver;
  final SupportingTaskUserSummary? requester;

  factory SupportingTaskItem.fromJson(Map<String, dynamic> json) {
    return SupportingTaskItem(
      id: _toInt(json['id']),
      taskId: json['task_id']?.toString(),
      requestedBy: json['requested_by']?.toString(),
      requestedTo: json['requested_to']?.toString(),
      message: json['message']?.toString(),
      timelineNote:
          (json['timeline_note'] ?? json['message'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      responseMessage: json['response_message']?.toString(),
      acceptedAt: json['accepted_at']?.toString(),
      declinedAt: json['declined_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      task: json['task'] is Map<String, dynamic>
          ? SupportingTaskSummary.fromJson(json['task'] as Map<String, dynamic>)
          : null,
      receiver: json['receiver'] is Map<String, dynamic>
          ? SupportingTaskUserSummary.fromJson(
              json['receiver'] as Map<String, dynamic>,
            )
          : null,
      requester: json['requester'] is Map<String, dynamic>
          ? SupportingTaskUserSummary.fromJson(
              json['requester'] as Map<String, dynamic>,
            )
          : json['sender'] is Map<String, dynamic>
              ? SupportingTaskUserSummary.fromJson(
                  json['sender'] as Map<String, dynamic>,
                )
              : null,
    );
  }
}

class SupportingTaskSummary {
  const SupportingTaskSummary({
    required this.id,
    required this.title,
    required this.status,
  });

  final int id;
  final String title;
  final String status;

  factory SupportingTaskSummary.fromJson(Map<String, dynamic> json) {
    return SupportingTaskSummary(
      id: _toInt(json['id']),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class SupportingTaskUserSummary {
  const SupportingTaskUserSummary({
    required this.id,
    required this.name,
    required this.email,
  });

  final int id;
  final String name;
  final String email;

  factory SupportingTaskUserSummary.fromJson(Map<String, dynamic> json) {
    return SupportingTaskUserSummary(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}

class SupportingTasksPageLink {
  const SupportingTasksPageLink({
    required this.url,
    required this.label,
    required this.active,
  });

  final String? url;
  final String label;
  final bool active;

  factory SupportingTasksPageLink.fromJson(Map<String, dynamic> json) {
    return SupportingTasksPageLink(
      url: json['url']?.toString(),
      label: (json['label'] ?? '').toString(),
      active: json['active'] == true,
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}
