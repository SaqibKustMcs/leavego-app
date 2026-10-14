import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/config/google_calendar_config.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/ui/widgets/google_calendar_android_setup_help.dart';
import 'package:leavego_app/ui/widgets/today_glance_meetings_body.dart';

const Color _primary = Color(0xFF173559);
const Color _muted = Color(0xFF999999);

class GoogleCalendarScreen extends StatefulWidget {
  const GoogleCalendarScreen({super.key});

  @override
  State<GoogleCalendarScreen> createState() => _GoogleCalendarScreenState();
}

class _GoogleCalendarScreenState extends State<GoogleCalendarScreen> {
  late final AppController _appController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _scrollController = ScrollController()..addListener(_onScroll);
    _appController.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appController.ensureGoogleCalendarReady();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_appController.googleCalendarEventsLoadingMore ||
        !_appController.googleCalendarEventsHasMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _appController.loadMoreGoogleCalendarEvents();
    }
  }

  void _onUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _appController.ensureGoogleCalendarReady(refreshEvents: true);
  }

  Future<void> _connect() async {
    final ok = await _appController.connectGoogleCalendar();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Calendar connected')),
      );
    } else {
      final err = _appController.googleCalendarConnectError;
      if (err != null && err.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Google Calendar?'),
        content: const Text(
          'TaskBulls will stop syncing your Google Calendar events. You can connect again anytime.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Disconnect')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await _appController.disconnectGoogleCalendar();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Calendar disconnected')),
      );
    } else {
      final err = _appController.googleCalendarDisconnectError;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  void _showSettingsSheet() {
    final connected = _appController.googleCalendarConnected;
    final email = _appController.googleCalendarGoogleEmail;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.appBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.paddingOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DEEA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                connected ? 'Connected' : 'Not connected',
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              if (email != null && email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: _muted, fontSize: 13)),
              ],
              if (!GoogleCalendarConfig.isConfigured) ...[
                const SizedBox(height: 12),
                const GoogleCalendarAndroidSetupHelp(),
              ],
              const SizedBox(height: 16),
              if (!connected)
                FilledButton(
                  onPressed: _appController.googleCalendarConnectLoading ? null : () {
                    Navigator.pop(ctx);
                    _connect();
                  },
                  child: _appController.googleCalendarConnectLoading
                      ? const AppButtonLoader(color: Colors.white, size: 18)
                      : const Text('Connect Google Calendar'),
                )
              else ...[
                OutlinedButton(
                  onPressed: _appController.googleCalendarEventsLoading
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _appController.loadGoogleCalendarEvents(
                            refresh: true,
                            allowInteractiveAuth: true,
                          );
                        },
                  child: const Text('Sync events'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _appController.googleCalendarDisconnectLoading
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _disconnect();
                        },
                  style: OutlinedButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
                  child: const Text('Disconnect'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected = _appController.googleCalendarConnected;
    final upcoming = _appController.googleCalendarUpcomingMeetings;
    final loading = _appController.googleCalendarEventsLoading;
    final loadingMore = _appController.googleCalendarEventsLoadingMore;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(),
        title: const Text(
          'Google Calendar',
          style: TextStyle(color: _primary, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: _primary),
            onPressed: _showSettingsSheet,
          ),
        ],
      ),
      body: TodayGlanceMeetingsBody(
        scrollController: _scrollController,
        connected: connected,
        loading: loading && upcoming.isEmpty,
        loadingMore: loadingMore,
        error: _appController.googleCalendarEventsError,
        events: upcoming,
        onRefresh: _onRefresh,
        onConnect: _connect,
        connectLoading: _appController.googleCalendarConnectLoading,
      ),
    );
  }
}
