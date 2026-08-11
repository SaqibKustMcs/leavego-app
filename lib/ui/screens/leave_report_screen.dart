import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/leave_report_response.dart';
import 'package:leavego_app/ui/screens/leave_detail_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

const _statusOptions = <String>[
  'approved',
  'pending',
  'rejected',
  // 'pending_hod',
  'pending_hr',
  'pending_ceo',
];

class LeaveReportFilters {
  const LeaveReportFilters({
    this.employeeId,
    this.departmentId,
    this.leaveTypeId,
    this.status,
    this.from = '',
    this.to = '',
  });

  final String? employeeId;
  final String? departmentId;
  final String? leaveTypeId;
  final String? status;
  final String from;
  final String to;

  LeaveReportFilters copyWith({
    Object? employeeId = _unset,
    Object? departmentId = _unset,
    Object? leaveTypeId = _unset,
    Object? status = _unset,
    String? from,
    String? to,
  }) {
    return LeaveReportFilters(
      employeeId: employeeId == _unset ? this.employeeId : employeeId as String?,
      departmentId: departmentId == _unset ? this.departmentId : departmentId as String?,
      leaveTypeId: leaveTypeId == _unset ? this.leaveTypeId : leaveTypeId as String?,
      status: status == _unset ? this.status : status as String?,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }

  static const Object _unset = Object();
}

class LeaveReportScreen extends StatefulWidget {
  const LeaveReportScreen({super.key});

  @override
  State<LeaveReportScreen> createState() => _LeaveReportScreenState();
}

class _LeaveReportScreenState extends State<LeaveReportScreen> {
  late final AppController _appController;
  final _scrollController = ScrollController();
  late LeaveReportFilters _filters;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _scrollController.addListener(_onScroll);

    // Default view is unfiltered: /leaves/report?page=1&per_page=20
    _filters = const LeaveReportFilters();

    _appController.loadEmployees(refresh: true);
    _appController.loadDepartments();
    _appController.loadLeaveTypes();
    _loadReport();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 320) return;
    if (!_appController.leaveReportHasMore) return;
    if (_appController.leaveReportLoading || _appController.leaveReportLoadingMore) return;
    _appController.loadMoreLeaveReport();
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  String _toYmd(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadReport() {
    return _appController.loadLeaveReport(
      refresh: true,
      employeeId: _filters.employeeId,
      departmentId: _filters.departmentId,
      leaveTypeId: _filters.leaveTypeId,
      status: _filters.status,
      from: _filters.from,
      to: _filters.to,
    );
  }

  Future<void> _onRefresh() async {
    await Future.wait<void>([
      _loadReport(),
      _appController.loadEmployees(refresh: true),
      _appController.loadDepartments(),
      _appController.loadLeaveTypes(),
    ]);
  }

  Future<void> _openFilters() async {
    final updated = await showModalBottomSheet<LeaveReportFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LeaveReportFiltersSheet(initialFilters: _filters),
    );
    if (updated == null || !mounted) return;
    setState(() => _filters = updated);
    await _loadReport();
  }

  Future<void> _clearFilter(LeaveReportFilters next) async {
    setState(() => _filters = next);
    await _loadReport();
  }

  String _employeeName(String id) {
    for (final employee in _appController.employees) {
      if (employee.id.toString() == id) return employee.name;
    }
    return 'Employee #$id';
  }

  String _departmentName(String id) {
    for (final department in _appController.departments) {
      if (department.id.toString() == id) return department.name;
    }
    return 'Department #$id';
  }

