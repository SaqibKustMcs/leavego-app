import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/users_response.dart';
import 'package:leavego_app/ui/screens/create_employee_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/ui/widgets/app_scroll_collapse_fab.dart';

enum _UserFilter { all, active, inactive }

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  static const Color _primary = Color(0xFF173559);
  static const Color _muted = Color(0xFF6A778B);

  late final AppController _appController;
  late final ScrollCollapseFabController _fabScrollController;
  _UserFilter _filter = _UserFilter.all;

  @override
  void initState() {
    super.initState();
    _fabScrollController = ScrollCollapseFabController();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadEmployees(refresh: true);
    _appController.loadDepartments();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fabScrollController.dispose();
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _appController.loadEmployees(refresh: true),
      _appController.loadDepartments(),
    ]);
  }

  String _toLabel(String raw) {
    if (raw.trim().isEmpty) return '-';
    return raw
        .split('_')
        .map(
          (part) =>
              part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _departmentName(String? departmentId) {
    final id = int.tryParse(departmentId ?? '');
    if (id == null) return departmentId?.isNotEmpty == true ? departmentId! : '-';
    for (final department in _appController.departments) {
      if (department.id == id) return department.name;
    }
    return departmentId ?? '-';
  }

  List<AppUserItem> _filteredUsers(List<AppUserItem> users) {
    switch (_filter) {
      case _UserFilter.all:
        return users;
      case _UserFilter.active:
        return users.where((u) => u.isActive).toList();
      case _UserFilter.inactive:
        return users.where((u) => !u.isActive).toList();
    }
  }

  int _allCount(List<AppUserItem> users) {
    final total = _appController.employeesTotal;
    return total > 0 ? total : users.length;
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreateEmployeeScreen()));
    if (created == true) {
      await _appController.loadEmployees(refresh: true);
    }
  }

  Future<void> _openEdit(AppUserItem user) async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => CreateEmployeeScreen(employee: user)));
    if (updated == true) {
      await _appController.loadEmployees(refresh: true);
    }
  }

  Future<void> _confirmDelete(AppUserItem user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete user?'),
          content: Text('This will remove “${user.name.isEmpty ? user.email : user.name}”.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final response = await _appController.deleteEmployee(employeeId: user.id);
    if (!mounted) return;
    if (response != null) {
      final message = (response['message'] ?? 'User deleted successfully').toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final error = _appController.deleteEmployeeError ?? 'Failed to delete user';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _showUserActions(AppUserItem user, BuildContext anchorContext) async {
    const menuWidth = 176.0;
    final button = anchorContext.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final anchorBottomRight = button.localToGlobal(
      button.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );

    var left = anchorBottomRight.dx - menuWidth + 4;
    left = left.clamp(8.0, overlay.size.width - menuWidth - 8);
    final top = anchorBottomRight.dy + 4;

    final action = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent,
      useRootNavigator: true,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final size = MediaQuery.sizeOf(dialogContext);
        return Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    behavior: HitTestBehavior.translucent,
                  ),
                ),
                Positioned(
                  left: left,
                  top: top,
                  width: menuWidth,
                  child: Material(
                    color: Colors.transparent,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 24,
                            spreadRadius: -2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _UserActionMenuItem(
                            label: 'Delete',
                            icon: Icons.delete_outline_rounded,
                            color: const Color(0xFFE53935),
                            onTap: () => Navigator.of(dialogContext).pop('delete'),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          _UserActionMenuItem(
                            label: 'Edit',
                            icon: Icons.edit_outlined,
                            color: _primary,
                            onTap: () => Navigator.of(dialogContext).pop('edit'),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    if (action == 'delete') {
      await _confirmDelete(user);
    } else if (action == 'edit') {
      await _openEdit(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allUsers = _appController.employees;
    final users = _filteredUsers(allUsers);
    final loading = _appController.employeesLoading;
    final error = _appController.employeesError;

    final allCount = _allCount(allUsers);
    final activeCount = allUsers.where((u) => u.isActive).length;
    final inactiveCount = allUsers.where((u) => !u.isActive).length;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(color: _primary),
        title: Text(
          'Manage User',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _fabScrollController,
        builder: (context, _) => AppScrollCollapseFab(
          label: 'Add User',
          collapsed: _fabScrollController.collapsed,
          onPressed: _openCreate,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: AppFabScrollListener(
          controller: _fabScrollController,
          child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _FilterTabs(
                selected: _filter,
                allCount: allCount,
                activeCount: activeCount,
                inactiveCount: inactiveCount,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 16),
              if (loading && allUsers.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: AppLoader())
              else if (error != null && allUsers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        error,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                      TextButton(
                        onPressed: () => _appController.loadEmployees(refresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (users.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    allUsers.isEmpty ? 'No users found.' : 'No users in this filter.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: _muted),
                  ),
                )
              else ...[
                if (loading)
                  const Padding(padding: EdgeInsets.only(bottom: 10), child: AppLoader(size: 22)),
                ...users.map(
                  (user) => _UserCard(
                    user: user,
                    roleLabel: _toLabel(user.role),
                    departmentLabel: _departmentName(user.departmentId),
                    onMore: (anchor) => _showUserActions(user, anchor),
                  ),
                ),
                const SizedBox(height: 8),
                if (_filter == _UserFilter.all && _appController.employeesHasMore)
                  OutlinedButton(
                    onPressed: _appController.employeesLoadingMore
                        ? null
                        : _appController.loadMoreEmployees,
                    child: _appController.employeesLoadingMore
                        ? const AppButtonLoader(color: AppTheme.navy)
                        : const Text('Load more'),
                  ),
                if (_appController.employeesError != null && allUsers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _appController.employeesError!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _UserActionMenuItem extends StatelessWidget {
  const _UserActionMenuItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.borderRadius,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.selected,
    required this.allCount,
    required this.activeCount,
    required this.inactiveCount,
    required this.onSelected,
  });

  final _UserFilter selected;
  final int allCount;
  final int activeCount;
  final int inactiveCount;
  final ValueChanged<_UserFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterTab(
              label: 'All ($allCount)',
              selected: selected == _UserFilter.all,
              onTap: () => onSelected(_UserFilter.all),
            ),
          ),
          Expanded(
            child: _FilterTab(
              label: 'Active ($activeCount)',
              selected: selected == _UserFilter.active,
              onTap: () => onSelected(_UserFilter.active),
            ),
          ),
          Expanded(
            child: _FilterTab(
              label: 'Inactive ($inactiveCount)',
              selected: selected == _UserFilter.inactive,
              onTap: () => onSelected(_UserFilter.inactive),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _tabSelected = Color(0xFF55957F);
  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _tabSelected : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.roleLabel,
    required this.departmentLabel,
    required this.onMore,
  });

  final AppUserItem user;
  final String roleLabel;
  final String departmentLabel;
  final void Function(BuildContext anchorContext) onMore;

  static const Color _primary = Color(0xFF173559);
  static const Color _muted = Color(0xFF6A778B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <String>[
      if (roleLabel != '-') roleLabel,
      if (departmentLabel != '-' && departmentLabel != roleLabel) departmentLabel,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF4F2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty ? '-' : user.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email.isEmpty ? '-' : user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(active: user.isActive),
              GestureDetector(
                onTap: () => onMore(context),

                child: Icon(Icons.more_vert, color: _primary),
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map((label) => _RoleChip(label: label)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDFF5E2) : const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: active ? const Color(0xFF33594C) : const Color(0xFF9B2C2C),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  static const Color _roleChipBg = Color(0xFFE5F1FE);
  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: _roleChipBg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: const TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
