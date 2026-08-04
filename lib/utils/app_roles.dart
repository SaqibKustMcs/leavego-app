/// Role permission helpers used across the app.
class AppRoles {
  AppRoles._();

  static String normalize(String? role) => (role ?? '').trim().toLowerCase();

  /// Human-readable role label for UI (e.g. operations_manager → Operations Manager).
  static String displayName(String? role) {
    final raw = (role ?? '').trim();
    if (raw.isEmpty || raw == '-') return '-';

    final normalized = raw.toLowerCase();
    const labels = <String, String>{
      'operations_manager': 'Operations Manager',
      'ceo': 'CEO',
      'hr': 'HR',
      'hod': 'HOD',
      'admin': 'Admin',
      'employee': 'Employee',
      'developer': 'Developer',
    };
    if (labels.containsKey(normalized)) return labels[normalized]!;

    return normalized
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  /// Create news: HR, CEO, admin, operations_manager.
  static bool canCreateNews(String? role) {
    final r = normalize(role);
    return r == 'hr' || r == 'ceo' || r == 'admin' || r == 'operations_manager';
  }

  /// Edit news: HR, CEO, admin only (not operations_manager).
  static bool canEditNews(String? role) {
    final r = normalize(role);
    return r == 'hr' || r == 'ceo' || r == 'admin';
  }

  /// Delete news: HR, CEO, admin only (not operations_manager).
  static bool canDeleteNews(String? role) {
    final r = normalize(role);
    return r == 'hr' || r == 'ceo' || r == 'admin';
  }

  static bool canManageProjects(String? role) {
    final r = normalize(role);
    return r == 'ceo' || r == 'hr' || r == 'admin' || r == 'operations_manager';
  }

  /// Create employee/user: operations_manager only.
  static bool canCreateEmployee(String? role) {
    return normalize(role) == 'operations_manager';
  }

  /// Leave approvals / pending queue like HR (and CEO for shared tabs).
  static bool isCeoOrHrLike(String? role) {
    final r = normalize(role);
    return r == 'ceo' || r == 'hr' || r == 'operations_manager';
  }

  /// Can take the HR approval action on a leave request.
  static bool isHrLikeApprover(String? role) {
    final r = normalize(role);
    return r == 'hr' || r == 'operations_manager';
  }

  /// OPM / CEO apply leave via JSON POST /leaves (no user_id / attachment).
  static bool usesSimpleLeaveApply(String? role) {
    final r = normalize(role);
    return r == 'operations_manager' || r == 'ceo';
  }
}
