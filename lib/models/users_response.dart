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

class EmployeesResponse {
  const EmployeesResponse({required this.success, required this.data});

  final bool success;
  final EmployeesPageData data;

  factory EmployeesResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    return EmployeesResponse(
      success: json['success'] == true,
      data: raw is Map<String, dynamic>
          ? EmployeesPageData.fromJson(raw)
          : EmployeesPageData.empty(),
    );
  }
}

class EmployeesPageData {
  const EmployeesPageData({
    required this.currentPage,
    required this.items,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  final int currentPage;
  final List<AppUserItem> items;
  final int lastPage;
  final int total;
  final int perPage;

  factory EmployeesPageData.empty() {
    return const EmployeesPageData(
      currentPage: 1,
      items: <AppUserItem>[],
      lastPage: 1,
      total: 0,
      perPage: 20,
    );
  }

  factory EmployeesPageData.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = rawList is List
        ? rawList.whereType<Map<String, dynamic>>().map(AppUserItem.fromJson).toList()
        : <AppUserItem>[];

    return EmployeesPageData(
      currentPage: _toInt(json['current_page'], fallback: 1),
      lastPage: _toInt(json['last_page'], fallback: 1),
      total: _toInt(json['total']),
      perPage: _toInt(json['per_page'], fallback: 20),
      items: items,
    );
  }

  bool get hasMore => currentPage < lastPage;

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

class AppUserItem {
  const AppUserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.departmentId,
    required this.phone,
    required this.isActive,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? departmentId;
  final String? phone;
  final bool isActive;

  factory AppUserItem.fromJson(Map<String, dynamic> json) {
    return AppUserItem(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      departmentId: json['department_id']?.toString(),
      phone: json['phone']?.toString(),
      isActive: json['is_active'] == true || json['is_active']?.toString() == '1',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
