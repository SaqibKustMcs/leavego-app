class MeResponse {
  const MeResponse({required this.success, required this.data});

  final bool success;
  final MeData data;

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      success: json['success'] == true,
      data: MeData.fromJson((json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
    );
  }
}

class MeData {
  const MeData({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.departmentId,
    required this.department,
    required this.isActive,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? departmentId;
  final String? department;
  final bool isActive;

  factory MeData.fromJson(Map<String, dynamic> json) {
    return MeData(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      departmentId: json['department_id']?.toString(),
      department: json['department']?.toString(),
      isActive: json['is_active'] == true,
    );
  }
}
