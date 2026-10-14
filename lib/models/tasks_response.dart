class TasksResponse {
  const TasksResponse({required this.success, required this.data});

  final bool success;
  final TasksPageData data;

  factory TasksResponse.fromJson(Map<String, dynamic> json) {
    return TasksResponse(
      success: _jsonBool(json['success']),
      data: TasksPageData.fromJson((json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
    );
  }
}

class TasksPageData {
  const TasksPageData({
    required this.currentPage,
    required this.items,
    required this.from,
    required this.lastPage,
    required this.perPage,
    required this.to,
    required this.total,
    required this.firstPageUrl,
    required this.lastPageUrl,
    required this.nextPageUrl,
    required this.prevPageUrl,
    required this.path,
    required this.links,
  });

  final int currentPage;
  final List<TaskItem> items;
  final int? from;
  final int lastPage;
  final int perPage;
  final int? to;
  final int total;
  final String firstPageUrl;
  final String lastPageUrl;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final String path;
  final List<TasksPageLink> links;

  factory TasksPageData.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = rawList is List
        ? rawList.whereType<Map<String, dynamic>>().map(TaskItem.fromJson).toList()
        : <TaskItem>[];
    final linksRaw = json['links'];

    return TasksPageData(
      currentPage: _toInt(json['current_page']),
      items: items,
      from: _toNullableInt(json['from']),
      lastPage: _toInt(json['last_page']),
      perPage: _toInt(json['per_page']),
      to: _toNullableInt(json['to']),
      total: _toInt(json['total']),
      firstPageUrl: (json['first_page_url'] ?? '').toString(),
      lastPageUrl: (json['last_page_url'] ?? '').toString(),
      nextPageUrl: json['next_page_url']?.toString(),
      prevPageUrl: json['prev_page_url']?.toString(),
      path: (json['path'] ?? '').toString(),
      links: linksRaw is List
          ? linksRaw.whereType<Map<String, dynamic>>().map(TasksPageLink.fromJson).toList()
          : <TasksPageLink>[],
    );
  }

  bool get hasMore => nextPageUrl != null && nextPageUrl!.isNotEmpty;

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

class TasksPageLink {
  const TasksPageLink({required this.url, required this.label, required this.active});

  final String? url;
  final String label;
  final bool active;

  factory TasksPageLink.fromJson(Map<String, dynamic> json) {
    return TasksPageLink(
      url: json['url']?.toString(),
      label: (json['label'] ?? '').toString(),
      active: _jsonBool(json['active']),
    );
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.taskType,
    required this.priority,
    required this.status,
    required this.departmentId,
    required this.projectId,
    required this.assignedBy,
    required this.assignedTo,
    required this.assignedUserIds,
    required this.assignments,
    required this.myAssignment,
    required this.parentTaskId,
    required this.startDate,
    required this.startTime,
    required this.dueDate,
    required this.dueTime,
    required this.estimatedHours,
    required this.completionDate,
    required this.isSupportingTask,
    required this.createdAt,
    required this.updatedAt,
    required this.creator,
    required this.assignee,
    required this.department,
    required this.project,
  });

  final int id;
  final String title;
  final String description;
  final String taskType;
  final String priority;
  final String status;
  final String? departmentId;
  final String? projectId;
  final String? assignedBy;
  final String? assignedTo;
  final List<int> assignedUserIds;
  final List<TaskAssignmentItem> assignments;
  final TaskAssignmentItem? myAssignment;
  final int? parentTaskId;
  final String? startDate;
  final String? startTime;
  final String? dueDate;
  final String? dueTime;
  final int estimatedHours;
  final String? completionDate;
  final bool isSupportingTask;
  final String? createdAt;
  final String? updatedAt;
  final TaskPersonSummary? creator;
  final TaskPersonSummary? assignee;
  final TaskDepartmentSummary? department;
  final TaskProjectSummary? project;

  List<int> get resolvedAssigneeIds {
    if (assignedUserIds.isNotEmpty) return assignedUserIds;
    final fromAssignments = assignments.map((a) => a.userId).where((id) => id > 0).toList();
    if (fromAssignments.isNotEmpty) return fromAssignments;
    final legacy = int.tryParse(assignedTo ?? '');
    return legacy != null && legacy > 0 ? <int>[legacy] : const <int>[];
  }

  bool isAssignedToUserId(int userId) {
    if (userId <= 0) return false;
    if (myAssignment != null && myAssignment!.userId == userId) return true;
    return resolvedAssigneeIds.contains(userId);
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final assignedUserIds = _parseAssignedUserIds(json);
    final assignmentsRaw = json['assignments'];
    final assignments = assignmentsRaw is List
        ? assignmentsRaw.whereType<Map<String, dynamic>>().map(TaskAssignmentItem.fromJson).toList()
        : <TaskAssignmentItem>[];
    final myAssignmentRaw = json['my_assignment'];

    return TaskItem(
      id: _toInt(json['id']),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      taskType: (json['task_type'] ?? '').toString(),
      priority: (json['priority'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      departmentId: json['department_id']?.toString(),
      projectId: json['project_id']?.toString(),
      assignedBy: json['assigned_by']?.toString(),
      assignedTo: _parseLegacyAssignedTo(json),
      assignedUserIds: assignedUserIds,
      assignments: assignments,
      myAssignment: myAssignmentRaw is Map<String, dynamic>
          ? TaskAssignmentItem.fromJson(myAssignmentRaw)
          : null,
      parentTaskId: _toNullableInt(json['parent_task_id']),
      startDate: json['start_date']?.toString(),
      startTime: json['start_time']?.toString(),
      dueDate: json['due_date']?.toString(),
      dueTime: json['due_time']?.toString(),
      estimatedHours: _toInt(json['estimated_hours']),
      completionDate: json['completion_date']?.toString(),
      isSupportingTask: _jsonBool(json['is_supporting_task']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      creator: json['creator'] is Map<String, dynamic>
          ? TaskPersonSummary.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      assignee: json['assignee'] is Map<String, dynamic>
          ? TaskPersonSummary.fromJson(json['assignee'] as Map<String, dynamic>)
          : null,
      department: json['department'] is Map<String, dynamic>
          ? TaskDepartmentSummary.fromJson(json['department'] as Map<String, dynamic>)
          : null,
      project: json['project'] is Map<String, dynamic>
          ? TaskProjectSummary.fromJson(json['project'] as Map<String, dynamic>)
          : null,
    );
  }

  static String? _parseLegacyAssignedTo(Map<String, dynamic> json) {
    final assignedTo = json['assigned_to'];
    if (assignedTo == null) return null;
    if (assignedTo is List) {
      if (assignedTo.isEmpty) return null;
      return _toInt(assignedTo.first).toString();
    }
    return assignedTo.toString();
  }

  static List<int> _parseAssignedUserIds(Map<String, dynamic> json) {
    final canonical = json['assigned_user_ids'];
    if (canonical is List) {
      return canonical.map(_toInt).where((id) => id > 0).toList();
    }
    final assignedTo = json['assigned_to'];
    if (assignedTo is List) {
      return assignedTo.map(_toInt).where((id) => id > 0).toList();
    }
    final single = _toNullableInt(assignedTo);
    if (single != null && single > 0) return <int>[single];
    return const <int>[];
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

class TaskAssignmentItem {
  const TaskAssignmentItem({
    required this.id,
    required this.userId,
    required this.status,
    required this.completionDate,
    required this.user,
  });

  final int id;
  final int userId;
  final String status;
  final String? completionDate;
  final TaskPersonSummary? user;

  factory TaskAssignmentItem.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    return TaskAssignmentItem(
      id: _assignmentJsonInt(json['id']),
      userId: _assignmentJsonInt(
        json['user_id'] ?? (userRaw is Map ? userRaw['id'] : null),
      ),
      status: (json['status'] ?? '').toString(),
      completionDate: json['completion_date']?.toString(),
      user: userRaw is Map<String, dynamic> ? TaskPersonSummary.fromJson(userRaw) : null,
    );
  }
}

class TaskPersonSummary {
  const TaskPersonSummary({required this.id, required this.name});

  final int id;
  final String name;

  factory TaskPersonSummary.fromJson(Map<String, dynamic> json) {
    return TaskPersonSummary(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

class TaskDepartmentSummary {
  const TaskDepartmentSummary({required this.id, required this.name});

  final int id;
  final String name;

  factory TaskDepartmentSummary.fromJson(Map<String, dynamic> json) {
    return TaskDepartmentSummary(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

class TaskProjectSummary {
  const TaskProjectSummary({required this.id, required this.name});

  final int id;
  final String name;

  factory TaskProjectSummary.fromJson(Map<String, dynamic> json) {
    return TaskProjectSummary(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

int _assignmentJsonInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _jsonBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  final raw = value?.toString().trim().toLowerCase() ?? '';
  return raw == '1' || raw == 'true' || raw == 'yes';
}
