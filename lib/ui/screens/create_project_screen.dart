import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/projects_response.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key, this.project});

  final ProjectItem? project;

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  late final AppController _appController;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _dueDateController = TextEditingController();

  String _selectedStatus = 'active';
  final Set<int> _selectedMemberIds = <int>{};

  static const _statuses = <String>['active', 'on_hold', 'completed', 'cancelled'];

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadUsers();
    _prefillFromProject();
  }

  void _prefillFromProject() {
    final project = widget.project;
    if (project == null) return;

    _nameController.text = project.name;
    _descriptionController.text = project.description;
    _startDateController.text = _toYmd(project.startDate);
    _dueDateController.text = _toYmd(project.dueDate);
    final status = project.status.trim().toLowerCase();
    if (_statuses.contains(status)) {
      _selectedStatus = status;
    }
    _selectedMemberIds
      ..clear()
      ..addAll(project.members.map((m) => m.id));
  }

  String _toYmd(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    try {
      final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
      final date = DateTime.parse(normalized).toLocal();
      return '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    _nameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    DateTime? firstDate,
  }) async {
    final now = DateTime.now();
    final current = _tryParseDate(controller.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(firstDate ?? DateTime(now.year - 1))
          ? (firstDate ?? now)
          : current,
      firstDate: firstDate ?? DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    controller.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  DateTime? _tryParseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw.trim());
    } catch (_) {
      return null;
    }
  }

  String _toLabel(String raw) {
    if (raw.trim().isEmpty) return '-';
    return raw
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Future<void> _openMembersSheet() async {
    if (_appController.usersLoading) return;
    if (_appController.usersError != null) {
      await _appController.loadUsers();
      if (!mounted) return;
    }

    final selected = Set<int>.from(_selectedMemberIds);
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MembersBottomSheet(
          initiallySelected: selected,
          toLabel: _toLabel,
        );
      },
    );

    if (result == null || !mounted) return;
    setState(() {
      _selectedMemberIds
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    final startDate = _tryParseDate(_startDateController.text.trim());
    final dueDate = _tryParseDate(_dueDateController.text.trim());
    if (startDate != null && dueDate != null && dueDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Due date must be same as or after start date')),
      );
      return;
    }

    final Map<String, dynamic>? response;
    if (_isEditing) {
      response = await _appController.updateProject(
        projectId: widget.project!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _selectedStatus,
        startDate: _startDateController.text.trim(),
        dueDate: _dueDateController.text.trim(),
        memberIds: _selectedMemberIds.toList()..sort(),
      );
    } else {
      response = await _appController.createProject(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _selectedStatus,
        startDate: _startDateController.text.trim(),
        dueDate: _dueDateController.text.trim(),
        memberIds: _selectedMemberIds.toList()..sort(),
      );
    }

    if (!mounted) return;
    if (response != null) {
      final fallback = _isEditing ? 'Project updated successfully' : 'Project created successfully';
      final message = (response['message'] ?? fallback).toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(true);
      return;
    }

    final error = _isEditing
        ? (_appController.updateProjectError ?? 'Failed to update project')
        : (_appController.createProjectError ?? 'Failed to create project');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = _appController.users.where((user) => user.isActive).toList();
    final usersLoading = _appController.usersLoading;
    final usersError = _appController.usersError;
    final submitting = _isEditing
        ? _appController.updateProjectLoading
        : _appController.createProjectLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Project' : 'Create Project'),
        leading: const AppBackButton(),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                _isEditing ? 'Update Project' : 'New Project',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isEditing
                    ? 'Update project details and team members'
                    : 'Create a project and assign team members',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter project name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                items: _statuses
                    .map(
                      (status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(_toLabel(status)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedStatus = value);
                },
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _startDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  hintText: 'Select start date',
                  suffixIcon: IconButton(
                    onPressed: () => _pickDate(controller: _startDateController),
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                ),
                onTap: () => _pickDate(controller: _startDateController),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please select start date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Due Date',
                  hintText: 'Select due date',
                  suffixIcon: IconButton(
                    onPressed: () => _pickDate(
                      controller: _dueDateController,
                      firstDate: _tryParseDate(_startDateController.text.trim()),
                    ),
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                ),
                onTap: () => _pickDate(
                  controller: _dueDateController,
                  firstDate: _tryParseDate(_startDateController.text.trim()),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please select due date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Members',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select users to add to this project',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
              ),
              const SizedBox(height: 10),
              if (usersError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          usersError,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFC62828),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _appController.loadUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              InkWell(
                onTap: usersLoading || users.isEmpty ? null : _openMembersSheet,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Select Members',
                    suffixIcon: usersLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.keyboard_arrow_up_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _selectedMemberIds.isEmpty
                        ? (users.isEmpty ? 'No users available' : 'Tap to select members')
                        : '${_selectedMemberIds.length} member(s) selected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _selectedMemberIds.isEmpty
                          ? const Color(0xFF6A778B)
                          : const Color(0xFF1E293B),
                      fontWeight: _selectedMemberIds.isEmpty ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (_selectedMemberIds.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: users
                      .where((user) => _selectedMemberIds.contains(user.id))
                      .map(
                        (user) => Chip(
                          label: Text(user.name),
                          backgroundColor: AppTheme.navy.withValues(alpha: 0.08),
                          deleteIconColor: AppTheme.navy,
                          onDeleted: () {
                            setState(() => _selectedMemberIds.remove(user.id));
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.navy, AppTheme.lightNavy],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: FilledButton(
                  onPressed: submitting || usersLoading || users.isEmpty
                      ? null
                      : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: submitting
                      ? const AppButtonLoader(size: 22)
                      : Text(_isEditing ? 'Update Project' : 'Create Project'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersBottomSheet extends StatefulWidget {
  const _MembersBottomSheet({
    required this.initiallySelected,
    required this.toLabel,
  });

  final Set<int> initiallySelected;
  final String Function(String) toLabel;

  @override
  State<_MembersBottomSheet> createState() => _MembersBottomSheetState();
}

class _MembersBottomSheetState extends State<_MembersBottomSheet> {
  late final AppController _appController;
  late final Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _selected = Set<int>.from(widget.initiallySelected);
    _appController.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = _appController.users.where((user) => user.isActive).toList();
    final media = MediaQuery.of(context);

    return Container(
      height: media.size.height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD7DEEA),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Members',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.navy,
                        ),
                      ),
                      Text(
                        '${_selected.length} selected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6A778B),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _appController.usersLoading
                ? const Center(child: AppLoader(size: 28))
                : users.isEmpty
                    ? const Center(child: Text('No users available'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                        itemCount: users.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final selected = _selected.contains(user.id);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selected.add(user.id);
                                } else {
                                  _selected.remove(user.id);
                                }
                              });
                            },
                            title: Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('${user.email} · ${widget.toLabel(user.role)}'),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppTheme.navy,
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _selected.isEmpty
                      ? 'Confirm Selection'
                      : 'Confirm ${_selected.length} Member(s)',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
