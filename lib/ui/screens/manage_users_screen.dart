import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/users_response.dart';
import 'package:leavego_app/ui/screens/create_employee_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  late final AppController _appController;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = _appController.employees;
    final loading = _appController.employeesLoading;
    final error = _appController.employeesError;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      appBar: AppBar(
        title: Text(
          'Manage Users',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: const AppBackButton(),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Create user',
            onPressed: () async {
              final created = await Navigator.of(
                context,
              ).push<bool>(MaterialPageRoute(builder: (_) => const CreateEmployeeScreen()));
              if (created == true) {
                await _appController.loadEmployees(refresh: true);
              }
            },
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Employees',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Text(
                    'Page ${_appController.employeesCurrentPage}/${_appController.employeesLastPage}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6A778B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _appController.employeesTotal > 0
                    ? '${_appController.employeesTotal} users · Tap edit to update details'
                    : 'Tap edit to update user details',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
              ),
              const SizedBox(height: 14),
              if (loading && users.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: AppLoader())
              else if (error != null && users.isEmpty)
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
                  child: const Text('No users found.'),
                )
              else ...[
                if (loading)
                  const Padding(padding: EdgeInsets.only(bottom: 10), child: AppLoader(size: 22)),
                ...users.map(
                  (user) => _UserCard(
                    user: user,
                    roleLabel: _toLabel(user.role),
                    departmentLabel: _departmentName(user.departmentId),
                    deleting: _appController.deleteEmployeeLoading,
                    onEdit: () => _openEdit(user),
                    onDelete: () => _confirmDelete(user),
                  ),
                ),
                const SizedBox(height: 8),
                if (_appController.employeesHasMore)
                  OutlinedButton(
                    onPressed: _appController.employeesLoadingMore
                        ? null
                        : _appController.loadMoreEmployees,
                    child: _appController.employeesLoadingMore
                        ? const AppButtonLoader(color: AppTheme.navy)
                        : const Text('Load more'),
                  ),
                if (_appController.employeesError != null && users.isNotEmpty)
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
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.roleLabel,
    required this.departmentLabel,
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
  });

  final AppUserItem user;
  final String roleLabel;
  final String departmentLabel;
  final bool deleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isEmpty ? '-' : user.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email.isEmpty ? '-' : user.email,
                  style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(label: roleLabel),
                    _Pill(label: departmentLabel),
                    _Pill(
                      label: user.isActive ? 'Active' : 'Inactive',
                      background: user.isActive ? const Color(0xFFDFF5E2) : const Color(0xFFFDECEC),
                      foreground: user.isActive ? const Color(0xFF1B5E20) : const Color(0xFF9B2C2C),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit user',
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
          ),
          IconButton(
            onPressed: deleting ? null : onDelete,
            tooltip: 'Delete user',
            icon: const Icon(Icons.delete_outlined, color: Color(0xFFC62828)),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    this.background = const Color(0xFFE8EEFC),
    this.foreground = AppTheme.navy,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}
