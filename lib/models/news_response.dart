class NewsResponse {
  const NewsResponse({required this.success, required this.data});

  final bool success;
  final NewsPageData data;

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    return NewsResponse(
      success: json['success'] == true,
      data: NewsPageData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}

class NewsPageData {
  const NewsPageData({
    required this.currentPage,
    required this.items,
    required this.lastPage,
    required this.total,
  });

  final int currentPage;
  final List<NewsItem> items;
  final int lastPage;
  final int total;

  factory NewsPageData.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = rawList is List
        ? rawList.whereType<Map<String, dynamic>>().map(NewsItem.fromJson).toList()
        : <NewsItem>[];

    return NewsPageData(
      currentPage: _toInt(json['current_page']),
      lastPage: _toInt(json['last_page']),
      total: _toInt(json['total']),
      items: items,
    );
  }
}

class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.content,
    required this.image,
    required this.targetAudience,
    required this.publishedAt,
    required this.createdAt,
    required this.postedByName,
    required this.postedByRole,
  });

  final String id;
  final String title;
  final String content;
  final String? image;
  final String targetAudience;
  final String? publishedAt;
  final String? createdAt;
  final String postedByName;
  final String postedByRole;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      image: json['image']?.toString(),
      targetAudience: (json['target_audience'] ?? '').toString(),
      publishedAt: json['published_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      postedByName: (json['posted_by_name'] ?? '').toString(),
      postedByRole: (json['posted_by_role'] ?? '').toString(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

