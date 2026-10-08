import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/dashboard_response.dart';
import 'package:leavego_app/models/my_leaves_response.dart';
import 'package:leavego_app/ui/models/leave_request.dart';
import 'package:leavego_app/ui/screens/apply_leave_screen.dart';
import 'package:leavego_app/ui/screens/leave_detail_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/utils/app_roles.dart';

enum _LeaveListMode { pending, myLeaves }

class MyLeaveRequestsScreen extends StatefulWidget {
  const MyLeaveRequestsScreen({super.key});

  @override
  State<MyLeaveRequestsScreen> createState() => _MyLeaveRequestsScreenState();
}

class _MyLeaveRequestsScreenState extends State<MyLeaveRequestsScreen> {
  static const Color _primary = Color(0xFF173559);
  static const String _calendarIcon = 'assets/images/calendar-range.png';
  static const String _balanceIcon = 'assets/images/calendar-week.webp';
  static const String _recentIcon = 'assets/images/dates.webp';

  static const _balanceDotColors = <Color>[
    Color(0xFF2E7D32),
    Color(0xFF2B68B1),
    Color(0xFF7B1FA2),
    Color(0xFFE65100),
    Color(0xFF00838F),
    Color(0xFF6A1B9A),
  ];

  late final AppController _appController;
  bool _bootstrapped = false;
  int _selectedYear = DateTime.now().year;
  _LeaveListMode _listMode = _LeaveListMode.pending;
  List<MyLeaveItem> _ownLeaves = <MyLeaveItem>[];

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    if (_appController.meData == null) _appController.loadMe();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    await _onRefresh();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _appController.loadDashboard(),
      _appController.loadLeaveTypes(),
      _appController.loadMyLeaves(),
    ]);
    _ownLeaves = List<MyLeaveItem>.from(_appController.myLeaves);
    _syncListModeForRole();
    if (_showApprovalQueue) {
      await _appController.loadRequestsByRole();
    }
    if (mounted) setState(() {});
  }

  Future<void> _onListModeChanged(_LeaveListMode value) async {
    setState(() => _listMode = value);
    if (value == _LeaveListMode.pending) {
      await _appController.loadRequestsByRole();
    } else {
      await _appController.loadMyLeaves();
      _ownLeaves = List<MyLeaveItem>.from(_appController.myLeaves);
    }
    if (mounted) setState(() {});
  }

  void _onUpdate() {
    if (_appController.meData != null && !_bootstrapped) {
      _bootstrap();
    }
    _syncListModeForRole();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  String get _role => AppRoles.normalize(_appController.meData?.role);

  bool get _isCeoOrHr => AppRoles.isCeoOrHrLike(_role);

  bool get _isHod => _role == 'hod';

  /// CEO / HR / OPM / HOD: Pending + My Leaves; everyone else: My Leaves only.
  List<_LeaveListMode> get _listModeOptions {
    if (_isCeoOrHr || _isHod) {
      return const [_LeaveListMode.pending, _LeaveListMode.myLeaves];
    }
    return const [_LeaveListMode.myLeaves];
  }

  void _syncListModeForRole() {
    final options = _listModeOptions;
    if (!options.contains(_listMode)) {
      _listMode = options.first;
    }
  }

  bool get _showApprovalQueue {
    if (_isHod) return true;
    if (_isCeoOrHr) return _listMode == _LeaveListMode.pending;
    return false;
  }

  bool get _canApproveFromList => _isHod || (_isCeoOrHr && _listMode == _LeaveListMode.pending);

  List<MyLeaveItem> get _listSource => _showApprovalQueue ? _appController.myLeaves : _ownLeaves;

  List<MyLeaveItem> get _filteredLeaves {
    return _listSource.where(_inSelectedYear).toList();
  }

  MyLeaveItem? get _recentApprovedLeave {
    final approved = _ownLeaves.where((item) => _normalizedStatus(item) == 'approved').toList();
    approved.sort((a, b) {
      final ad = _parseDate(a.startDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = _parseDate(b.startDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    if (approved.isEmpty) return null;
    final recent = approved.first;
    if (!_inSelectedYear(recent)) return null;
    return recent;
  }

  bool _inSelectedYear(MyLeaveItem item) {
    final date = _parseDate(item.startDate);
    return date?.year == _selectedYear;
  }

  String _normalizedStatus(MyLeaveItem item) {
    final raw = item.finalStatus.trim().isNotEmpty ? item.finalStatus : item.status;
    return raw.trim().toLowerCase().replaceAll('_', ' ');
  }

  String _displayStatus(MyLeaveItem item) {
    final raw = item.finalStatus.trim().isNotEmpty ? item.finalStatus : item.status;
    if (raw.trim().isEmpty) return 'Pending';
    return raw
        .trim()
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (part) =>
              part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  DateTime? _parseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw.contains(' ') ? raw.split(' ').first : raw);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(String raw) {
    final date = _parseDate(raw);
    if (date == null) return raw;
    return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';
  }

  String _formatCompactRange(String startRaw, String endRaw) {
    final start = _parseDate(startRaw);
    final end = _parseDate(endRaw);
    if (start == null || end == null) {
      return '${_formatDate(startRaw)} - ${_formatDate(endRaw)}';
    }
    if (start.year == end.year && start.month == end.month) {
      return '${start.day.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')} ${_monthName(start.month)}';
    }
    return '${_formatDate(startRaw)} - ${_formatDate(endRaw)}';
  }

  String _monthName(int month) {
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
    return months[month - 1];
  }

  String _leaveTypeName(String leaveTypeId, {required String fallback}) {
    for (final type in _appController.leaveTypes) {
      if (type.id == leaveTypeId) {
        return type.name.isEmpty ? fallback : type.name;
      }
    }
    return fallback;
  }

  Future<void> _pickYear() async {
    final now = DateTime.now().year;
    final years = List<int>.generate(6, (i) => now - 2 + i);
    final picked = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select year'),
          children: years
              .map(
                (year) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, year),
                  child: Text('$year'),
                ),
              )
              .toList(),
        );
      },
    );
    if (picked == null || picked == _selectedYear) return;
    setState(() => _selectedYear = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balances = _appController.dashboardData?.leaveBalances ?? <DashboardLeaveBalanceItem>[];
    final recentApproved = _recentApprovedLeave;
    final filtered = _filteredLeaves;
    final emptyMessage = _showApprovalQueue
        ? 'No pending approvals found.'
        : 'No leave requests found.';

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              Row(
                children: [
                  if (Navigator.of(context).canPop())
                    const AppBackButton(color: _primary)
                  else
                    const SizedBox(width: 0),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Leave',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _pickYear,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F1FE),
                        borderRadius: BorderRadius.circular(4),
                        // border: Border.all(color: const Color(0xFFB8D4F0), width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(_calendarIcon, width: 20, height: 20, fit: BoxFit.contain),
                          const SizedBox(width: 8),
                          Text(
                            '$_selectedYear',
                            style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: _primary, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (balances.isNotEmpty) ...[
                _LeaveBalanceCard(
                  balances: balances,
                  dotColors: _balanceDotColors,
                  icon: _balanceIcon,
                ),
                const SizedBox(height: 14),
              ],
              if (recentApproved != null) ...[
                _RecentApprovedCard(
                  leaveTypeName: _leaveTypeName(recentApproved.leaveTypeId, fallback: 'Leave'),
                  dateRange: _formatCompactRange(recentApproved.startDate, recentApproved.endDate),
                  daysLabel:
                      '(${recentApproved.days} ${recentApproved.days == 1 ? 'day' : 'days'})',
                  status: _displayStatus(recentApproved),
                  iconAsset: _recentIcon,
                  onTap: () => _openDetail(recentApproved),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LeaveListModeDropdown(
                    value: _listMode,
                    options: _listModeOptions,
                    onChanged: (value) {
                      if (value != null) _onListModeChanged(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_appController.myLeavesLoading && filtered.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: AppLoader())
              else if (_appController.myLeavesError != null && filtered.isEmpty)
                _MessageCard(message: _appController.myLeavesError!, isError: true)
              else if (filtered.isEmpty)
                _MessageCard(message: emptyMessage)
              else
                ...filtered.map((item) {
                  final leave = LeaveRequest.fromMyLeaveItem(item);
                  final leaveTypeName = _leaveTypeName(item.leaveTypeId, fallback: leave.leaveType);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _LeaveRequestCard(
                      leaveTypeName: leaveTypeName,
                      dateRange: '${_formatDate(item.startDate)} - ${_formatDate(item.endDate)}',
                      status: _displayStatus(item),
                      onTap: () => _openDetail(item),
                    ),
                  );
                }),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add, size: 22),
                  label: const Text(
                    'Apply Leave',
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

  void _openDetail(MyLeaveItem item) {
    final enableActions = _canApproveFromList;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeaveDetailScreen(leaveId: item.id, enableActions: enableActions),
      ),
    );
  }
}

class _LeaveBalanceCard extends StatelessWidget {
  const _LeaveBalanceCard({required this.balances, required this.dotColors, required this.icon});

  final List<DashboardLeaveBalanceItem> balances;
  final List<Color> dotColors;
  final String icon;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Color(0xffffffff),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF4F2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(icon, width: 22, height: 22, fit: BoxFit.contain),
              const SizedBox(width: 8),
              const Text(
                'Leave balance',
                style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var rowStart = 0; rowStart < balances.length; rowStart += 2) ...[
            if (rowStart > 0) const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var col = 0; col < 2; col++) ...[
                  if (col > 0) const SizedBox(width: 12),
                  Expanded(
                    child: rowStart + col < balances.length
                        ? _BalanceColumn(
                            dotColor: dotColors[(rowStart + col) % dotColors.length],
                            item: balances[rowStart + col],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceColumn extends StatelessWidget {
  const _BalanceColumn({required this.dotColor, required this.item});

  final Color dotColor;
  final DashboardLeaveBalanceItem item;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    final remaining = item.remaining;
    final total = item.assigned;
    final showTotal = total > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.leaveTypeName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BalanceMetric(label: 'Remaining', value: remaining),
              if (showTotal) _BalanceMetric(label: 'Total', value: total),
              // const SizedBox(height: 4),
              // Text(
              //   showTotal ? 'days per year' : 'days remaining',
              //   style: const TextStyle(
              //     color: Color(0xFF6A778B),
              //     fontWeight: FontWeight.w500,
              //     fontSize: 11,
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({required this.label, required this.value});

  final String label;
  final int value;

  String get _displayValue => value < 10 ? value.toString().padLeft(2, '0') : '$value';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Text(
            _displayValue,
            style: const TextStyle(
              color: Color(0xFF173559),
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF999999),
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _RecentApprovedCard extends StatelessWidget {
  const _RecentApprovedCard({
    required this.leaveTypeName,
    required this.dateRange,
    required this.daysLabel,
    required this.status,
    required this.iconAsset,
    required this.onTap,
  });

  final String leaveTypeName;
  final String dateRange;
  final String daysLabel;
  final String status;
  final String iconAsset;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEF4F2), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    "assets/images/calendar-import.webp",
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      leaveTypeName,
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateRange,
                            style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            daysLabel,
                            style: const TextStyle(
                              color: Color(0xFF999999),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 30, child: _StatusBadge(status: status)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveListModeDropdown extends StatelessWidget {
  const _LeaveListModeDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final _LeaveListMode value;
  final List<_LeaveListMode> options;
  final ValueChanged<_LeaveListMode?> onChanged;

  static const Color _primary = Color(0xFF173559);

  String _label(_LeaveListMode mode) {
    switch (mode) {
      case _LeaveListMode.pending:
        return 'Pending';
      case _LeaveListMode.myLeaves:
        return 'My Leaves';
    }
  }

  @override
  Widget build(BuildContext context) {
    final multipleOptions = options.length > 1;

    return Container(
      height: 48,
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_LeaveListMode>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: multipleOptions
              ? const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white)
              : const SizedBox.shrink(),
          iconSize: multipleOptions ? 24 : 0,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 12),
          selectedItemBuilder: (context) {
            return options
                .map(
                  (_) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _label(value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
                .toList();
          },
          items: options
              .map(
                (mode) => DropdownMenuItem<_LeaveListMode>(
                  value: mode,
                  child: Text(
                    _label(mode),
                    style: const TextStyle(color: _primary, fontWeight: FontWeight.w600),
                  ),
                ),
              )
              .toList(),
          onChanged: options.length <= 1 ? null : onChanged,
        ),
      ),
    );
  }
}

class _LeaveRequestCard extends StatelessWidget {
  const _LeaveRequestCard({
    required this.leaveTypeName,
    required this.dateRange,
    required this.status,
    required this.onTap,
  });

  final String leaveTypeName;
  final String dateRange;
  final String status;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(12),

      child: Container(
        // margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Color(0xffFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 8,
                    // margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8E9FF),
                      // borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  leaveTypeName,
                                  style: const TextStyle(
                                    color: _primary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  dateRange,
                                  style: const TextStyle(
                                    color: Color(0xFF4C4C4C),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(height: 30, child: _StatusBadge(status: status)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError
            ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.45)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF4F2), width: 0.5),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? Theme.of(context).colorScheme.error : const Color(0xFF6A778B),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color fg = AppTheme.navy;
    Color bg = const Color(0xFFDCE7FF);
    final lower = status.toLowerCase();

    if (lower == 'approved') {
      fg = const Color(0xFF40705F);
      bg = const Color(0xFFD9FCF0);
    } else if (lower == 'rejected') {
      fg = const Color(0xFF8B1D18);
      bg = const Color(0xFFFCE3E1);
    } else if (lower.contains('pending')) {
      fg = const Color(0xFF173559);
      bg = const Color(0xFFE4F1FE);
    }

    return Container(
      height: 30,

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(56)),
      child: Center(
        child: Text(
          status,
          style: TextStyle(color: fg, fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ),
    );
  }
}