  String _leaveTypeName(String id) {
    for (final type in _appController.leaveTypes) {
      if (type.id == id) return type.name;
    }
    return 'Leave type #$id';
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      const months = <String>[
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
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return raw;
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

  List<Widget> _buildFilterChips() {
    final chips = <Widget>[];

    if (_filters.from.isNotEmpty || _filters.to.isNotEmpty) {
      chips.add(
        _FilterChip(
          label: '${_formatDate(_filters.from)} - ${_formatDate(_filters.to)}',
          icon: Icons.date_range_rounded,
        ),
      );
    }
    if (_filters.employeeId != null) {
      chips.add(
        _FilterChip(
          label: _employeeName(_filters.employeeId!),
          icon: Icons.person_outline_rounded,
          onClear: () => _clearFilter(_filters.copyWith(employeeId: null)),
        ),
      );
    }
    if (_filters.departmentId != null) {
      chips.add(
        _FilterChip(
          label: _departmentName(_filters.departmentId!),
          icon: Icons.apartment_rounded,
          onClear: () => _clearFilter(_filters.copyWith(departmentId: null)),
        ),
      );
    }
    if (_filters.leaveTypeId != null) {
      chips.add(
        _FilterChip(
          label: _leaveTypeName(_filters.leaveTypeId!),
          icon: Icons.category_outlined,
          onClear: () => _clearFilter(_filters.copyWith(leaveTypeId: null)),
        ),
      );
    }
    if (_filters.status != null) {
      chips.add(
        _FilterChip(
          label: _toLabel(_filters.status!),
          icon: Icons.flag_outlined,
          onClear: () => _clearFilter(_filters.copyWith(status: null)),
        ),
      );
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _appController.leaveReportItems;
    final total = _appController.leaveReportTotal;
    final isLoading = _appController.leaveReportLoading;
    final error = _appController.leaveReportError;
    final chips = _buildFilterChips();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      appBar: AppBar(
        title: const Text('Leave Report'),
        leading: const AppBackButton(),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: _openFilters,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              // Row(
              //   children: [
              //     Expanded(
              //       child: Text(
              //         'Results${total > 0 ? ' ($total)' : ''}',
              //         style: theme.textTheme.titleMedium?.copyWith(
              //           fontWeight: FontWeight.w700,
              //           color: Colors.black,
              //         ),
              //       ),
              //     ),
              //     TextButton.icon(
              //       onPressed: _openFilters,
              //       style: TextButton.styleFrom(foregroundColor: AppTheme.navy),
              //       icon: const Icon(Icons.filter_list_rounded, size: 18),
              //       label: const Text('Filters', style: TextStyle(fontWeight: FontWeight.w700)),
              //     ),
              //   ],
              // ),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(spacing: 8, runSpacing: 8, children: chips),
              ],
              const SizedBox(height: 12),
              if (isLoading && items.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: AppLoader())
              else if (error != null && items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                )
              else if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('No leave records found for the selected filters.'),
                )
              else
                ...items.map(
                  (item) => _LeaveReportCard(
                    item: item,
                    formatDate: _formatDate,
                    toLabel: _toLabel,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              LeaveDetailScreen(leaveId: item.id.toString(), enableActions: false),
                        ),
                      );
                    },
                  ),
                ),
              if (_appController.leaveReportLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: AppLoader(size: 26),
                )
              else if (_appController.leaveReportHasMore && items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: OutlinedButton(
                    onPressed: _appController.loadMoreLeaveReport,
                    child: const Text('Load more'),
                  ),
                )
              else if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Center(
                    child: Text(
                      'Showing all ${items.length} record(s)',
                      style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.icon, this.onClear});

