class LeaveDetailResponse {
  const LeaveDetailResponse({required this.success, required this.data});

  final bool success;
  final LeaveDetailData data;

  factory LeaveDetailResponse.fromJson(Map<String, dynamic> json) {
    return LeaveDetailResponse(
      success: json['success'] == true,
      data: LeaveDetailData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}

class LeaveDetailData {
  const LeaveDetailData({
    required this.leave,
    required this.attachmentUrl,
    required this.approvals,
    required this.employeeName,
    required this.department,
  });
  final String department;
  final String employeeName;
  final LeaveDetailItem leave;
  final String? attachmentUrl;
  final List<LeaveApprovalItem> approvals;

  factory LeaveDetailData.fromJson(Map<String, dynamic> json) {
    final approvalsRaw = json['approvals'];
    return LeaveDetailData(
      department: json['department']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      leave: LeaveDetailItem.fromJson(
        (json['leave'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      attachmentUrl: json['attachment_url']?.toString(),
      approvals: approvalsRaw is List
          ? approvalsRaw.whereType<Map<String, dynamic>>().map(LeaveApprovalItem.fromJson).toList()
          : <LeaveApprovalItem>[],
    );
  }
}

class LeaveDetailItem {
  const LeaveDetailItem({
    required this.id,
    required this.employeeId,
    required this.userId,
    required this.departmentId,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.attachment,
    required this.supportingDocumentPath,
    required this.status,
    required this.hodStatus,
    required this.hrStatus,
    required this.ceoStatus,
    required this.finalStatus,
    required this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String employeeId;
  final String userId;
  final String departmentId;
  final String leaveTypeId;
  final String startDate;
  final String endDate;
  final String days;
  final String reason;
  final String? attachment;
  final String? supportingDocumentPath;
  final String status;
  final String hodStatus;
  final String hrStatus;
  final String ceoStatus;
  final String finalStatus;
  final String? submittedAt;
  final String? createdAt;
  final String? updatedAt;

  factory LeaveDetailItem.fromJson(Map<String, dynamic> json) {
    return LeaveDetailItem(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      departmentId: json['department_id']?.toString() ?? '',
      leaveTypeId: json['leave_type_id']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      days: json['days']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      attachment: json['attachment']?.toString(),
      supportingDocumentPath: json['supporting_document_path']?.toString(),
      status: json['status']?.toString() ?? '',
      hodStatus: json['hod_status']?.toString() ?? '',
      hrStatus: json['hr_status']?.toString() ?? '',
      ceoStatus: json['ceo_status']?.toString() ?? '',
      finalStatus: json['final_status']?.toString() ?? '',
      submittedAt: json['submitted_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class LeaveApprovalItem {
  const LeaveApprovalItem({
    required this.id,
    required this.leaveRequestId,
    required this.actionByUserId,
    required this.stage,
    required this.action,
    required this.comment,
    required this.actionAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String leaveRequestId;
  final String actionByUserId;
  final String stage;
  final String action;
  final String? comment;
  final String? actionAt;
  final String? createdAt;
  final String? updatedAt;

  factory LeaveApprovalItem.fromJson(Map<String, dynamic> json) {
    return LeaveApprovalItem(
      id: json['id']?.toString() ?? '',
      leaveRequestId: json['leave_request_id']?.toString() ?? '',
      actionByUserId: json['action_by_user_id']?.toString() ?? '',
      stage: json['stage']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      comment: json['comment']?.toString(),
      actionAt: json['action_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}
