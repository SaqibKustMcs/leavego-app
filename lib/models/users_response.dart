class UsersResponse {
  const UsersResponse({required this.success, required this.data});

  final bool success;
  final List<AppUserItem> data;

  factory UsersResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final items = raw is List
        ? raw.whereType<Map<String, dynamic>>().map(AppUserItem.fromJson).toList()
        : <AppUserItem>[];
    return UsersResponse(success: json['success'] == true, data: items);
  }
}

class AppUserItem {
  const AppUserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.departmentId,
    required this.isActive,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? departmentId;
  final bool isActive;

  factory AppUserItem.fromJson(Map<String, dynamic> json) {
    return AppUserItem(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      departmentId: json['department_id']?.toString(),
      isActive: json['is_active'] == true || json['is_active']?.toString() == '1',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

