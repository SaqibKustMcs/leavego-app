import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/users_response.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class SelectProjectMembersScreen extends StatefulWidget {
  const SelectProjectMembersScreen({
    super.key,
    required this.initiallySelected,
    this.allowedUserIds,
    this.maxSelections,
    this.appBarTitle = 'Select Member',
  });

  final Set<int> initiallySelected;
  final Set<int>? allowedUserIds;
  final int? maxSelections;
  final String appBarTitle;

  @override
  State<SelectProjectMembersScreen> createState() => _SelectProjectMembersScreenState();
}

class _SelectProjectMembersScreenState extends State<SelectProjectMembersScreen> {
  static const Color _primary = Color(0xFF173559);
  static const Color _muted = Color(0xFF747D7A);
  static const Color _fieldBorder = Color(0xFFEEF4F2);

  static const List<Color> _avatarColors = <Color>[
    Color(0xFFE57373),
    Color(0xFF4DB6AC),
    Color(0xFFFFB74D),
    Color(0xFFBA68C8),
    Color(0xFF9E9D24),
    Color(0xFF7986CB),
    Color(0xFF8D6E63),
  ];

  late final AppController _appController;
  late final Set<int> _selected;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _selected = Set<int>.from(widget.initiallySelected);
    _appController.addListener(_onUpdate);
    if (_appController.users.isEmpty && !_appController.usersLoading) {
      _appController.loadUsers();
    }
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _popWithSelection() {
    Navigator.of(context).pop(Set<int>.from(_selected));
  }

  List<AppUserItem> _activeUsersUnique() {
    final seen = <int>{};
    final users = <AppUserItem>[];
    final allowed = widget.allowedUserIds;
    for (final user in _appController.users) {
      if (!user.isActive) continue;
      if (allowed != null && !allowed.contains(user.id)) continue;
      if (seen.add(user.id)) users.add(user);
    }
    users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return users;
  }

  List<AppUserItem> _filteredUsers(List<AppUserItem> users) {
    if (_query.isEmpty) return users;
    return users.where((user) {
      final name = user.name.toLowerCase();
      final email = user.email.toLowerCase();
      return name.contains(_query) || email.contains(_query);
    }).toList();
  }

  Color _avatarColor(int id) => _avatarColors[id % _avatarColors.length];

  String _initial(AppUserItem user) {
    final name = user.name.trim();
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  AppUserItem? _userById(int id, List<AppUserItem> users) {
    for (final user in users) {
      if (user.id == id) return user;
    }
    return null;
  }

  void _toggleUser(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        return;
      }
      if (widget.maxSelections == 1) {
        _selected
          ..clear()
          ..add(id);
      } else {
        _selected.add(id);
      }
    });
  }

  bool get _canSelectAll => widget.maxSelections != 1;

  bool _allEmployeesSelected(List<AppUserItem> allUsers) {
    if (allUsers.isEmpty) return false;
    return allUsers.every((user) => _selected.contains(user.id));
  }

  void _toggleSelectAll(List<AppUserItem> allUsers) {
    if (allUsers.isEmpty) return;
    setState(() {
      if (_allEmployeesSelected(allUsers)) {
        for (final user in allUsers) {
          _selected.remove(user.id);
        }
      } else {
        for (final user in allUsers) {
          _selected.add(user.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allUsers = _activeUsersUnique();
    final filtered = _filteredUsers(allUsers);
    final selectedUsers =
        _selected.map((id) => _userById(id, allUsers)).whereType<AppUserItem>().toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _popWithSelection();
      },
      child: Scaffold(
        backgroundColor: AppTheme.appBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.appBackground,
          elevation: 0,
          scrolledUnderElevation: 0,

          leading: AppBackButton(color: _primary, onPressed: _popWithSelection),
          title: Text(
            widget.appBarTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Color(0xff000000),
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
        ),
        body: _appController.usersLoading && allUsers.isEmpty
            ? const Center(child: AppLoader())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: SizedBox(
                      height: 54,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: const TextStyle(color: Color(0xFF6E6E6E)),
                          prefixIcon: const Icon(Icons.search_rounded, color: _primary),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _fieldBorder, width: 0.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _fieldBorder, width: 0.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _primary, width: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (selectedUsers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: selectedUsers
                            .map(
                              (user) => _MemberChip(
                                user: user,
                                avatarColor: _avatarColor(user.id),
                                initial: _initial(user),
                                onRemove: () => setState(() => _selected.remove(user.id)),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  if (_appController.usersError != null && allUsers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _appController.usersError!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'People',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _primary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select users to add',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_canSelectAll)
                          TextButton(
                            onPressed: allUsers.isEmpty ? null : () => _toggleSelectAll(allUsers),
                            style: TextButton.styleFrom(
                              foregroundColor: _primary,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              _allEmployeesSelected(allUsers) ? 'Deselect all' : 'Select all',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              allUsers.isEmpty ? 'No users available' : 'No matches found',
                              style: theme.textTheme.bodyMedium?.copyWith(color: _muted),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: filtered.length,
                            // separatorBuilder: (context, index) =>
                            //     Divider(height: 1, color: _fieldBorder.withValues(alpha: 0.9)),
                            itemBuilder: (context, index) {
                              final user = filtered[index];
                              final isSelected = _selected.contains(user.id);
                              return InkWell(
                                onTap: () => _toggleUser(user.id),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 32,
                                        width: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,

                                          color: _avatarColor(user.id),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _initial(user),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          user.name.isEmpty ? user.email : user.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 18,
                                            color: _primary,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(Icons.check_rounded, color: _primary, size: 22),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.user,
    required this.avatarColor,
    required this.initial,
    required this.onRemove,
  });

  final AppUserItem user;
  final Color avatarColor;
  final String initial;
  final VoidCallback onRemove;

  static const Color _fieldBorder = Color(0xFFEEF4F2);

  @override
  Widget build(BuildContext context) {
    final label = user.name.isEmpty ? user.email : user.name;

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 4, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _fieldBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: avatarColor,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF9AA5B5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
