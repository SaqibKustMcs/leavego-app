class ApplyLeaveResponse {
  const ApplyLeaveResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final Map<String, dynamic> data;

  factory ApplyLeaveResponse.fromJson(Map<String, dynamic> json) {
    return ApplyLeaveResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }
}
