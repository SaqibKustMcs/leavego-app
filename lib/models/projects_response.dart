class ProjectsResponse {
  const ProjectsResponse({required this.success, required this.data});

  final bool success;
  final ProjectsPageData data;

  factory ProjectsResponse.fromJson(Map<String, dynamic> json) {
    return ProjectsResponse(
      success: json['success'] == true,
      data: ProjectsPageData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}

class ProjectsPageData {
  const ProjectsPageData({
    required this.currentPage,
    required this.items,
    required this.lastPage,
    required this.total,
  });

  final int currentPage;
  final List<ProjectItem> items;
  final int lastPage;
  final int total;

  factory ProjectsPageData.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = rawList is List
        ? rawList.whereType<Map<String, dynamic>>().map(ProjectItem.fromJson).toList()
        : <ProjectItem>[];

    return ProjectsPageData(
      currentPage: _toInt(json['current_page']),
      lastPage: _toInt(json['last_page']),
      total: _toInt(json['total']),
      items: items,
    );
  }

  bool get hasMore => currentPage < lastPage;
}

class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.startDate,
    required this.dueDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.tasksCount,
    required this.creator,
    required this.members,
  });

  final int id;
  final String name;
  final String description;
  final String status;
  final String? startDate;
  final String? dueDate;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final int tasksCount;
  final ProjectPerson? creator;
  final List<ProjectMember> members;

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    final membersRaw = json['members'];
    return ProjectItem(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      startDate: json['start_date']?.toString(),
      dueDate: json['due_date']?.toString(),
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      tasksCount: _toInt(json['tasks_count']),
      creator: json['creator'] is Map<String, dynamic>
          ? ProjectPerson.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      members: membersRaw is List
          ? membersRaw
                .whereType<Map<String, dynamic>>()
                .map(ProjectMember.fromJson)
                .toList()
          : <ProjectMember>[],
    );
  }
}

class ProjectPerson {
  const ProjectPerson({
    required this.id,
    required this.name,
    required this.email,
  });

  final int id;
  final String name;
  final String email;

  factory ProjectPerson.fromJson(Map<String, dynamic> json) {
    return ProjectPerson(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}

class ProjectMember {
  const ProjectMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final int id;
  final String name;
  final String email;
  final String role;

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
    );
  }
}

class ProjectMembersResponse {
  const ProjectMembersResponse({required this.success, required this.data});

  final bool success;
  final List<ProjectMember> data;

  factory ProjectMembersResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final items = raw is List
        ? raw.whereType<Map<String, dynamic>>().map(ProjectMember.fromJson).toList()
        : <ProjectMember>[];
    return ProjectMembersResponse(success: json['success'] == true, data: items);
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
