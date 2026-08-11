import 'package:flutter_test/flutter_test.dart';
import 'package:leavego_app/services/notification_navigation_service.dart';

NotificationDestination destinationFor(Map<String, dynamic> data) {
  return NotificationNavigationService.resolveRoute(data).destination;
}

void main() {
  group('task notifications', () {
    test('opens task detail when a task id is present', () {
      final route = NotificationNavigationService.resolveRoute(<String, dynamic>{
        'type': 'task_assigned',
        'title': 'Task Assigned',
        'task_id': '42',
      });

      expect(route.destination, NotificationDestination.taskDetail);
      expect(route.id, '42');
    });

    test('accepts camelCase task id from push data', () {
      final route = NotificationNavigationService.resolveRoute(<String, dynamic>{
        'taskId': '7',
      });

      expect(route.destination, NotificationDestination.taskDetail);
      expect(route.id, '7');
    });

    test('falls back to the task list when the id is missing', () {
      expect(
        destinationFor(<String, dynamic>{'title': 'Task Completed'}),
        NotificationDestination.taskList,
      );
    });

    test('ignores a literal "null" id string', () {
      expect(
        destinationFor(<String, dynamic>{'task_id': 'null', 'title': 'Task Updated'}),
        NotificationDestination.taskList,
      );
    });
  });

  group('leave notifications', () {
    test('opens leave detail for any supported id key', () {
      for (final key in const ['leave_request_id', 'leaveRequestId', 'leave_id', 'leaveId']) {
        final route = NotificationNavigationService.resolveRoute(<String, dynamic>{key: '9'});

        expect(route.destination, NotificationDestination.leaveDetail, reason: key);
        expect(route.id, '9', reason: key);
      }
    });

    test('falls back to my leave requests when the id is missing', () {
      expect(
        destinationFor(<String, dynamic>{'title': 'Leave Approved'}),
        NotificationDestination.leaveList,
      );
    });

    test('routes approval wording to the leave list', () {
      expect(
        destinationFor(<String, dynamic>{'type': 'approval_pending'}),
        NotificationDestination.leaveList,
      );
    });
  });

  group('project notifications', () {
    test('routes "Project Assigned" to the projects tab', () {
      expect(
        destinationFor(<String, dynamic>{'title': 'Project Assigned'}),
        NotificationDestination.projectsTab,
      );
    });

    test('routes a project id payload to the projects tab', () {
      expect(
        destinationFor(<String, dynamic>{'project_id': '3'}),
        NotificationDestination.projectsTab,
      );
    });

    test('still opens the task when a project task carries a task id', () {
      final route = NotificationNavigationService.resolveRoute(<String, dynamic>{
        'type': 'project_task_assigned',
        'project_id': '3',
        'task_id': '11',
      });

      expect(route.destination, NotificationDestination.taskDetail);
      expect(route.id, '11');
    });
  });

  group('news notifications', () {
    test('routes news wording to news', () {
      expect(
        destinationFor(<String, dynamic>{'title': 'Company News Published'}),
        NotificationDestination.news,
      );
    });

    test('routes announcements to news', () {
      expect(
        destinationFor(<String, dynamic>{'message': 'New announcement from HR'}),
        NotificationDestination.news,
      );
    });

    test('carries the news id so the detail screen can be opened', () {
      final route = NotificationNavigationService.resolveRoute(<String, dynamic>{
        'type': 'news',
        'news_id': '5',
      });

      expect(route.destination, NotificationDestination.news);
      expect(route.id, '5');
    });
  });

  group('fallbacks', () {
    test('unknown payloads land on the notifications tab', () {
      expect(
        destinationFor(<String, dynamic>{'type': 'info', 'title': 'Welcome'}),
        NotificationDestination.notificationsTab,
      );
    });

    test('an empty payload never dead-ends', () {
      expect(
        destinationFor(<String, dynamic>{}),
        NotificationDestination.notificationsTab,
      );
    });

    test('matching is case insensitive', () {
      expect(
        destinationFor(<String, dynamic>{'title': 'PROJECT ASSIGNED'}),
        NotificationDestination.projectsTab,
      );
    });
  });
}
