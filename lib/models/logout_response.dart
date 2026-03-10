class LogoutResponse {
  const LogoutResponse({required this.success, required this.message});

  final bool success;
  final String message;

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }
}