  final String label;
  final IconData icon;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(10, 6, onClear == null ? 12 : 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3EAF8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.navy),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 2),
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: Icon(Icons.close_rounded, size: 14, color: Color(0xFF6A778B)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaveReportFiltersSheet extends StatefulWidget {
  const _LeaveReportFiltersSheet({required this.initialFilters});

  final LeaveReportFilters initialFilters;

  @override
  State<_LeaveReportFiltersSheet> createState() => _LeaveReportFiltersSheetState();
}

class _LeaveReportFiltersSheetState extends State<_LeaveReportFiltersSheet> {
  late final AppController _appController;
  late String? _employeeId;
  late String? _departmentId;
  late String? _leaveTypeId;
  late String? _status;
  late final TextEditingController _fromController;
  late final TextEditingController _toController;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);

    _employeeId = widget.initialFilters.employeeId;
    _departmentId = widget.initialFilters.departmentId;
    _leaveTypeId = widget.initialFilters.leaveTypeId;
    _status = widget.initialFilters.status;
    _fromController = TextEditingController(text: widget.initialFilters.from);
    _toController = TextEditingController(text: widget.initialFilters.to);

    if (_appController.employees.isEmpty) _appController.loadEmployees(refresh: true);
    if (_appController.departments.isEmpty) _appController.loadDepartments();
    if (_appController.leaveTypes.isEmpty) _appController.loadLeaveTypes();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  String _toYmd(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate({required TextEditingController controller}) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(controller.text.trim()) ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (selected == null) return;
    setState(() => controller.text = _toYmd(selected));
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

  void _resetFilters() {
    final now = DateTime.now();
    setState(() {
      _employeeId = null;
      _departmentId = null;
      _leaveTypeId = null;
      _status = null;
      _fromController.text = _toYmd(DateTime(now.year, now.month, 1));
      _toController.text = _toYmd(DateTime(now.year, now.month + 1, 0));
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      LeaveReportFilters(
        employeeId: _employeeId,
        departmentId: _departmentId,
        leaveTypeId: _leaveTypeId,
        status: _status,
        from: _fromController.text.trim(),
        to: _toController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return Container(
      height: media.size.height * 0.82,
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
                  child: Text(
                    'Report Filters',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.navy,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                DropdownButtonFormField<String?>(
                  key: ValueKey<String?>('employee-$_employeeId'),
                  initialValue: _employeeId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Employee'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All employees')),
                    ..._appController.employees.map(
                      (employee) => DropdownMenuItem<String?>(
                        value: employee.id.toString(),
                        child: Text(employee.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _employeeId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  key: ValueKey<String?>('department-$_departmentId'),
                  initialValue: _departmentId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All departments')),
                    ..._appController.departments.map(
                      (department) => DropdownMenuItem<String?>(
                        value: department.id.toString(),
                        child: Text(department.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _departmentId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  key: ValueKey<String?>('leave-type-$_leaveTypeId'),
                  initialValue: _leaveTypeId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Leave type'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All leave types')),
                    ..._appController.leaveTypes.map(
                      (type) => DropdownMenuItem<String?>(
                        value: type.id,
                        child: Text(type.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _leaveTypeId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All statuses')),
                    ..._statusOptions.map(
                      (status) =>
                          DropdownMenuItem<String?>(value: status, child: Text(_toLabel(status))),
                    ),
                  ],
                  onChanged: (value) => setState(() => _status = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fromController,
                  readOnly: true,
                  onTap: () => _pickDate(controller: _fromController),
                  decoration: const InputDecoration(
                    labelText: 'From',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _toController,
                  readOnly: true,
                  onTap: () => _pickDate(controller: _toController),
                  decoration: const InputDecoration(
                    labelText: 'To',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + media.padding.bottom),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.navy, AppTheme.lightNavy]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveReportCard extends StatelessWidget {
  const _LeaveReportCard({
    required this.item,
    required this.formatDate,
    required this.toLabel,
    required this.onTap,
  });

  final LeaveReportItem item;
  final String Function(String) formatDate;
  final String Function(String) toLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leaveLabel = item.leaveTypeCode.isEmpty
        ? item.leaveTypeName
        : '${item.leaveTypeName} (${item.leaveTypeCode})';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        onTap: onTap,
        title: Text(item.employeeName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(leaveLabel, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '${formatDate(item.startDate)} - ${formatDate(item.endDate)} • ${item.days} day(s)',
              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.departmentName} • ${toLabel(item.finalStatus.isNotEmpty ? item.finalStatus : item.status)}',
              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6A778B)),
      ),
    );
  }
}
