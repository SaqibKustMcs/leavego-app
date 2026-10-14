import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/projects_response.dart';
import 'package:leavego_app/ui/screens/select_project_members_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/ui/widgets/attachment_row.dart';
import 'package:leavego_app/ui/widgets/share_with_row.dart';
import 'package:leavego_app/ui/widgets/task_links_field.dart';

class CreateProjectTaskScreen extends StatefulWidget {
  const CreateProjectTaskScreen({super.key, required this.project});

  final ProjectItem project;

  @override
  State<CreateProjectTaskScreen> createState() => _CreateProjectTaskScreenState();
}

class _CreateProjectTaskScreenState extends State<CreateProjectTaskScreen> {
  static const Color _primary = Color(0xFF173559);
  static const Color _muted = Color(0xFF6A778B);
  static const Color _fieldBorder = Color(0xFFEEF4F2);
  static const double _fieldHeight = 54;
  static const double _fieldRadius = 8;
  static const double _fieldBorderWidth = 0.5;
  static const String _calendarIcon = 'assets/images/calendar-range.png';
  late final AppController _appController;
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _dueDateController = TextEditingController();

  String? _selectedPriority;
  final List<String> _links = <String>[];
  final List<String> _attachmentPaths = <String>[];
  String? _pendingAttachmentName;
  final Set<int> _selectedAssigneeIds = <int>{};

  static const _priorities = <String>['urgent', 'high', 'medium', 'critical'];

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _selectedPriority = 'urgent';
    _appController.loadProjectMembers(projectId: widget.project.id);
    _appController.loadUsers();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Set<int> get _allowedAssigneeIds =>
      _appController.projectMembers.map((member) => member.id).toSet();

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

  Future<void> _pickDateTime({
    required TextEditingController controller,
    DateTime? firstDate,
  }) async {
    final now = DateTime.now();
    final current = _tryParseDate(controller.text) ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: firstDate ?? DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    controller.text = _formatDateTime(combined);
  }

  String _formatDateTime(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final hour24 = dateTime.hour;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final h = hour12.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min $period';
  }

