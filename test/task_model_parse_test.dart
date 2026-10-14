import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:leavego_app/models/tasks_response.dart';

void main() {
  test('parses project tasks payload', () {
    const sample = '''
{"success":true,"data":{"current_page":1,"data":[{"id":26,"project_id":2,"title":"Test","description":"test","task_type":"project_task","priority":"high","status":"assigned","department_id":null,"assigned_by":4,"assigned_to":13,"parent_task_id":null,"start_date":"2026-10-12T00:00:00.000000Z","start_time":"12:22:00","due_date":"2026-10-12T00:00:00.000000Z","due_time":"17:22:00","links":null,"estimated_hours":1,"completion_date":null,"is_supporting_task":0,"created_at":"2026-10-12T07:22:49.000000Z","updated_at":"2026-10-12T07:22:49.000000Z","assigned_user_ids":[13,2],"my_assignment":null,"project":{"id":2,"name":"Movenpic"},"creator":{"id":4,"name":"Mishaal Fatima"},"assignee":{"id":13,"name":"Saba Parveen"},"department":null,"assignments":[{"id":27,"task_id":26,"user_id":13,"status":"assigned","completion_date":null}]}],"first_page_url":"x","last_page_url":"x","path":"x","per_page":15,"to":1,"total":1,"links":[{"url":null,"label":"1","active":1}]}}
''';

    final payload = jsonDecode(sample) as Map<String, dynamic>;
    final response = TasksResponse.fromJson(payload);
    expect(response.data.items.length, 1);
    expect(response.data.items.first.assignedUserIds, [13, 2]);
    expect(response.data.items.first.isAssignedToUserId(13), isTrue);
    expect(response.data.items.first.isAssignedToUserId(2), isTrue);
    expect(response.data.items.first.isAssignedToUserId(99), isFalse);
  });
}
