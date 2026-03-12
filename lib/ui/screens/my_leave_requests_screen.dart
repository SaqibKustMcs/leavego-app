import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/ui/models/leave_request.dart';
import 'package:leavego_app/ui/screens/apply_leave_screen.dart';
import 'package:leavego_app/ui/screens/leave_detail_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';

class MyLeaveRequestsScreen extends StatefulWidget {
  const MyLeaveRequestsScreen({super.key});

  @override
  State<MyLeaveRequestsScreen> createState() => _MyLeaveRequestsScreenState();
}

class _MyLeaveRequestsScreenState extends State<MyLeaveRequestsScreen> {
  late final AppController _appController;

  Future<void> _onRefresh() async {
    await _appController.loadMyLeaves();
  }

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadMyLeaves();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            Row(
              children: [
                Text(
                  'My Leave Requests',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF102446),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _appController.myLeavesLoading
                      ? null
                      : _appController.loadMyLeaves,
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_appController.myLeavesLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_appController.myLeavesError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _appController.myLeavesError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              )
            else if (_appController.myLeaves.isEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('No leave requests found.'),
              )
            else
              ..._appController.myLeaves.map((item) {
                final leave = LeaveRequest.fromMyLeaveItem(item);
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    title: Text(
                      leave.leaveType,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                    ),
                    trailing: _StatusBadge(status: leave.status),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LeaveDetailScreen(leaveId: item.id),
                        ),
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.navy, Color(0xFF19489A)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Apply Leave'),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return raw;
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
      final month = months[date.month - 1];
      return '${date.day.toString().padLeft(2, '0')} $month ${date.year}';
    } catch (_) {
      return raw;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color fg = AppTheme.navy;
    Color bg = const Color(0xFFDCE7FF);

    if (status == 'Approved') {
      fg = const Color(0xFF1B5E20);
      bg = const Color(0xFFDFF5E2);
    } else if (status == 'Rejected') {
      fg = const Color(0xFF8B1D18);
      bg = const Color(0xFFFCE3E1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
