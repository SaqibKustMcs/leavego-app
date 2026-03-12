class DashboardResponse {
  const DashboardResponse({required this.success, required this.data});

  final bool success;
  final DashboardData data;

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      success: json['success'] == true,
      data: DashboardData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}

class DashboardData {
  const DashboardData({required this.summary, required this.leaveBalances});

  final DashboardSummary summary;
  final List<DashboardLeaveBalanceItem> leaveBalances;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final balancesRaw = json['leave_balances'];
    return DashboardData(
      summary: DashboardSummary.fromJson(
        (json['summary'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      leaveBalances: balancesRaw is List
          ? balancesRaw
                .whereType<Map<String, dynamic>>()
                .map(DashboardLeaveBalanceItem.fromJson)
                .toList()
          : <DashboardLeaveBalanceItem>[],
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.totalAssigned,
    required this.totalUsed,
    required this.totalRemaining,
  });

  final int pending;
  final int approved;
  final int rejected;
  final int totalAssigned;
  final int totalUsed;
  final int totalRemaining;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      pending: _toInt(json['pending']),
      approved: _toInt(json['approved']),
      rejected: _toInt(json['rejected']),
      totalAssigned: _toInt(json['total_assigned']),
      totalUsed: _toInt(json['total_used']),
      totalRemaining: _toInt(json['total_remaining']),
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
