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
  const DashboardData({
    required this.pendingHod,
    required this.pendingHr,
    required this.approved,
    required this.rejected,
  });

  final int pendingHod;
  final int pendingHr;
  final int approved;
  final int rejected;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      pendingHod: _toInt(json['pending_hod']),
      pendingHr: _toInt(json['pending_hr']),
      approved: _toInt(json['approved']),
      rejected: _toInt(json['rejected']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
