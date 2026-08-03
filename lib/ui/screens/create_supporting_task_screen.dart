import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/tasks_response.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class CreateSupportingTaskScreen extends StatefulWidget {
  const CreateSupportingTaskScreen({super.key, required this.task});

  final TaskItem task;

  @override
  State<CreateSupportingTaskScreen> createState() =>
      _CreateSupportingTaskScreenState();
}

class _CreateSupportingTaskScreenState extends State<CreateSupportingTaskScreen> {
  late final AppController _appController;
  final _timelineNoteController = TextEditingController();

  String? _selectedRequestedTo;

  final requestedToError = ''.obs;
  final timelineNoteError = ''.obs;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onControllerUpdate);
    if (_appController.meData == null) {
      _appController.loadMe();
    }
    if (_appController.users.isEmpty) {
      _appController.loadUsers();
    }
    _selectedRequestedTo = widget.task.assignedTo;
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onControllerUpdate);
    _timelineNoteController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    requestedToError.value = '';
    timelineNoteError.value = '';
  }

  Future<void> _submit() async {
    _clearErrors();
    var isValid = true;

    if (_selectedRequestedTo == null || _selectedRequestedTo!.isEmpty) {
      requestedToError.value = 'Please select requested user';
      isValid = false;
    }

    if (_timelineNoteController.text.trim().isEmpty) {
      timelineNoteError.value = 'Please enter timeline note';
      isValid = false;
    }

    if (!isValid) return;

    final response = await _appController.createSupportingTask(
      taskId: widget.task.id.toString(),
      requestedTo: _selectedRequestedTo!,
      timelineNote: _timelineNoteController.text.trim(),
    );

    if (!mounted) return;

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : 'Supporting task created successfully',
          ),
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    if (_appController.createSupportingTaskError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_appController.createSupportingTaskError!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = _appController.meData?.id.toString();
    final users = _appController.users
        .where(
          (user) => user.isActive && user.id.toString() != currentUserId,
        )
        .toList();

    if (_selectedRequestedTo != null &&
        !users.any((user) => user.id.toString() == _selectedRequestedTo)) {
      _selectedRequestedTo = null;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      appBar: AppBar(
        title: const Text('Create Supporting Task'),
        leading: const AppBackButton(),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
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
                    'Support Request',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create a supporting task request for this task.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6A778B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ReadOnlyInfo(
                    label: 'Parent Task',
                    value: widget.task.title,
                  ),
                  const SizedBox(height: 12),
                  _ReadOnlyInfo(
                    label: 'Task ID',
                    value: '#${widget.task.id}',
                  ),
                  if (_appController.usersLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: AppLoader(size: 24),
                    ),
                  const SizedBox(height: 12),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: _selectedRequestedTo,
                      items: users
                          .map(
                            (user) => DropdownMenuItem<String>(
                              value: user.id.toString(),
                              child: Text('${user.name} • ${user.role}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedRequestedTo = value);
                        requestedToError.value = '';
                      },
                      decoration: InputDecoration(
                        labelText: 'Requested To',
                        errorText: requestedToError.value.isEmpty
                            ? null
                            : requestedToError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => TextField(
                      controller: _timelineNoteController,
                      maxLines: 4,
                      onChanged: (_) => timelineNoteError.value = '',
                      decoration: InputDecoration(
                        labelText: 'Timeline Note',
                        hintText: 'Need support by tomorrow noon',
                        errorText: timelineNoteError.value.isEmpty
                            ? null
                            : timelineNoteError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.navy, AppTheme.lightNavy],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: FilledButton(
                      onPressed: _appController.createSupportingTaskLoading
                          ? null
                          : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _appController.createSupportingTaskLoading
                          ? const AppButtonLoader(size: 22)
                          : const Text('Create Supporting Task'),
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

class _ReadOnlyInfo extends StatelessWidget {
  const _ReadOnlyInfo({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6A778B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
