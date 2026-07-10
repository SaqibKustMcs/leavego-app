import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/leave_type_response.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  late final AppController _appController;
  String? _selectedLeaveTypeId;
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _attachmentPath;
  final leaveTypeError = ''.obs;
  final startDateError = ''.obs;
  final endDateError = ''.obs;
  final reasonError = ''.obs;
  final attachmentError = ''.obs;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadLeaveTypes();
  }

  void _onUpdate() {
    if (!mounted) return;
    if (_selectedLeaveTypeId != null &&
        _appController.leaveTypes.where((type) => type.id == _selectedLeaveTypeId).isEmpty) {
      _selectedLeaveTypeId = null;
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
      endDateError.value = '';
      return true;
    }

    if (end.isBefore(start)) {
      const msg = 'End date must be same as or after start date';
      endDateError.value = msg;
      if (showMessage) _showSnack(msg);
      return false;
    }

    endDateError.value = '';
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

    final safeInitial = initial.isBefore(firstAllowedDate) ? firstAllowedDate : initial;

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
    if (attachmentError.value.isNotEmpty) {
      attachmentError.value = '';
    }
  }

  LeaveTypeItem? get _selectedLeaveType {
    final id = _selectedLeaveTypeId;
    if (id == null || id.isEmpty) return null;
    for (final type in _appController.leaveTypes) {
      if (type.id == id) return type;
    }
    return null;
  }

  Future<void> _submit() async {
    leaveTypeError.value = '';
    startDateError.value = '';
    endDateError.value = '';
    reasonError.value = '';
    attachmentError.value = '';

    var isValid = true;
    if (_selectedLeaveTypeId == null || _selectedLeaveTypeId!.isEmpty) {
      leaveTypeError.value = 'Please select leave type';
      isValid = false;
    }
    if (_startDateController.text.trim().isEmpty) {
      startDateError.value = 'Please select start date';
      isValid = false;
    }
    if (_endDateController.text.trim().isEmpty) {
      endDateError.value = 'Please select end date';
      isValid = false;
    }
    if (_reasonController.text.trim().isEmpty) {
      reasonError.value = 'Please enter reason';
      isValid = false;
    }
    final selectedType = _selectedLeaveType;
    if (selectedType != null &&
        selectedType.requiresAttachment &&
        (_attachmentPath == null || _attachmentPath!.trim().isEmpty)) {
      attachmentError.value = 'Attachment is required for ${selectedType.name}';
      isValid = false;
    }
    if (!isValid) return;
    if (!_validateDateRange()) return;

    final response = await _appController.applyLeave(
      leaveTypeId: _selectedLeaveTypeId!,
      startDate: _startDateController.text.trim(),
      endDate: _endDateController.text.trim(),
      reason: _reasonController.text.trim(),
      attachmentPath: _attachmentPath,
    );
    if (!mounted) return;
    if (response != null) {
      _showSnack(response.message.isNotEmpty ? response.message : 'Leave request submitted');
      await _appController.loadMyLeaves();
      if (!mounted) return;
      Navigator.of(context).pop();
    } else if (_appController.applyLeaveError != null) {
      _showSnack(_appController.applyLeaveError!);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
                  colors: [AppTheme.navy, AppTheme.lightNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_calendar_rounded, color: Colors.white),
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
                      child: AppLoader(size: 24),
                    ),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: _selectedLeaveTypeId,
                      items: _appController.leaveTypes
                          .map(
                            (type) =>
                                DropdownMenuItem<String>(value: type.id, child: Text(type.name)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedLeaveTypeId = value);
                        leaveTypeError.value = '';
                        attachmentError.value = '';
                      },
                      decoration: InputDecoration(
                        labelText: 'Leave Type',
                        hintText: 'Select leave type',
                        errorText: leaveTypeError.value.isEmpty ? null : leaveTypeError.value,
                      ),
                    ),
                  ),
                  if (_appController.leaveTypesError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _appController.leaveTypesError!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Obx(
                    () => TextField(
                      controller: _startDateController,
                      readOnly: true,
                      onTap: () {
                        startDateError.value = '';
                        _pickDate(isStartDate: true);
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
                      controller: _endDateController,
                      readOnly: true,
                      onTap: () {
                        endDateError.value = '';
                        _pickDate(isStartDate: false);
                      },
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        hintText: 'YYYY-MM-DD',
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                        errorText: endDateError.value.isEmpty ? null : endDateError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => TextField(
                      controller: _reasonController,
                      maxLines: 4,
                      onChanged: (_) {
                        if (reasonError.value.isNotEmpty) {
                          reasonError.value = '';
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        hintText: 'Briefly describe the reason for leave.',
                        errorText: reasonError.value.isEmpty ? null : reasonError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    final selectedType = _selectedLeaveType;
                    final isRequired = selectedType?.requiresAttachment == true;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRequired ? 'Attachment (required)' : 'Attachment (optional)',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: 6),
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
                        if (attachmentError.value.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            attachmentError.value,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.navy, AppTheme.lightNavy]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: FilledButton(
                      onPressed: _appController.applyLeaveLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _appController.applyLeaveLoading
                          ? const AppButtonLoader(size: 22)
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
