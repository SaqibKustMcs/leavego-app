import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/projects_response.dart';
import 'package:leavego_app/ui/screens/select_project_members_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/ui/widgets/share_with_row.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key, this.project});

  final ProjectItem? project;

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  static const Color _primary = Color(0xFF173559);
  static const Color _fieldBorder = Color(0xFFEEF4F2);
  static const Color _muted = Color(0xFF6A778B);
  static const double _fieldHeight = 54;
  static const double _fieldRadius = 8;
  static const double _fieldBorderWidth = 0.5;
  static const String _calendarIcon = 'assets/images/calendar-range.png';

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

  InputDecoration _fieldDecoration({String? hint, String? label, Widget? suffixIcon}) {
    final borderRadius = BorderRadius.circular(_fieldRadius);
    const border = BorderSide(color: _fieldBorder, width: _fieldBorderWidth);
    const focusedBorder = BorderSide(color: _primary, width: 1);

    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: const TextStyle(color: Color(0xFF6E6E6E), fontWeight: FontWeight.w400),
      labelStyle: const TextStyle(
        color: Color(0xFF6E6E6E),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(color: Color(0xFF6E6E6E), fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: borderRadius, borderSide: border),
      enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: border),
      focusedBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: focusedBorder),
      disabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: border),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  Widget _singleLineField({required Widget child}) {
    return SizedBox(height: _fieldHeight, child: child);
  }

  Widget _calendarSuffix({required VoidCallback onPressed}) {
    return IconButton(
      onPressed: onPressed,
      icon: Image.asset(_calendarIcon, width: 22, height: 22, fit: BoxFit.contain),
    );
  }

  Future<void> _pickDate({required TextEditingController controller, DateTime? firstDate}) async {
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
          (part) =>
              part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Future<void> _openMembersPicker() async {
    if (_appController.usersLoading) return;
    if (_appController.usersError != null) {
      await _appController.loadUsers();
      if (!mounted) return;
    }

    final selected = Set<int>.from(_selectedMemberIds);
    final result = await Navigator.of(context).push<Set<int>>(
      MaterialPageRoute(builder: (_) => SelectProjectMembersScreen(initiallySelected: selected)),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select at least one member')));
      return;
    }

    final startDate = _tryParseDate(_startDateController.text.trim());
    final dueDate = _tryParseDate(_dueDateController.text.trim());
    if (startDate != null && dueDate != null && dueDate.isBefore(startDate)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('End date must be same as or after start date')));
      return;
    }

    final description = _descriptionController.text.trim();

    final Map<String, dynamic>? response;
    if (_isEditing) {
      response = await _appController.updateProject(
        projectId: widget.project!.id,
        name: _nameController.text.trim(),
        description: description,
        status: _selectedStatus,
        startDate: _startDateController.text.trim(),
        dueDate: _dueDateController.text.trim(),
        memberIds: _selectedMemberIds.toList()..sort(),
      );
    } else {
      response = await _appController.createProject(
        name: _nameController.text.trim(),
        description: description,
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
    final selectedUsers = users.where((u) => _selectedMemberIds.contains(u.id)).toList();

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(color: _primary),
        title: Text(
          _isEditing ? 'Edit Project' : 'Create Project',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                _isEditing ? 'Update Project' : 'New Project',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: _primary,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),
              _singleLineField(
                child: TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 16, height: 1.2),
                  decoration: _fieldDecoration(hint: 'Project Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter project name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              _singleLineField(
                child: TextFormField(
                  controller: _startDateController,
                  readOnly: true,
                  style: const TextStyle(fontSize: 16, height: 1.2),
                  decoration: _fieldDecoration(
                    hint: 'Start Date',
                    suffixIcon: _calendarSuffix(
                      onPressed: () => _pickDate(controller: _startDateController),
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
              ),
              const SizedBox(height: 20),
              _singleLineField(
                child: TextFormField(
                  controller: _dueDateController,
                  readOnly: true,
                  style: const TextStyle(fontSize: 16, height: 1.2),
                  decoration: _fieldDecoration(
                    hint: 'End Date',
                    suffixIcon: _calendarSuffix(
                      onPressed: () => _pickDate(
                        controller: _dueDateController,
                        firstDate: _tryParseDate(_startDateController.text.trim()),
                      ),
                    ),
                  ),
                  onTap: () => _pickDate(
                    controller: _dueDateController,
                    firstDate: _tryParseDate(_startDateController.text.trim()),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please select end date';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              _singleLineField(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
                  decoration: _fieldDecoration(label: 'Status'),
                  items: _statuses
                      .map(
                        (status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(
                            _toLabel(status),
                            style: const TextStyle(fontSize: 16, color: Color(0xFF6E6E6E)),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedStatus = value);
                  },
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Members',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _primary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select users to add',
                style: theme.textTheme.bodySmall?.copyWith(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (usersError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
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
                      TextButton(onPressed: _appController.loadUsers, child: const Text('Retry')),
                    ],
                  ),
                ),
              ShareWithRow(
                usersLoading: usersLoading,
                usersAvailable: users.isNotEmpty,
                selectedUsers: selectedUsers,
                onTap: usersLoading || users.isEmpty ? null : _openMembersPicker,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: FilledButton(
                  onPressed: submitting || usersLoading || users.isEmpty ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _primary.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_fieldRadius),
                    ),
                    elevation: 0,
                  ),
                  child: submitting
                      ? const AppButtonLoader(size: 22)
                      : Text(
                          _isEditing ? 'Update Project' : 'Create Project',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
