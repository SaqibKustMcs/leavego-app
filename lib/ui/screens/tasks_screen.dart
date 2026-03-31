import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/departments_response.dart';
import 'package:leavego_app/models/users_response.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late final AppController _appController;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _estimatedHoursController = TextEditingController();

  String? _selectedTaskType;
  String? _selectedPriority;
  String? _selectedAssignedTo;
  String? _selectedDepartmentId;

  final titleError = ''.obs;
  final descriptionError = ''.obs;
  final taskTypeError = ''.obs;
  final priorityError = ''.obs;
  final assignedToError = ''.obs;
  final departmentError = ''.obs;
  final startDateError = ''.obs;
  final dueDateError = ''.obs;
  final estimatedHoursError = ''.obs;

  static const _taskTypes = <String>[
    'project_task',
    'development_task',
    'operational_task',
    'meeting',
  ];

  static const _priorities = <String>['low', 'medium', 'high', 'critical'];

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    if (_appController.meData == null) {
      _appController.loadMe();
    }
    _appController.loadUsers();
    _appController.loadDepartments();
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _dueDateController.dispose();
    _estimatedHoursController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait(<Future<void>>[
      _appController.loadMe(),
      _appController.loadUsers(),
      _appController.loadDepartments(),
    ]);
  }

  void _clearErrors() {
    titleError.value = '';
    descriptionError.value = '';
    taskTypeError.value = '';
    priorityError.value = '';
    assignedToError.value = '';
    departmentError.value = '';
    startDateError.value = '';
    dueDateError.value = '';
    estimatedHoursError.value = '';
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

  AppUserItem? _findUser(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final user in _appController.users) {
      if (user.id.toString() == id) return user;
    }
    return null;
  }

  DepartmentItem? _findDepartment(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final department in _appController.departments) {
      if (department.id.toString() == id) return department;
    }
    return null;
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
    if (_selectedTaskType == null || _selectedTaskType!.isEmpty) {
      taskTypeError.value = 'Please select task type';
      isValid = false;
    }
    if (_selectedPriority == null || _selectedPriority!.isEmpty) {
      priorityError.value = 'Please select priority';
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
      dueDateError.value = 'Please select due date';
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

    final response = await _appController.createTask(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      taskType: _selectedTaskType!,
      priority: _selectedPriority!,
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
            response.message.isNotEmpty ? response.message : 'Task created successfully',
          ),
        ),
      );
      _titleController.clear();
      _descriptionController.clear();
      _startDateController.clear();
      _dueDateController.clear();
      _estimatedHoursController.clear();
      setState(() {
        _selectedTaskType = null;
        _selectedPriority = null;
        _selectedAssignedTo = null;
        _selectedDepartmentId = null;
      });
      if (!mounted) return;
      _appController.requestSwitchToTasksTab();
      return;
    }

    if (_appController.createTaskError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_appController.createTaskError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = (_appController.meData?.role ?? '').trim().toLowerCase();
    final canCreateTask = role == '$role';

    final users = _appController.users.where((user) => user.isActive).toList();
    final departments = _appController.departments
        .where((department) => department.isActive)
        .toList();

    if (_selectedAssignedTo != null && _findUser(_selectedAssignedTo) == null) {
      _selectedAssignedTo = null;
    }
    if (_selectedDepartmentId != null && _findDepartment(_selectedDepartmentId) == null) {
      _selectedDepartmentId = null;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.navy, AppTheme.lightNavy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.task_alt_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Task',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            canCreateTask
                                ? 'Assign a new task to your team member'
                                : 'Only HOD and HR can create tasks',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_task_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (canCreateTask) ...[
                _TaskCreateCard(
                  theme: theme,
                  usersLoading: _appController.usersLoading,
                  departmentsLoading: _appController.departmentsLoading,
                  usersError: _appController.usersError,
                  departmentsError: _appController.departmentsError,
                  titleController: _titleController,
                  descriptionController: _descriptionController,
                  startDateController: _startDateController,
                  dueDateController: _dueDateController,
                  estimatedHoursController: _estimatedHoursController,
                  selectedTaskType: _selectedTaskType,
                  selectedPriority: _selectedPriority,
                  selectedAssignedTo: _selectedAssignedTo,
                  selectedDepartmentId: _selectedDepartmentId,
                  taskTypes: _taskTypes,
                  priorities: _priorities,
                  users: users,
                  departments: departments,
                  titleError: titleError,
                  descriptionError: descriptionError,
                  taskTypeError: taskTypeError,
                  priorityError: priorityError,
                  assignedToError: assignedToError,
                  departmentError: departmentError,
                  startDateError: startDateError,
                  dueDateError: dueDateError,
                  estimatedHoursError: estimatedHoursError,
                  createTaskLoading: _appController.createTaskLoading,
                  onTaskTypeChanged: (value) {
                    setState(() => _selectedTaskType = value);
                    taskTypeError.value = '';
                  },
                  onPriorityChanged: (value) {
                    setState(() => _selectedPriority = value);
                    priorityError.value = '';
                  },
                  onAssignedToChanged: (value) {
                    setState(() => _selectedAssignedTo = value);
                    assignedToError.value = '';
                  },
                  onDepartmentChanged: (value) {
                    setState(() => _selectedDepartmentId = value);
                    departmentError.value = '';
                  },
                  onPickStartDate: () async {
                    startDateError.value = '';
                    await _pickDate(controller: _startDateController);
                    if (_dueDateController.text.trim().isNotEmpty) {
                      final start = _tryParseDate(_startDateController.text);
                      final due = _tryParseDate(_dueDateController.text);
                      if (start != null && due != null && due.isBefore(start)) {
                        _dueDateController.clear();
                      }
                    }
                  },
                  onPickDueDate: () async {
                    dueDateError.value = '';
                    final start = _tryParseDate(_startDateController.text);
                    await _pickDate(controller: _dueDateController, firstDate: start);
                  },
                  onSubmit: _submit,
                ),
              ] else
                const _MessageCard(
                  message: 'Task creation is available only for HOD and HR users.',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCreateCard extends StatelessWidget {
  const _TaskCreateCard({
    required this.theme,
    required this.usersLoading,
    required this.departmentsLoading,
    required this.usersError,
    required this.departmentsError,
    required this.titleController,
    required this.descriptionController,
    required this.startDateController,
    required this.dueDateController,
    required this.estimatedHoursController,
    required this.selectedTaskType,
    required this.selectedPriority,
    required this.selectedAssignedTo,
    required this.selectedDepartmentId,
    required this.taskTypes,
    required this.priorities,
    required this.users,
    required this.departments,
    required this.titleError,
    required this.descriptionError,
    required this.taskTypeError,
    required this.priorityError,
    required this.assignedToError,
    required this.departmentError,
    required this.startDateError,
    required this.dueDateError,
    required this.estimatedHoursError,
    required this.createTaskLoading,
    required this.onTaskTypeChanged,
    required this.onPriorityChanged,
    required this.onAssignedToChanged,
    required this.onDepartmentChanged,
    required this.onPickStartDate,
    required this.onPickDueDate,
    required this.onSubmit,
  });

  final ThemeData theme;
  final bool usersLoading;
  final bool departmentsLoading;
  final String? usersError;
  final String? departmentsError;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController startDateController;
  final TextEditingController dueDateController;
  final TextEditingController estimatedHoursController;
  final String? selectedTaskType;
  final String? selectedPriority;
  final String? selectedAssignedTo;
  final String? selectedDepartmentId;
  final List<String> taskTypes;
  final List<String> priorities;
  final List<AppUserItem> users;
  final List<DepartmentItem> departments;
  final RxString titleError;
  final RxString descriptionError;
  final RxString taskTypeError;
  final RxString priorityError;
  final RxString assignedToError;
  final RxString departmentError;
  final RxString startDateError;
  final RxString dueDateError;
  final RxString estimatedHoursError;
  final bool createTaskLoading;
  final ValueChanged<String?> onTaskTypeChanged;
  final ValueChanged<String?> onPriorityChanged;
  final ValueChanged<String?> onAssignedToChanged;
  final ValueChanged<String?> onDepartmentChanged;
  final Future<void> Function() onPickStartDate;
  final Future<void> Function() onPickDueDate;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Create Task',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Assign a new task to your team member.',
            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
          ),
          if (usersLoading || departmentsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (usersError != null || departmentsError != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                [
                  if (usersError != null) usersError!,
                  if (departmentsError != null) departmentsError!,
                ].join('\n'),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: 12),
          Obx(
            () => TextField(
              controller: titleController,
              onChanged: (_) => titleError.value = '',
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Prepare Sprint Report',
                errorText: titleError.value.isEmpty ? null : titleError.value,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => TextField(
              controller: descriptionController,
              maxLines: 3,
              onChanged: (_) => descriptionError.value = '',
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Write task details...',
                errorText: descriptionError.value.isEmpty ? null : descriptionError.value,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => DropdownButtonFormField<String>(
              value: selectedTaskType,
              items: taskTypes
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.replaceAll('_', ' ')),
                    ),
                  )
                  .toList(),
              onChanged: onTaskTypeChanged,
              decoration: InputDecoration(
                labelText: 'Task Type',
                errorText: taskTypeError.value.isEmpty ? null : taskTypeError.value,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => DropdownButtonFormField<String>(
              value: selectedPriority,
              items: priorities
                  .map(
                    (value) =>
                        DropdownMenuItem<String>(value: value, child: Text(value.toUpperCase())),
                  )
                  .toList(),
              onChanged: onPriorityChanged,
              decoration: InputDecoration(
                labelText: 'Priority',
                errorText: priorityError.value.isEmpty ? null : priorityError.value,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => DropdownButtonFormField<String>(
              value: selectedAssignedTo,
              items: users
                  .map(
                    (user) => DropdownMenuItem<String>(
                      value: user.id.toString(),
                      child: Text('${user.name} • ${user.role}'),
                    ),
                  )
                  .toList(),
              onChanged: onAssignedToChanged,
              decoration: InputDecoration(
                labelText: 'Assign To',
                errorText: assignedToError.value.isEmpty ? null : assignedToError.value,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => DropdownButtonFormField<String>(
              value: selectedDepartmentId,
              items: departments
                  .map(
                    (department) => DropdownMenuItem<String>(
                      value: department.id.toString(),
                      child: Text(department.name),
                    ),
                  )
                  .toList(),
              onChanged: onDepartmentChanged,
              decoration: InputDecoration(
                labelText: 'Department',
                errorText: departmentError.value.isEmpty ? null : departmentError.value,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => TextField(
              controller: startDateController,
              readOnly: true,
              onTap: onPickStartDate,
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
              controller: dueDateController,
              readOnly: true,
              onTap: onPickDueDate,
              decoration: InputDecoration(
                labelText: 'Due Date',
                hintText: 'YYYY-MM-DD',
                suffixIcon: const Icon(Icons.calendar_today_outlined),
                errorText: dueDateError.value.isEmpty ? null : dueDateError.value,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => TextField(
              controller: estimatedHoursController,
              keyboardType: TextInputType.number,
              onChanged: (_) => estimatedHoursError.value = '',
              decoration: InputDecoration(
                labelText: 'Estimated Hours',
                hintText: 'e.g., 6',
                errorText: estimatedHoursError.value.isEmpty ? null : estimatedHoursError.value,
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
              onPressed: createTaskLoading ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: createTaskLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Task'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isError ? theme.colorScheme.error : const Color(0xFF5F6D84);
    final background = isError
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
        : Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: isError ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
