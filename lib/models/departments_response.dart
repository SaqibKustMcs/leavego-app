class DepartmentsResponse {
  const DepartmentsResponse({required this.success, required this.data});

  final bool success;
  final List<DepartmentItem> data;

  factory DepartmentsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final items = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(DepartmentItem.fromJson)
              .toList()
        : <DepartmentItem>[];
    return DepartmentsResponse(success: json['success'] == true, data: items);
  }
}

class DepartmentItem {
  const DepartmentItem({
    required this.id,
    required this.name,
    required this.hodUserId,
    required this.parentId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final int? hodUserId;
  final int? parentId;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  factory DepartmentItem.fromJson(Map<String, dynamic> json) {
    return DepartmentItem(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      hodUserId: _toNullableInt(json['hod_user_id']),
      parentId: _toNullableInt(json['parent_id']),
      isActive: json['is_active'] == true || json['is_active']?.toString() == '1',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

