import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/leave_type_response.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  late final AppController _appController;
  LeaveTypeItem? _selectedLeaveType;
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _attachmentPath;
  String? _dateValidationError;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadLeaveTypes();
  }

  void _onUpdate() {
    if (!mounted) return;
    if (_selectedLeaveType == null && _appController.leaveTypes.isNotEmpty) {
      _selectedLeaveType = _appController.leaveTypes.first;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    _startDateController.dispose();
    _endDateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  DateTime? _tryParseYmd(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  bool _validateDateRange({bool showMessage = false}) {
    final start = _tryParseYmd(_startDateController.text.trim());
    final end = _tryParseYmd(_endDateController.text.trim());

    if (start == null || end == null) {
      setState(() => _dateValidationError = null);
      return true;
    }

    if (end.isBefore(start)) {
      const msg = 'End date must be same as or after start date';
      setState(() => _dateValidationError = msg);
      if (showMessage) _showSnack(msg);
      return false;
    }

    setState(() => _dateValidationError = null);
    return true;
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final selectedStart = _tryParseYmd(_startDateController.text);

    final firstAllowedDate = isStartDate
        ? todayDateOnly
        : (selectedStart != null && !selectedStart.isBefore(todayDateOnly)
              ? selectedStart
              : todayDateOnly);

    final initial =
        (isStartDate
            ? _tryParseYmd(_startDateController.text)
            : _tryParseYmd(_endDateController.text)) ??
        firstAllowedDate;

    final safeInitial = initial.isBefore(firstAllowedDate)
        ? firstAllowedDate
        : initial;

    final selected = await showDatePicker(
      context: context,
      firstDate: firstAllowedDate,
      lastDate: DateTime(2100),
      initialDate: safeInitial,
    );
    if (selected == null) return;
    final month = selected.month.toString().padLeft(2, '0');
    final day = selected.day.toString().padLeft(2, '0');
    final formatted = '${selected.year}-$month-$day';

    if (isStartDate) {
      _startDateController.text = formatted;
      final end = _tryParseYmd(_endDateController.text);
      if (end != null && end.isBefore(selected)) {
        _endDateController.clear();
      }
    } else {
      final start = _tryParseYmd(_startDateController.text);
      if (start != null && selected.isBefore(start)) {
        _showSnack('End date cannot be before start date');
        return;
      }
      _endDateController.text = formatted;
    }

    _validateDateRange();
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    setState(() => _attachmentPath = result.files.single.path);
  }

  Future<void> _submit() async {
    if (_selectedLeaveType == null) {
      _showSnack('Please select leave type');
      return;
    }
    if (_startDateController.text.trim().isEmpty ||
        _endDateController.text.trim().isEmpty) {
      _showSnack('Please select start and end date');
      return;
    }
    if (!_validateDateRange(showMessage: true)) return;
    if (_reasonController.text.trim().isEmpty) {
      _showSnack('Please enter reason');
      return;
    }

    final response = await _appController.applyLeave(
      leaveTypeId: _selectedLeaveType!.id,
      startDate: _startDateController.text.trim(),
      endDate: _endDateController.text.trim(),
      reason: _reasonController.text.trim(),
      attachmentPath: _attachmentPath,
    );
    if (!mounted) return;
    if (response != null) {
      _showSnack(
        response.message.isNotEmpty
            ? response.message
            : 'Leave request submitted',
      );
      await _appController.loadMyLeaves();
      if (!mounted) return;
      Navigator.of(context).pop();
    } else if (_appController.applyLeaveError != null) {
      _showSnack(_appController.applyLeaveError!);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B2A63), Color(0xFF1A4A9D)],
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
                    child: const Icon(
                      Icons.edit_calendar_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply Leave',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Create a new leave request',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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
                children: [
                  if (_appController.leaveTypesLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  DropdownButtonFormField<LeaveTypeItem>(
                    initialValue: _selectedLeaveType,
                    items: _appController.leaveTypes
                        .map(
                          (type) => DropdownMenuItem<LeaveTypeItem>(
                            value: type,
                            child: Text(type.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedLeaveType = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Leave Type',
                      hintText: 'Select leave type',
                    ),
                  ),
                  if (_appController.leaveTypesError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _appController.leaveTypesError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _startDateController,
                    readOnly: true,
                    onTap: () => _pickDate(isStartDate: true),
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      hintText: 'YYYY-MM-DD',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _endDateController,
                    readOnly: true,
                    onTap: () => _pickDate(isStartDate: false),
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      hintText: 'YYYY-MM-DD',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  if (_dateValidationError != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _dateValidationError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      hintText: 'Briefly describe the reason for leave.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _attachmentPath == null
                              ? 'No attachment selected'
                              : _attachmentPath!.split(RegExp(r'[\\/]')).last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _pickAttachment,
                        child: const Text('Choose File'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.navy, Color(0xFF184695)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: FilledButton(
                      onPressed: _appController.applyLeaveLoading
                          ? null
                          : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _appController.applyLeaveLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit Request'),
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
