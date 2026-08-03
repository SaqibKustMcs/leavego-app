/// Role permission helpers used across the app.
class AppRoles {
  AppRoles._();

  static String normalize(String? role) => (role ?? '').trim().toLowerCase();

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
}
