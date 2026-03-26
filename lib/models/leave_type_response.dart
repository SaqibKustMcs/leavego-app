class LeaveTypeResponse {
  const LeaveTypeResponse({required this.success, required this.data});

  final bool success;
  final List<LeaveTypeItem> data;

  factory LeaveTypeResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = rawList is List
        ? rawList.whereType<Map<String, dynamic>>().map(LeaveTypeItem.fromJson).toList()
        : <LeaveTypeItem>[];
    return LeaveTypeResponse(success: json['success'] == true, data: items);
  }
}

class LeaveTypeItem {
  const LeaveTypeItem({
    required this.id,
    required this.name,
    required this.code,

    required this.requiresAttachment,
  });

  final String id;
  final String name;
  final String code;

  final bool requiresAttachment;

  factory LeaveTypeItem.fromJson(Map<String, dynamic> json) {
    return LeaveTypeItem(
      code: (json['code'] ?? '').toString(),
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      requiresAttachment: _toBool(json['requires_attachment']),
    );
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }
}
