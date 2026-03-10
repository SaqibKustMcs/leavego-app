import 'package:leavego_app/models/my_leaves_response.dart';

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.status,
    required this.reason,
  });

  final String id;
  final String employeeName;
  final String leaveType;
  final String startDate;
  final String endDate;
  final int days;
  final String status;
  final String reason;

  factory LeaveRequest.fromMyLeaveItem(MyLeaveItem item) {
    final normalizedStatus = item.finalStatus.isNotEmpty
        ? item.finalStatus
        : item.status;
    return LeaveRequest(
      id: item.id,
      employeeName: 'Employee',
      leaveType: 'Leave Type #${item.leaveTypeId}',
      startDate: item.startDate,
      endDate: item.endDate,
      days: item.days,
      status: normalizedStatus,
      reason: item.reason,
    );
  }
}

const List<LeaveRequest> sampleLeaves = [
  LeaveRequest(
    id: 'LP-1001',
    employeeName: 'Ahmed Khan',
    leaveType: 'Annual Leave',
    startDate: '12 Mar 2026',
    endDate: '15 Mar 2026',
    days: 4,
    status: 'Pending',
    reason: 'Family event in Lahore',
  ),
  LeaveRequest(
    id: 'LP-1002',
    employeeName: 'Ayesha Malik',
    leaveType: 'Sick Leave',
    startDate: '02 Mar 2026',
    endDate: '03 Mar 2026',
    days: 2,
    status: 'Approved',
    reason: 'Medical rest recommended by doctor',
  ),
  LeaveRequest(
    id: 'LP-1003',
    employeeName: 'Bilal Qureshi',
    leaveType: 'Casual Leave',
    startDate: '20 Mar 2026',
    endDate: '20 Mar 2026',
    days: 1,
    status: 'Rejected',
    reason: 'Urgent personal work',
  ),
];
