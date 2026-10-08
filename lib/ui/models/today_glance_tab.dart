/// Tasks vs Meetings for Today's at a glance (home dropdown + detail tabs).
enum TodayGlanceTab {
  tasks,
  meetings;

  String get label {
    switch (this) {
      case TodayGlanceTab.tasks:
        return 'Tasks';
      case TodayGlanceTab.meetings:
        return 'Meetings';
    }
  }

  static TodayGlanceTab? fromLabel(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'tasks':
        return TodayGlanceTab.tasks;
      case 'meetings':
        return TodayGlanceTab.meetings;
      default:
        return null;
    }
  }
}
