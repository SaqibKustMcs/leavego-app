class DashboardResponse {
  const DashboardResponse({
    required this.success,
    required this.role,
    required this.data,
  });

  final bool success;
  final String? role;
  final DashboardData data;

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    // Supports both shapes:
    // 1) { success, data: {...} }
    // 2) { success, role, data: {...nested...} }
    return DashboardResponse(
      success: json['success'] == true,
      role: json['role']?.toString(),
      data: DashboardData.fromJson((json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.type,
    required this.summary,
    required this.leaveBalances,
    required this.tasks,
    required this.hrPendingLeaveRequests,
  });

  final String? type;
  final DashboardSummary? summary;
  final List<DashboardLeaveBalanceItem> leaveBalances;
  final DashboardTasksSummary? tasks;
  final DashboardHrPendingLeaveRequests? hrPendingLeaveRequests;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // New API shape nests inside data: { type, summary, leave_balances, tasks, hr_pending_leave_requests }
    // Old/legacy shape may include pending_hod / pending_hr at same level.
    final balancesRaw = json['leave_balances'];
    final summaryRaw = json['summary'];
    final tasksRaw = json['tasks'];
    final hrPendingRaw = json['hr_pending_leave_requests'];
    return DashboardData(
      type: json['type']?.toString(),
      summary: summaryRaw is Map<String, dynamic> ? DashboardSummary.fromJson(summaryRaw) : null,
      leaveBalances: balancesRaw is List
          ? balancesRaw
                .whereType<Map<String, dynamic>>()
                .map(DashboardLeaveBalanceItem.fromJson)
                .toList()
          : <DashboardLeaveBalanceItem>[],
      tasks: tasksRaw is Map<String, dynamic> ? DashboardTasksSummary.fromJson(tasksRaw) : null,
      hrPendingLeaveRequests: hrPendingRaw is Map<String, dynamic>
          ? DashboardHrPendingLeaveRequests.fromJson(hrPendingRaw)
          : null,
    );
  }

  int get pendingHod => _toInt(hrPendingLeaveRequests?.pendingHod);
  int get pendingHr => _toInt(hrPendingLeaveRequests?.pendingHr);
}

class DashboardSummary {
  const DashboardSummary({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.totalRequests,
    required this.totalAssigned,
    required this.totalUsed,
    required this.totalRemaining,
  });

  final int pending;
  final int approved;
  final int rejected;
  final int totalRequests;
  final int totalAssigned;
  final int totalUsed;
  final int totalRemaining;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      pending: _toInt(json['pending']),
      approved: _toInt(json['approved']),
      rejected: _toInt(json['rejected']),
      totalRequests: _toInt(json['total_requests']),
      totalAssigned: _toInt(json['total_assigned']),
      totalUsed: _toInt(json['total_used']),
      totalRemaining: _toInt(json['total_remaining']),
    );
  }
}

class DashboardTasksSummary {
  const DashboardTasksSummary({
    required this.assigned,
    required this.accepted,
    required this.inProgress,
    required this.completed,
    required this.blocked,
    required this.rejected,
    required this.cancelled,
    required this.overdue,
    required this.total,
  });

  final int assigned;
  final int accepted;
  final int inProgress;
  final int completed;
  final int blocked;
  final int rejected;
  final int cancelled;
  final int overdue;
  final int total;

  factory DashboardTasksSummary.fromJson(Map<String, dynamic> json) {
    return DashboardTasksSummary(
      assigned: _toInt(json['assigned']),
      accepted: _toInt(json['accepted']),
      inProgress: _toInt(json['in_progress']),
      completed: _toInt(json['completed']),
      blocked: _toInt(json['blocked']),
      rejected: _toInt(json['rejected']),
      cancelled: _toInt(json['cancelled']),
      overdue: _toInt(json['overdue']),
      total: _toInt(json['total']),
    );
  }
}

class DashboardHrPendingLeaveRequests {
  const DashboardHrPendingLeaveRequests({
    required this.pendingHod,
    required this.pendingHr,
    required this.approved,
    required this.rejected,
    required this.totalRequests,
  });

  final int pendingHod;
  final int pendingHr;
  final int approved;
  final int rejected;
  final int totalRequests;

  factory DashboardHrPendingLeaveRequests.fromJson(Map<String, dynamic> json) {
    return DashboardHrPendingLeaveRequests(
      pendingHod: _toInt(json['pending_hod']),
      pendingHr: _toInt(json['pending_hr']),
      approved: _toInt(json['approved']),
      rejected: _toInt(json['rejected']),
      totalRequests: _toInt(json['total_requests']),
    );
  }
}

class DashboardLeaveBalanceItem {
  const DashboardLeaveBalanceItem({
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.assigned,
    required this.used,
    required this.remaining,
  });

  final String leaveTypeId;
  final String leaveTypeName;
  final int assigned;
  final int used;
  final int remaining;

  factory DashboardLeaveBalanceItem.fromJson(Map<String, dynamic> json) {
    return DashboardLeaveBalanceItem(
      leaveTypeId: json['leave_type_id']?.toString() ?? '',
      leaveTypeName: json['leave_type_name']?.toString() ?? '',
      assigned: _toInt(json['assigned']),
      used: _toInt(json['used']),
      remaining: _toInt(json['remaining']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
