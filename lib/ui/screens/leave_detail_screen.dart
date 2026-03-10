import 'package:flutter/material.dart';
import 'package:leavego_app/ui/models/leave_request.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';

class LeaveDetailScreen extends StatelessWidget {
  const LeaveDetailScreen({super.key, required this.leave});

  final LeaveRequest leave;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      Icons.description_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leave Detail',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Request information',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _DetailCard(label: 'Request ID', value: leave.id),
            _DetailCard(label: 'Employee', value: leave.employeeName),
            _DetailCard(label: 'Leave Type', value: leave.leaveType),
            _DetailCard(
              label: 'Dates',
              value:
                  '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
            ),
            _DetailCard(label: 'Days', value: '${leave.days}'),
            _DetailCard(label: 'Status', value: leave.status),
            _DetailCard(label: 'Reason', value: leave.reason),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.navy),
            ),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
