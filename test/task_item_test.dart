import 'package:flutter_test/flutter_test.dart';
import 'package:taskmate/models/task_item.dart';

void main() {
  group('TaskItem', () {
    test('fromMap reads all fields', () {
      final due = DateTime(2030, 1, 15, 18, 30);
      final task = TaskItem.fromMap('abc', {
        'userId': 'u1',
        'title': 'Finish report',
        'description': 'Chapter 1-3',
        'subject': 'Mobile Programming',
        'category': 'Project',
        'dueDate': due,
        'isCompleted': true,
        'attachmentUrl': 'https://example.com/file.pdf',
        'attachmentPath': 'attachments/u1/abc/file.pdf',
        'attachmentName': 'file.pdf',
      });

      expect(task.id, 'abc');
      expect(task.userId, 'u1');
      expect(task.title, 'Finish report');
      expect(task.subject, 'Mobile Programming');
      expect(task.category, 'Project');
      expect(task.dueDate, due);
      expect(task.isCompleted, true);
      expect(task.hasAttachment, true);
    });

    test('fromMap applies defaults for missing fields', () {
      final task = TaskItem.fromMap('x', {});
      expect(task.title, '');
      expect(task.isCompleted, false);
      expect(task.category, 'Assignment');
      expect(task.hasAttachment, false);
    });

    test('toFirestore writes the expected keys', () {
      final due = DateTime(2030, 1, 15);
      final map = TaskItem(
        id: '1',
        userId: 'u1',
        title: 'Quiz 2',
        dueDate: due,
        subject: 'Math',
        category: 'Quiz',
      ).toFirestore();

      expect(map['userId'], 'u1');
      expect(map['title'], 'Quiz 2');
      expect(map['dueDate'], due.toIso8601String());
      expect(map['isCompleted'], false);
      expect(map['reminderSent'], false);
    });

    test('isOverdue only for unfinished tasks past the deadline', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final future = DateTime.now().add(const Duration(days: 1));

      expect(
        TaskItem(id: '1', userId: 'u', title: 'a', dueDate: past).isOverdue,
        true,
      );
      expect(
        TaskItem(
          id: '2',
          userId: 'u',
          title: 'b',
          dueDate: past,
          isCompleted: true,
        ).isOverdue,
        false,
      );
      expect(
        TaskItem(id: '3', userId: 'u', title: 'c', dueDate: future).isOverdue,
        false,
      );
    });

    test('isDueWithin detects deadlines in the next 24 hours', () {
      final soon = DateTime.now().add(const Duration(hours: 5));
      final later = DateTime.now().add(const Duration(days: 3));
      const window = Duration(hours: 24);

      expect(
        TaskItem(id: '1', userId: 'u', title: 'a', dueDate: soon)
            .isDueWithin(window),
        true,
      );
      expect(
        TaskItem(id: '2', userId: 'u', title: 'b', dueDate: later)
            .isDueWithin(window),
        false,
      );
    });
  });
}
