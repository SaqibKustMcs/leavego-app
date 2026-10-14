class GoogleCalendarEventItem {
  const GoogleCalendarEventItem({
    required this.id,
    required this.calendarId,
    required this.summary,
    this.description,
    this.location,
    this.status,
    this.htmlLink,
    required this.allDay,
    this.startDateTime,
    this.endDateTime,
    this.startDate,
    this.endDate,
    this.timeZone,
  });

  final String id;
  final String calendarId;
  final String summary;
  final String? description;
  final String? location;
  final String? status;
  final String? htmlLink;
  final bool allDay;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? startDate;
  final String? endDate;
  final String? timeZone;

  DateTime? get effectiveStart {
    if (startDateTime != null) return startDateTime!.toLocal();
    if (startDate != null && startDate!.isNotEmpty) {
      try {
        return DateTime.parse(startDate!).toLocal();
      } catch (_) {}
    }
    return null;
  }

  DateTime? get effectiveEnd {
    if (endDateTime != null) return endDateTime!.toLocal();
    if (endDate != null && endDate!.isNotEmpty) {
      try {
        return DateTime.parse(endDate!).toLocal();
      } catch (_) {}
    }
    return null;
  }

  bool occursOnLocalDay(DateTime day) {
    final start = effectiveStart;
    if (start == null) return false;
    final localDay = DateTime(day.year, day.month, day.day);
    final eventDay = DateTime(start.year, start.month, start.day);
    if (allDay) {
      final end = effectiveEnd;
      if (end == null) return eventDay == localDay;
      final endDay = DateTime(end.year, end.month, end.day);
      return !localDay.isBefore(eventDay) && localDay.isBefore(endDay);
    }
    return eventDay == localDay;
  }

  /// True if the event has not ended yet relative to [now] (includes in-progress meetings).
  bool isUpcomingFrom(DateTime now) {
    if (status == 'cancelled') return false;
    final start = effectiveStart;
    if (start == null) return false;

    if (allDay) {
      final today = DateTime(now.year, now.month, now.day);
      final startDay = DateTime(start.year, start.month, start.day);
      if (today.isBefore(startDay)) return true;
      final end = effectiveEnd;
      if (end == null) return !today.isBefore(startDay);
      final endDay = DateTime(end.year, end.month, end.day);
      return today.isBefore(endDay);
    }

    final end = effectiveEnd;
    if (end != null && !end.isAfter(now)) return false;
    return start.isAfter(now) || (end != null && end.isAfter(now));
  }

  static int compareByStart(GoogleCalendarEventItem a, GoogleCalendarEventItem b) {
    final sa = a.effectiveStart;
    final sb = b.effectiveStart;
    if (sa == null && sb == null) return 0;
    if (sa == null) return 1;
    if (sb == null) return -1;
    return sa.compareTo(sb);
  }

  factory GoogleCalendarEventItem.fromGoogleApiJson(Map<String, dynamic> json) {
    final start = json['start'];
    final end = json['end'];
    DateTime? startDt;
    DateTime? endDt;
    String? startD;
    String? endD;
    String? tz;

    if (start is Map<String, dynamic>) {
      startDt = _parseDateTime(start['dateTime'] ?? start['date_time']);
      startD = _nullableString(start['date']);
      tz = _nullableString(start['timeZone'] ?? start['time_zone']);
    }
    if (end is Map<String, dynamic>) {
      endDt = _parseDateTime(end['dateTime'] ?? end['date_time']);
      endD = _nullableString(end['date']);
    }

    final inferredAllDay = startD != null && startDt == null;

    return GoogleCalendarEventItem(
      id: (json['id'] ?? '').toString(),
      calendarId: (json['organizer'] is Map
              ? (json['organizer'] as Map)['email']
              : null)
          ?.toString() ??
          'primary',
      summary: (json['summary'] ?? 'Untitled event').toString(),
      description: _nullableString(json['description']),
      location: _nullableString(json['location']),
      status: _nullableString(json['status']),
      htmlLink: _nullableString(json['htmlLink'] ?? json['html_link']),
      allDay: inferredAllDay,
      startDateTime: startDt,
      endDateTime: endDt,
      startDate: startD,
      endDate: endD,
      timeZone: tz,
    );
  }

  factory GoogleCalendarEventItem.fromJson(Map<String, dynamic> json) {
    final start = json['start'];
    final end = json['end'];
    DateTime? startDt;
    DateTime? endDt;
    String? startD;
    String? endD;
    String? tz;

    if (start is Map<String, dynamic>) {
      startDt = _parseDateTime(start['date_time'] ?? start['dateTime']);
      startD = _nullableString(start['date']);
      tz = _nullableString(start['time_zone'] ?? start['timeZone']);
    }
    if (end is Map<String, dynamic>) {
      endDt = _parseDateTime(end['date_time'] ?? end['dateTime']);
      endD = _nullableString(end['date']);
    }

    final allDayFlag = json['all_day'] == true || json['allDay'] == true;
    final inferredAllDay = allDayFlag || (startD != null && startDt == null);

    return GoogleCalendarEventItem(
      id: (json['id'] ?? json['event_id'] ?? '').toString(),
      calendarId: (json['calendar_id'] ?? json['calendarId'] ?? 'primary').toString(),
      summary: (json['summary'] ?? json['title'] ?? 'Untitled event').toString(),
      description: _nullableString(json['description']),
      location: _nullableString(json['location']),
      status: _nullableString(json['status']),
      htmlLink: _nullableString(json['html_link'] ?? json['htmlLink']),
      allDay: inferredAllDay,
      startDateTime: startDt,
      endDateTime: endDt,
      startDate: startD,
      endDate: endD,
      timeZone: tz,
    );
  }
}

class GoogleCalendarEventsPageData {
  const GoogleCalendarEventsPageData({
    required this.items,
    this.nextPageToken,
    this.currentPage,
    this.lastPage,
    this.total,
  });

  final List<GoogleCalendarEventItem> items;
  final String? nextPageToken;
  final int? currentPage;
  final int? lastPage;
  final int? total;

  bool get hasMore {
    final token = nextPageToken?.trim();
    if (token != null && token.isNotEmpty) return true;
    if (currentPage != null && lastPage != null && lastPage! > 0) {
      return currentPage! < lastPage!;
    }
    return false;
  }

  factory GoogleCalendarEventsPageData.fromJson(Map<String, dynamic> json) {
    final rawList = json['items'] ?? json['data'] ?? json['events'];
    final items = rawList is List
        ? rawList
              .whereType<Map<String, dynamic>>()
              .map(GoogleCalendarEventItem.fromJson)
              .toList()
        : <GoogleCalendarEventItem>[];

    return GoogleCalendarEventsPageData(
      items: items,
      nextPageToken: _nullableString(json['next_page_token'] ?? json['nextPageToken']),
      currentPage: _toNullableInt(json['current_page'] ?? json['page']),
      lastPage: _toNullableInt(json['last_page']),
      total: _toNullableInt(json['total']),
    );
  }
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

DateTime? _parseDateTime(Object? value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  try {
    return DateTime.parse(raw);
  } catch (_) {
    return null;
  }
}

int? _toNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
