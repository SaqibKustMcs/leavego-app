import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:leavego_app/config/google_calendar_config.dart';
import 'package:leavego_app/models/google_calendar_response.dart';
import 'package:leavego_app/services/google_calendar_auth_service.dart';

/// Fetches events from Google Calendar API v3 (no TaskBulls backend).
class GoogleCalendarDirectService {
  GoogleCalendarDirectService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _eventsUrl = 'https://www.googleapis.com/calendar/v3/calendars/primary/events';

  Future<GoogleCalendarEventsPageData> fetchEvents({
    required DateTime timeMin,
    required DateTime timeMax,
    int maxResults = GoogleCalendarConfig.defaultEventsPerPage,
    String? pageToken,
    bool allowInteractiveAuth = false,
  }) async {
    final auth = GoogleCalendarAuthService.instance;
    var accessToken = await auth.getCalendarAccessToken(
      interactiveIfNeeded: allowInteractiveAuth,
    );

    http.Response response;
    try {
      response = await _getEvents(
        accessToken: accessToken,
        timeMin: timeMin,
        timeMax: timeMax,
        maxResults: maxResults,
        pageToken: pageToken,
      );
    } on SocketException {
      throw Exception('No internet connection. Check your network and try again.');
    } on HttpException catch (e) {
      throw Exception(e.message);
    }

    if (response.statusCode == 401) {
      accessToken = await auth.refreshAccessTokenAfterUnauthorized(accessToken);
      try {
        response = await _getEvents(
          accessToken: accessToken,
          timeMin: timeMin,
          timeMax: timeMax,
          maxResults: maxResults,
          pageToken: pageToken,
        );
      } on SocketException {
        throw Exception('No internet connection. Check your network and try again.');
      }
    }

    if (response.statusCode == 401) {
      if (allowInteractiveAuth) {
        accessToken = await auth.getCalendarAccessToken(interactiveIfNeeded: true);
        response = await _getEvents(
          accessToken: accessToken,
          timeMin: timeMin,
          timeMax: timeMax,
          maxResults: maxResults,
          pageToken: pageToken,
        );
      } else {
        throw const GoogleCalendarAuthException(
          GoogleCalendarAuthException.codeSessionExpired,
          'Google Calendar authorization expired. Connect again from Profile.',
        );
      }
    }

    if (response.statusCode == 403) {
      throw const GoogleCalendarAuthException(
        GoogleCalendarAuthException.codePermissionRevoked,
        'Google Calendar access was revoked. Connect again from Profile.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractGoogleError(response.body);
      throw Exception(message ?? 'Google Calendar request failed (${response.statusCode})');
    }

    return _parseEventsPage(response.body);
  }

  Future<http.Response> _getEvents({
    required String accessToken,
    required DateTime timeMin,
    required DateTime timeMax,
    required int maxResults,
    String? pageToken,
  }) async {
    final query = <String, String>{
      'timeMin': timeMin.toUtc().toIso8601String(),
      'timeMax': timeMax.toUtc().toIso8601String(),
      'singleEvents': 'true',
      'orderBy': 'startTime',
      'maxResults': '$maxResults',
      if (pageToken != null && pageToken.trim().isNotEmpty) 'pageToken': pageToken.trim(),
    };

    final uri = Uri.parse(_eventsUrl).replace(queryParameters: query);
    return _client.get(
      uri,
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );
  }

  GoogleCalendarEventsPageData _parseEventsPage(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected Google Calendar response');
    }

    final itemsRaw = decoded['items'];
    final items = itemsRaw is List
        ? itemsRaw
              .whereType<Map<String, dynamic>>()
              .map(GoogleCalendarEventItem.fromGoogleApiJson)
              .toList()
        : <GoogleCalendarEventItem>[];

    return GoogleCalendarEventsPageData(
      items: items,
      nextPageToken: decoded['nextPageToken']?.toString(),
    );
  }

  String? _extractGoogleError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'];
        if (err is Map<String, dynamic>) {
          final msg = err['message'];
          if (msg is String && msg.isNotEmpty) return msg;
        }
      }
    } catch (_) {}
    return null;
  }
}
