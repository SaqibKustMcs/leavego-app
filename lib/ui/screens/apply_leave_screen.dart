import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/leave_type_response.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/ui/widgets/attachment_row.dart';
import 'package:leavego_app/utils/app_roles.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  static const String _calendarIcon = 'assets/images/calendar-range.png';

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
    final today = _formatDisplayDate(DateTime.now());
    _startDateController.text = today;
    _endDateController.text = today;
  }

  static const _monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDisplayDate(DateTime date) {
    final month = _monthNames[date.month - 1];
    return '${date.day.toString().padLeft(2, '0')} $month ${date.year}';
  }

  String _formatYmd(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime? _tryParseFieldDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final monthIndex = _monthNames.indexWhere((m) => m.toLowerCase() == parts[1].toLowerCase());
      final year = int.tryParse(parts[2]);
      if (day != null && monthIndex >= 0 && year != null) {
        return DateTime(year, monthIndex + 1, day);
      }
    }

    try {
      return DateTime.parse(trimmed);
    } catch (_) {
      return null;
    }
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

  bool _validateDateRange({bool showMessage = false}) {
    final start = _tryParseFieldDate(_startDateController.text.trim());
    final end = _tryParseFieldDate(_endDateController.text.trim());

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
    final selectedStart = _tryParseFieldDate(_startDateController.text);

    final firstAllowedDate = isStartDate
        ? todayDateOnly
        : (selectedStart != null && !selectedStart.isBefore(todayDateOnly)
              ? selectedStart
              : todayDateOnly);

    final existing = isStartDate
        ? _tryParseFieldDate(_startDateController.text)
        : _tryParseFieldDate(_endDateController.text);
    final defaultInitial = isStartDate
        ? todayDateOnly
        : (selectedStart != null && !selectedStart.isBefore(todayDateOnly)
              ? selectedStart
              : todayDateOnly);
    final initial = existing ?? defaultInitial;
    final safeInitial = initial.isBefore(firstAllowedDate) ? firstAllowedDate : initial;

    final selected = await showDatePicker(
      context: context,
      firstDate: firstAllowedDate,
      lastDate: DateTime(2100),
      initialDate: safeInitial,
    );
    if (selected == null) return;
    final formatted = _formatDisplayDate(selected);

    if (isStartDate) {
      _startDateController.text = formatted;
      final end = _tryParseFieldDate(_endDateController.text);
      if (end != null && end.isBefore(selected)) {
        _endDateController.clear();
      }
    } else {
      final start = _tryParseFieldDate(_startDateController.text);
      if (start != null && selected.isBefore(start)) {
        _showSnack('End date cannot be before start date');
        return;
      }
      _endDateController.text = formatted;
    }

    _validateDateRange();
  }

  Future<void> _pickAttachment({required FileType type}) async {
    final result = await FilePicker.platform.pickFiles(type: type, allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    setState(() => _attachmentPath = result.files.single.path);
    if (attachmentError.value.isNotEmpty) {
      attachmentError.value = '';
    }
  }

  String? get _attachmentDisplayName {
    final path = _attachmentPath;
    if (path == null || path.trim().isEmpty) return null;
    return path.split(RegExp(r'[\\/]')).last;
  }

  Widget _calendarSuffix({required VoidCallback onPressed}) {
    return IconButton(
      onPressed: onPressed,
      icon: Image.asset(_calendarIcon, width: 22, height: 22, fit: BoxFit.contain),
    );
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
    final skipAttachment = AppRoles.usesSimpleLeaveApply(_appController.meData?.role);
    if (!skipAttachment &&
        selectedType != null &&
        selectedType.requiresAttachment &&
        (_attachmentPath == null || _attachmentPath!.trim().isEmpty)) {
      attachmentError.value = 'Attachment is required for ${selectedType.name}';
      isValid = false;
    }
    if (!isValid) return;
    if (!_validateDateRange()) return;

    final startParsed = _tryParseFieldDate(_startDateController.text.trim());
    final endParsed = _tryParseFieldDate(_endDateController.text.trim());
    if (startParsed == null || endParsed == null) {
      if (startParsed == null) startDateError.value = 'Please select a valid start date';
      if (endParsed == null) endDateError.value = 'Please select a valid end date';
      return;
    }

    final response = await _appController.applyLeave(
      leaveTypeId: _selectedLeaveTypeId!,
      startDate: _formatYmd(startParsed),
      endDate: _formatYmd(endParsed),
      reason: _reasonController.text.trim(),
      attachmentPath: skipAttachment ? null : _attachmentPath,
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
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            Row(
              children: [
                const AppBackButton(),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply Leave',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Color(0xff000000),
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Column(
              children: [
                if (_appController.leaveTypesLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: AppLoader(size: 24),
                  ),
                Obx(
                  () => DropdownButtonFormField<String>(
                    icon: Icon(
                      Icons.keyboard_arrow_down_outlined,
                      size: 25,
                      color: Color(0xff173559),
                    ),
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
                      labelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff4C4C4C),
                      ),
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
                const SizedBox(height: 24),
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
                      hintText: 'DD Mon YYYY',
                      labelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff4C4C4C),
                      ),
                      suffixIcon: _calendarSuffix(
                        onPressed: () {
                          startDateError.value = '';
                          _pickDate(isStartDate: true);
                        },
                      ),
                      errorText: startDateError.value.isEmpty ? null : startDateError.value,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                      labelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff4C4C4C),
                      ),
                      hintText: 'DD Mon YYYY',
                      suffixIcon: _calendarSuffix(
                        onPressed: () {
                          endDateError.value = '';
                          _pickDate(isStartDate: false);
                        },
                      ),
                      errorText: endDateError.value.isEmpty ? null : endDateError.value,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                      labelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff4C4C4C),
                      ),
                      hintText: 'Briefly describe the reason for leave.',

                      errorText: reasonError.value.isEmpty ? null : reasonError.value,
                      // alignLabelWithHint: false,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintStyle: TextStyle(
                        color: Color(0xff999999),
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!AppRoles.usesSimpleLeaveApply(_appController.meData?.role))
                  Obx(() {
                    final selectedType = _selectedLeaveType;
                    final isRequired = selectedType?.requiresAttachment == true;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AttachmentRow(
                          attachmentName: _attachmentDisplayName,
                          onDocument: () => _pickAttachment(type: FileType.any),
                          onGallery: () => _pickAttachment(type: FileType.image),
                          onCamera: () => _pickAttachment(type: FileType.image),
                        ),
                        if (isRequired) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Required for ${selectedType?.name ?? 'this leave type'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6A778B),
                            ),
                          ),
                        ],
                        if (attachmentError.value.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            attachmentError.value,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    );
                  }),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xff173559), Color(0xff173559)]),
                    borderRadius: BorderRadius.circular(4),
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
                        : const Text(
                            'Submit Request',
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
