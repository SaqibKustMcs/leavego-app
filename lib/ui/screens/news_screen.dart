import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/news_response.dart';
import 'package:leavego_app/ui/screens/edit_news_screen.dart';
import 'package:leavego_app/ui/screens/news_detail_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/utils/app_roles.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final AppController _appController;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadNews(refresh: true);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _appController.loadNews(refresh: true);
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    try {
      final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
      final date = DateTime.parse(normalized).toLocal();
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
      final hour12 = (date.hour % 12 == 0) ? 12 : (date.hour % 12);
      final minute = date.minute.toString().padLeft(2, '0');
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year} ';

      // return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year} • $hour12:$minute $ampm';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _confirmDelete(NewsItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete news?'),
          content: Text('This will remove “${item.title}”.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final response = await _appController.deleteNews(newsId: item.id);
    if (!mounted) return;
    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message.isNotEmpty ? response.message : 'News deleted')),
      );
      return;
    }
    final err = _appController.deleteNewsError ?? 'Failed to delete news';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _appController.newsItems;
    final loading = _appController.newsLoading;
    final error = _appController.newsError;
    final canEdit = AppRoles.canEditNews(_appController.meData?.role);
    final canDelete = AppRoles.canDeleteNews(_appController.meData?.role);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      appBar: AppBar(
        title: Text(
          'Company News',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: const AppBackButton(),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (loading && items.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: AppLoader())
              else if (error != null && items.isEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                )
              else if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('No news found.'),
                )
              else ...[
                if (loading)
                  const Padding(padding: EdgeInsets.only(bottom: 10), child: AppLoader(size: 22)),
                ...items.map(
                  (item) => _NewsCard(
                    item: item,
                    formatDate: _formatDate,
                    canEdit: canEdit,
                    canDelete: canDelete,
                    onEdit: () async {
                      final updated = await Navigator.of(
                        context,
                      ).push<bool>(MaterialPageRoute(builder: (_) => EditNewsScreen(news: item)));
                      if (updated == true) {
                        await _appController.loadNews(refresh: true);
                      }
                    },
                    onDelete: _appController.deleteNewsLoading ? null : () => _confirmDelete(item),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => NewsDetailScreen(news: item)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_appController.newsHasMore)
                  OutlinedButton(
                    onPressed: _appController.newsLoadingMore ? null : _appController.loadMoreNews,
                    child: _appController.newsLoadingMore
                        ? const AppButtonLoader(color: AppTheme.navy)
                        : const Text('Load more'),
                  ),
                if (_appController.newsError != null && items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _appController.newsError!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.item,
    required this.formatDate,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  final NewsItem item;
  final String Function(String?) formatDate;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onTap;

  String _audienceLabel(String raw) {
    final v = raw.trim();
    return v.isEmpty ? '-' : v.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = item.publishedAt ?? item.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title.isEmpty ? '-' : item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (canEdit || canDelete)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (canEdit)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: InkWell(
                                onTap: onEdit,
                                child: Icon(Icons.edit_outlined, color: AppTheme.navy),
                              ),
                            ),
                          if (canDelete)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: InkWell(
                                onTap: onDelete,
                                child: Icon(Icons.delete_outlined, color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.content.isEmpty ? '-' : item.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'By ${item.postedByName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6A778B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      formatDate(date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6A778B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
