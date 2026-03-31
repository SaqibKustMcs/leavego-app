class NewsActionResponse {
  const NewsActionResponse({
    required this.success,
    required this.message,
    required this.newsId,
  });

  final bool success;
  final String message;
  final String? newsId;

  factory NewsActionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    String? id;
    if (data is Map<String, dynamic>) {
      id = data['id']?.toString();
    }
    return NewsActionResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      newsId: id,
    );
  }
}