  DateTime? _tryParseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final amPmMatch = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})\s+(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value);
    if (amPmMatch != null) {
      final year = int.parse(amPmMatch.group(1)!);
      final month = int.parse(amPmMatch.group(2)!);
      final day = int.parse(amPmMatch.group(3)!);
      var hour = int.parse(amPmMatch.group(4)!);
      final minute = int.parse(amPmMatch.group(5)!);
      final period = amPmMatch.group(6)!.toUpperCase();

      if (period == 'AM') {
        if (hour == 12) hour = 0;
      } else if (hour != 12) {
        hour += 12;
      }
      return DateTime(year, month, day, hour, minute);
    }

    try {
      final normalized = value.contains(' ') ? value.replaceFirst(' ', 'T') : value;
      return DateTime.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  String _toApiDate(String raw) {
    final parsed = _tryParseDate(raw);
    if (parsed == null) return raw.split(' ').first;
    final y = parsed.year.toString().padLeft(4, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _toApiTime(String raw) {
    final parsed = _tryParseDate(raw);
    if (parsed == null) return '09:00';
    final h = parsed.hour.toString().padLeft(2, '0');
    final min = parsed.minute.toString().padLeft(2, '0');
    return '$h:$min';
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

  String _priorityLabel(String priority) {
    final value = priority.trim().toLowerCase();
    if (value == 'medium' || value == 'low') return 'Normal';
    return _toLabel(priority);
  }

  Future<void> _pickAttachment({required FileType type}) async {
    final result = await FilePicker.platform.pickFiles(type: type, allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final path = file.path;
    if (path == null || path.trim().isEmpty) return;
    setState(() {
      _attachmentPaths.add(path);
      _pendingAttachmentName = file.name;
    });
  }

  Future<void> _addLink() async {
    final link = await TaskLinksField.promptForLink(context);
    if (link == null || !mounted) return;
    if (_links.contains(link)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This link is already added')),
      );
      return;
    }
    setState(() => _links.add(link));
  }

  Future<void> _openAssigneePicker() async {
    if (_appController.usersLoading || _appController.projectMembersLoading) return;
    if (_appController.usersError != null) {
      await _appController.loadUsers();
      if (!mounted) return;
    }
    if (_allowedAssigneeIds.isEmpty) return;

    final result = await Navigator.of(context).push<Set<int>>(
      MaterialPageRoute(
        builder: (_) => SelectProjectMembersScreen(
          initiallySelected: Set<int>.from(_selectedAssigneeIds),
          allowedUserIds: _allowedAssigneeIds,
          appBarTitle: 'Select Assignees',
        ),
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _selectedAssigneeIds
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_selectedAssigneeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one assignee')),
      );
      return;
    }

    final startDate = _tryParseDate(_startDateController.text.trim());
    final dueDate = _tryParseDate(_dueDateController.text.trim());
    if (startDate != null && dueDate != null && dueDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be same as or after start date')),
      );
      return;
    }

    final response = await _appController.createProjectTask(
      projectId: widget.project.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _selectedPriority!,
      assignedUserIds: _selectedAssigneeIds.toList(),
      startDate: _toApiDate(_startDateController.text.trim()),
      startTime: _toApiTime(_startDateController.text.trim()),
      dueDate: _toApiDate(_dueDateController.text.trim()),
      dueTime: _toApiTime(_dueDateController.text.trim()),
      estimatedHours: 1,
      links: List<String>.from(_links),
      attachmentFilePaths: List<String>.from(_attachmentPaths),
    );

    if (!mounted) return;
    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty ? response.message : 'Task created successfully',
          ),
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    final error = _appController.createTaskError ?? 'Failed to create task';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = _appController.users
        .where((user) => user.isActive && _allowedAssigneeIds.contains(user.id))
        .toList();
    final usersLoading = _appController.usersLoading || _appController.projectMembersLoading;
    final membersError = _appController.projectMembersError;
    final selectedUsers = users.where((u) => _selectedAssigneeIds.contains(u.id)).toList();
    final membersAvailable = _allowedAssigneeIds.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(color: _primary),
        title: Text(
          'Create Task',
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
                'New Task',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _primary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              _singleLineField(
                child: TextFormField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 16, height: 1.2),
                  decoration: _fieldDecoration(hint: 'Title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please enter title';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 6,
                style: const TextStyle(fontSize: 16, height: 1.3),
                decoration: _fieldDecoration(hint: 'Description'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter description';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _singleLineField(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedPriority,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
                  decoration: _fieldDecoration(label: 'Priority'),
                  items: _priorities
                      .map(
                        (priority) => DropdownMenuItem<String>(
                          value: priority,
                          child: Text(
                            _priorityLabel(priority),
                            style: const TextStyle(fontSize: 16, color: Color(0xFF6E6E6E)),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedPriority = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please select priority';
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
                      onPressed: () => _pickDateTime(controller: _startDateController),
                    ),
                  ),
                  onTap: () => _pickDateTime(controller: _startDateController),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please select start date';
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
                      onPressed: () => _pickDateTime(
                        controller: _dueDateController,
                        firstDate: _tryParseDate(_startDateController.text.trim()),
                      ),
                    ),
                  ),
                  onTap: () => _pickDateTime(
                    controller: _dueDateController,
                    firstDate: _tryParseDate(_startDateController.text.trim()),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please select end date';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              AttachmentRow(
                attachmentName: _pendingAttachmentName ??
                    (_attachmentPaths.isEmpty ? null : '${_attachmentPaths.length} file(s)'),
                onDocument: () => _pickAttachment(type: FileType.any),
                onGallery: () => _pickAttachment(type: FileType.image),
                onCamera: () => _pickAttachment(type: FileType.image),
              ),
              const SizedBox(height: 12),
              TaskLinksField(
                links: _links,
                onAddLink: _addLink,
                onRemoveLink: (index) => setState(() => _links.removeAt(index)),
              ),
              const SizedBox(height: 28),
              Text(
                'Assign to',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _primary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select one or more project members',
                style: theme.textTheme.bodySmall?.copyWith(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (membersError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    membersError,
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFC62828)),
                  ),
                ),
              ShareWithRow(
                label: 'Share with',
                usersLoading: usersLoading,
                usersAvailable: membersAvailable && users.isNotEmpty,
                selectedUsers: selectedUsers,
                onTap: !membersAvailable || usersLoading ? null : _openAssigneePicker,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _appController.createTaskLoading || usersLoading || !membersAvailable
                      ? null
                      : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _primary.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_fieldRadius),
                    ),
                    elevation: 0,
                  ),
                  child: _appController.createTaskLoading
                      ? const AppButtonLoader(size: 22)
                      : const Text(
                          'Create Task',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
