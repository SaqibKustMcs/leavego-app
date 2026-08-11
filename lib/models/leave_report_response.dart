class LeaveReportResponse {
  const LeaveReportResponse({required this.success, required this.data});

  final bool success;
  final LeaveReportPageData data;

  factory LeaveReportResponse.fromJson(Map<String, dynamic> json) {
    return LeaveReportResponse(
      success: json['success'] == true,
      data: LeaveReportPageData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}

class LeaveReportPageData {
  const LeaveReportPageData({
    required this.currentPage,
    required this.items,
    required this.total,
    required this.lastPage,
    required this.perPage,
  });

  final int currentPage;
  final List<LeaveReportItem> items;
  final int total;
  final int lastPage;
  final int perPage;

  factory LeaveReportPageData.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = rawList is List
        ? rawList.whereType<Map<String, dynamic>>().map(LeaveReportItem.fromJson).toList()
        : <LeaveReportItem>[];

    return LeaveReportPageData(
      currentPage: _toInt(json['current_page']),
      items: items,
      total: _toInt(json['total']),
      lastPage: _toInt(json['last_page']),
      perPage: _toInt(json['per_page']),
    );
  }

  bool get hasMore => currentPage < lastPage;

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class LeaveReportItem {
  const LeaveReportItem({
    required this.id,
    required this.employeeId,
    required this.departmentId,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.status,
    required this.hodStatus,
    required this.hrStatus,
    required this.ceoStatus,
    required this.finalStatus,
    required this.submittedAt,
    required this.employeeName,
    required this.employeeEmail,
    required this.employeeRole,
    required this.departmentName,
    required this.leaveTypeName,
    required this.leaveTypeCode,
  });

  final int id;
  final int employeeId;
  final int departmentId;
  final int leaveTypeId;
  final String startDate;
  final String endDate;
  final int days;
  final String reason;
  final String status;
  final String hodStatus;
  final String hrStatus;
  final String? ceoStatus;
  final String finalStatus;
  final String? submittedAt;
  final String employeeName;
  final String employeeEmail;
  final String employeeRole;
  final String departmentName;
  final String leaveTypeName;
  final String leaveTypeCode;

  factory LeaveReportItem.fromJson(Map<String, dynamic> json) {
    return LeaveReportItem(
      id: _toInt(json['id']),
      employeeId: _toInt(json['employee_id']),
      departmentId: _toInt(json['department_id']),
      leaveTypeId: _toInt(json['leave_type_id']),
      startDate: (json['start_date'] ?? '').toString(),
      endDate: (json['end_date'] ?? '').toString(),
      days: _toInt(json['days']),
      reason: (json['reason'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      hodStatus: (json['hod_status'] ?? '').toString(),
      hrStatus: (json['hr_status'] ?? '').toString(),
      ceoStatus: json['ceo_status']?.toString(),
      finalStatus: (json['final_status'] ?? '').toString(),
      submittedAt: json['submitted_at']?.toString(),
      employeeName: (json['employee_name'] ?? '').toString(),
      employeeEmail: (json['employee_email'] ?? '').toString(),
      employeeRole: (json['employee_role'] ?? '').toString(),
      departmentName: (json['department_name'] ?? '').toString(),
      leaveTypeName: (json['leave_type_name'] ?? '').toString(),
      leaveTypeCode: (json['leave_type_code'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
