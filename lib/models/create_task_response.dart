class CreateTaskResponse {
  const CreateTaskResponse({
    required this.success,
    required this.message,
    required this.taskId,
  });

  final bool success;
  final String message;
  final String? taskId;

  factory CreateTaskResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    String? id;
    if (data is Map<String, dynamic>) {
      id = data['id']?.toString();
    }
    return CreateTaskResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      taskId: id,
    );
  }
}

