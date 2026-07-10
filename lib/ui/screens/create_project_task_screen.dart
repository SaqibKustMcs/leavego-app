import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/projects_response.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class CreateProjectTaskScreen extends StatefulWidget {
  const CreateProjectTaskScreen({super.key, required this.project});

  final ProjectItem project;

  @override
  State<CreateProjectTaskScreen> createState() => _CreateProjectTaskScreenState();
}

class _CreateProjectTaskScreenState extends State<CreateProjectTaskScreen> {
  late final AppController _appController;
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _estimatedHoursController = TextEditingController();

  String? _selectedPriority;
  String? _selectedAssignedTo;

  static const _priorities = <String>['low', 'medium', 'high', 'critical'];

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadProjectMembers(projectId: widget.project.id);
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
    _estimatedHoursController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tryParseDate(controller.text) ?? now,
      firstDate: firstDate ?? DateTime(now.year - 1),
      lastDate: lastDate ?? DateTime(now.year + 5),
    );
    if (picked == null) return;
    controller.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  DateTime? _tryParseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw);
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

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    final startDate = _tryParseDate(_startDateController.text.trim());
    final dueDate = _tryParseDate(_dueDateController.text.trim());
    if (startDate != null && dueDate != null && dueDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Due date must be same as or after start date')),
      );
      return;
    }

    final estimatedHours = int.tryParse(_estimatedHoursController.text.trim()) ?? 0;
    final response = await _appController.createProjectTask(
      projectId: widget.project.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _selectedPriority!,
      assignedTo: _selectedAssignedTo!,
      startDate: _startDateController.text.trim(),
      dueDate: _dueDateController.text.trim(),
      estimatedHours: estimatedHours,
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
    final members = _appController.projectMembers;
    final membersLoading = _appController.projectMembersLoading;
    final membersError = _appController.projectMembersError;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      appBar: AppBar(
        title: const Text('Create Task'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.navy,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                widget.project.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add a new task to this project',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter title';
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
                  if (value == null || value.trim().isEmpty) return 'Please enter description';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                items: _priorities
                    .map(
                      (priority) => DropdownMenuItem<String>(
                        value: priority,
                        child: Text(_toLabel(priority)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedPriority = value),
                decoration: const InputDecoration(labelText: 'Priority'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please select priority';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (membersLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: AppLoader(size: 28)),
                )
              else if (membersError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        membersError,
                        style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFC62828)),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _appController.loadProjectMembers(
                          projectId: widget.project.id,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (members.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No project members available to assign.',
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFF57F17)),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedAssignedTo,
                  items: members
                      .map(
                        (member) => DropdownMenuItem<String>(
                          value: member.id.toString(),
                          child: Text(member.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedAssignedTo = value),
                  decoration: const InputDecoration(labelText: 'Assign To'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please select assignee';
                    return null;
                  },
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _startDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  suffixIcon: IconButton(
                    onPressed: () => _pickDate(controller: _startDateController),
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please select start date';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Due Date',
                  suffixIcon: IconButton(
                    onPressed: () => _pickDate(controller: _dueDateController),
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please select due date';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _estimatedHoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Estimated Hours'),
                validator: (value) {
                  final hours = int.tryParse((value ?? '').trim());
                  if (hours == null || hours <= 0) {
                    return 'Please enter estimated hours greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.navy, AppTheme.lightNavy],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: FilledButton(
                  onPressed: _appController.createTaskLoading ||
                          membersLoading ||
                          members.isEmpty
                      ? null
                      : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _appController.createTaskLoading
                      ? const AppButtonLoader(size: 22)
                      : const Text('Create Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
