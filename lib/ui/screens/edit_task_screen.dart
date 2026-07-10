import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/departments_response.dart';
import 'package:leavego_app/models/tasks_response.dart';
import 'package:leavego_app/models/users_response.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class EditTaskScreen extends StatefulWidget {
  const EditTaskScreen({super.key, required this.task});

  final TaskItem task;

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late final AppController _appController;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _estimatedHoursController = TextEditingController();

  String? _selectedPriority;
  String? _selectedStatus;
  String? _selectedAssignedTo;
  String? _selectedDepartmentId;

  final titleError = ''.obs;
  final descriptionError = ''.obs;
  final priorityError = ''.obs;
  final statusError = ''.obs;
  final assignedToError = ''.obs;
  final departmentError = ''.obs;
  final startDateError = ''.obs;
  final dueDateError = ''.obs;
  final estimatedHoursError = ''.obs;

  static const _priorities = <String>['low', 'medium', 'high', 'urgent', 'critical'];
  static const _statuses = <String>['assigned', 'in_progress', 'qa', 'completed', 'overdue'];

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _titleController.text = widget.task.title;
    _descriptionController.text = widget.task.description;
    _startDateController.text = _toDateOnly(widget.task.startDate);
    _dueDateController.text = _toDateOnly(widget.task.dueDate);
    _estimatedHoursController.text = widget.task.estimatedHours.toString();
    _selectedPriority = _priorities.contains(widget.task.priority) ? widget.task.priority : null;
    _selectedStatus = _statuses.contains(widget.task.status) ? widget.task.status : null;
    _selectedAssignedTo = widget.task.assignedTo;
    _selectedDepartmentId = widget.task.departmentId;

    if (_appController.users.isEmpty) {
      _appController.loadUsers();
    }
    if (_appController.departments.isEmpty) {
      _appController.loadDepartments();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _dueDateController.dispose();
    _estimatedHoursController.dispose();
    super.dispose();
  }

  String _toDateOnly(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    try {
      final date = DateTime.parse(raw).toLocal();
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}-$month-$day';
    } catch (_) {
      return raw.split('T').first;
    }
  }

  DateTime? _tryParseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
      return DateTime.parse(normalized);
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

  void _clearErrors() {
    titleError.value = '';
    descriptionError.value = '';
    priorityError.value = '';
    statusError.value = '';
    assignedToError.value = '';
    departmentError.value = '';
    startDateError.value = '';
    dueDateError.value = '';
    estimatedHoursError.value = '';
  }

  Future<void> _pickDate({required TextEditingController controller, DateTime? firstDate}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final allowedFirstDate = firstDate ?? today;
    final initial = _tryParseDate(controller.text) ?? allowedFirstDate;
    final safeInitial = initial.isBefore(allowedFirstDate) ? allowedFirstDate : initial;

    final selected = await showDatePicker(
      context: context,
      firstDate: allowedFirstDate,
      lastDate: DateTime(2100),
      initialDate: safeInitial,
    );
    if (selected == null) return;

    final month = selected.month.toString().padLeft(2, '0');
    final day = selected.day.toString().padLeft(2, '0');
    controller.text = '${selected.year}-$month-$day';
  }

  Future<void> _submit() async {
    _clearErrors();
    var isValid = true;

    if (_titleController.text.trim().isEmpty) {
      titleError.value = 'Please enter title';
      isValid = false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      descriptionError.value = 'Please enter description';
      isValid = false;
    }
    if (_selectedPriority == null || _selectedPriority!.isEmpty) {
      priorityError.value = 'Please select priority';
      isValid = false;
    }
    if (_selectedStatus == null || _selectedStatus!.isEmpty) {
      statusError.value = 'Please select status';
      isValid = false;
    }
    if (_selectedAssignedTo == null || _selectedAssignedTo!.isEmpty) {
      assignedToError.value = 'Please select assignee';
      isValid = false;
    }
    if (_selectedDepartmentId == null || _selectedDepartmentId!.isEmpty) {
      departmentError.value = 'Please select department';
      isValid = false;
    }
    if (_startDateController.text.trim().isEmpty) {
      startDateError.value = 'Please select start date';
      isValid = false;
    }
    if (_dueDateController.text.trim().isEmpty) {
      dueDateError.value = 'Please select end date';
      isValid = false;
    }

    final estimatedHoursRaw = _estimatedHoursController.text.trim();
    final estimatedHours = int.tryParse(estimatedHoursRaw);
    if (estimatedHoursRaw.isEmpty) {
      estimatedHoursError.value = 'Please enter estimated hours';
      isValid = false;
    } else if (estimatedHours == null || estimatedHours <= 0) {
      estimatedHoursError.value = 'Estimated hours must be greater than 0';
      isValid = false;
    }

    final startDate = _tryParseDate(_startDateController.text.trim());
    final dueDate = _tryParseDate(_dueDateController.text.trim());
    if (startDate != null && dueDate != null && dueDate.isBefore(startDate)) {
      dueDateError.value = 'Due date must be same as or after start date';
      isValid = false;
    }

    if (!isValid) return;

    final response = await _appController.updateTask(
      taskId: widget.task.id.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _selectedPriority!,
      status: _selectedStatus!,
      assignedTo: _selectedAssignedTo!,
      departmentId: _selectedDepartmentId!,
      startDate: _startDateController.text.trim(),
      dueDate: _dueDateController.text.trim(),
      estimatedHours: estimatedHours ?? 1,
    );

    if (!mounted) return;

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty ? response.message : 'Task updated successfully',
          ),
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    if (_appController.updateTaskError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_appController.updateTaskError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = _appController.users.where((user) => user.isActive).toList();
    final departments = _appController.departments
        .where((department) => department.isActive)
        .toList();

    if (_selectedAssignedTo != null &&
        !users.any((user) => user.id.toString() == _selectedAssignedTo)) {
      _selectedAssignedTo = null;
    }
    if (_selectedDepartmentId != null &&
        !departments.any((department) => department.id.toString() == _selectedDepartmentId)) {
      _selectedDepartmentId = null;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      appBar: AppBar(
        title: const Text('Edit Task'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.navy,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Task',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Edit task info, assignment, status, and dates.',
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
                  ),
                  if (_appController.usersLoading || _appController.departmentsLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: AppLoader(size: 24),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Task Type: ${_toLabel(widget.task.taskType)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6A778B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => TextField(
                      controller: _titleController,
                      onChanged: (_) => titleError.value = '',
                      decoration: InputDecoration(
                        labelText: 'Title',
                        errorText: titleError.value.isEmpty ? null : titleError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      onChanged: (_) => descriptionError.value = '',
                      decoration: InputDecoration(
                        labelText: 'Description',
                        errorText: descriptionError.value.isEmpty ? null : descriptionError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      items: _priorities
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(_toLabel(value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedPriority = value);
                        priorityError.value = '';
                      },
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        errorText: priorityError.value.isEmpty ? null : priorityError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      items: _statuses
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(_toLabel(value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedStatus = value);
                        statusError.value = '';
                      },
                      decoration: InputDecoration(
                        labelText: 'Status',
                        errorText: statusError.value.isEmpty ? null : statusError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: _selectedAssignedTo,
                      items: users
                          .map(
                            (user) => DropdownMenuItem<String>(
                              value: user.id.toString(),
                              child: Text('${user.name} • ${user.role}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedAssignedTo = value);
                        assignedToError.value = '';
                      },
                      decoration: InputDecoration(
                        labelText: 'Assign To',
                        errorText: assignedToError.value.isEmpty ? null : assignedToError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: _selectedDepartmentId,
                      items: departments
                          .map(
                            (department) => DropdownMenuItem<String>(
                              value: department.id.toString(),
                              child: Text(department.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedDepartmentId = value);
                        departmentError.value = '';
                      },
                      decoration: InputDecoration(
                        labelText: 'Department',
                        errorText: departmentError.value.isEmpty ? null : departmentError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => TextField(
                      controller: _startDateController,
                      readOnly: true,
                      onTap: () async {
                        startDateError.value = '';
                        await _pickDate(controller: _startDateController);
                      },
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        hintText: 'YYYY-MM-DD',
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                        errorText: startDateError.value.isEmpty ? null : startDateError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => TextField(
                      controller: _dueDateController,
                      readOnly: true,
                      onTap: () async {
                        dueDateError.value = '';
                        final start = _tryParseDate(_startDateController.text);
                        await _pickDate(controller: _dueDateController, firstDate: start);
                      },
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        hintText: 'YYYY-MM-DD',
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                        errorText: dueDateError.value.isEmpty ? null : dueDateError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => TextField(
                      controller: _estimatedHoursController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => estimatedHoursError.value = '',
                      decoration: InputDecoration(
                        labelText: 'Estimated Hours',
                        errorText: estimatedHoursError.value.isEmpty
                            ? null
                            : estimatedHoursError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.navy, AppTheme.lightNavy]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: FilledButton(
                      onPressed: _appController.updateTaskLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _appController.updateTaskLoading
                          ? const AppButtonLoader(size: 22)
                          : const Text('Update Task'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
