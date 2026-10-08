import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/news_response.dart';
import 'package:leavego_app/ui/screens/create_news_screen.dart';
import 'package:leavego_app/ui/screens/news_detail_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/ui/widgets/app_scroll_collapse_fab.dart';
import 'package:leavego_app/utils/app_roles.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  static const Color _primary = Color(0xFF173559);

  late final AppController _appController;
  late final ScrollCollapseFabController _fabScrollController;

  @override
  void initState() {
    super.initState();
    _fabScrollController = ScrollCollapseFabController();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadNews(refresh: true);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fabScrollController.dispose();
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
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _openCreateNews() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreateNewsScreen()));
    if (created == true && mounted) {
      await _appController.loadNews(refresh: true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('News published')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _appController.newsItems;
    final loading = _appController.newsLoading;
    final error = _appController.newsError;
    final canCreateNews = AppRoles.canCreateNews(_appController.meData?.role);

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(color: _primary),
        title: Text(
          'Company News',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      floatingActionButton: canCreateNews
          ? ListenableBuilder(
              listenable: _fabScrollController,
              builder: (context, _) => AppScrollCollapseFab(
                label: 'Create News',
                collapsed: _fabScrollController.collapsed,
                onPressed: _openCreateNews,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: AppFabScrollListener(
        controller: _fabScrollController,
        child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                'News & Update',
                style: TextStyle(color: _primary, fontWeight: FontWeight.w500, fontSize: 18),
              ),
            ),
            if (loading && items.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: AppLoader())
            else if (error != null && items.isEmpty)
              Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              )
            else if (items.isEmpty)
              const Text(
                'No news found.',
                style: TextStyle(color: Color(0xFF747D7A), fontWeight: FontWeight.w500),
              )
            else ...[
              if (loading)
                const Padding(padding: EdgeInsets.only(bottom: 10), child: AppLoader(size: 22)),
              ...List.generate(items.length, (index) {
                final item = items[index];
                return _NewsCard(
                  item: item,
                  index: index,
                  formatDate: _formatDate,
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => NewsDetailScreen(news: item))),
                );
              }),
              if (_appController.newsHasMore) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _appController.newsLoadingMore ? null : _appController.loadMoreNews,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: _primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                    ),
                  ),
                  child: _appController.newsLoadingMore
                      ? const AppButtonLoader(color: _primary)
                      : const Text('Load more'),
                ),
              ],
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

class _NewsCardTheme {
  const _NewsCardTheme({required this.dotColor, required this.backgroundColor});

  final Color dotColor;
  final Color backgroundColor;

  static const Color cardBorder = Color(0xFFEEF4F2);

  static const List<_NewsCardTheme> cycle = [
    _NewsCardTheme(dotColor: Color(0xFF2E9B86), backgroundColor: Color(0x80EEFFF9)),
    _NewsCardTheme(dotColor: Color(0xFF173559), backgroundColor: Color(0x80E5F1FE)),
    _NewsCardTheme(dotColor: Color(0xFF7B61FF), backgroundColor: Color(0x80FAF6FF)),
  ];
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.item,
    required this.index,
    required this.formatDate,
    required this.onTap,
  });

  final NewsItem item;
  final int index;
  final String Function(String?) formatDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _NewsCardTheme.cycle[index % _NewsCardTheme.cycle.length];
    final date = item.publishedAt ?? item.createdAt;
    final preview = item.content.trim().isEmpty ? '-' : item.content.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: palette.dotColor, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    color: palette.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _NewsCardTheme.cardBorder, width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
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
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff173559),
                                  fontSize: 14,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF173559),
                              size: 32,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: const Color(0xFF090909),
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            formatDate(date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF999999),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
