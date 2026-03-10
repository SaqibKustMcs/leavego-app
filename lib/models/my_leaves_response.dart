class MyLeavesResponse {
  const MyLeavesResponse({required this.success, required this.data});

  final bool success;
  final MyLeavesPageData data;

  factory MyLeavesResponse.fromJson(Map<String, dynamic> json) {
    return MyLeavesResponse(
      success: json['success'] == true,
      data: MyLeavesPageData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}

class MyLeavesPageData {
  const MyLeavesPageData({
    required this.currentPage,
    required this.items,
    required this.total,
  });

  final int currentPage;
  final List<MyLeaveItem> items;
  final int total;

  factory MyLeavesPageData.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = rawList is List
        ? rawList
              .whereType<Map<String, dynamic>>()
              .map(MyLeaveItem.fromJson)
              .toList()
        : <MyLeaveItem>[];

    return MyLeavesPageData(
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

class MyLeaveItem {
  const MyLeaveItem({
    required this.id,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.status,
    required this.hodStatus,
    required this.hrStatus,
    required this.finalStatus,
    required this.createdAt,
    required this.attachment,
  });

  final String id;
  final String leaveTypeId;
  final String startDate;
  final String endDate;
  final int days;
  final String reason;
  final String status;
  final String hodStatus;
  final String hrStatus;
  final String finalStatus;
  final String createdAt;
  final String? attachment;

  factory MyLeaveItem.fromJson(Map<String, dynamic> json) {
    return MyLeaveItem(
      id: (json['id'] ?? '').toString(),
      leaveTypeId: (json['leave_type_id'] ?? '').toString(),
      startDate: (json['start_date'] ?? '').toString(),
      endDate: (json['end_date'] ?? '').toString(),
      days: _toInt(json['days']),
      reason: (json['reason'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      hodStatus: (json['hod_status'] ?? '').toString(),
      hrStatus: (json['hr_status'] ?? '').toString(),
      finalStatus: (json['final_status'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      attachment: json['attachment']?.toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
