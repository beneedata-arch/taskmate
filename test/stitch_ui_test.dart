import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskmate/models/task_item.dart';
import 'package:taskmate/utils/theme.dart';
import 'package:taskmate/widgets/brand_logo.dart';
import 'package:taskmate/widgets/progress_ring.dart';
import 'package:taskmate/widgets/task_card.dart';

void main() {
  group('Stitch UI Components', () {
    testWidgets('TaskMateLogo renders with icon and badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: TaskMateLogo(size: 80, showBadge: true),
            ),
          ),
        ),
      );

      expect(find.byType(TaskMateLogo), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
    });

    testWidgets('TaskMateProgressRing renders label and arc', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: TaskMateProgressRing(
                progress: 0.5,
                label: '6/12',
                size: 60,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TaskMateProgressRing), findsOneWidget);
      expect(find.text('6/12'), findsOneWidget);
    });

    testWidgets('TaskCard renders title, status chip and toggles completion',
        (tester) async {
      bool toggled = false;
      final task = TaskItem(
        id: '101',
        userId: 'u1',
        title: 'Database Systems Assignment',
        description: '3NF schema normalization',
        subject: 'CS 301',
        category: 'Assignment',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        isCompleted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: TaskMateTheme.lightTheme,
          home: Scaffold(
            body: TaskCard(
              task: task,
              onTap: () {},
              onToggle: (val) => toggled = val,
            ),
          ),
        ),
      );

      expect(find.text('Database Systems Assignment'), findsOneWidget);
      expect(find.text('CS 301'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      // Tap checkbox
      await tester.tap(find.byKey(const ValueKey('task_checkbox')));
      await tester.pump();
      expect(toggled, true);
    });
  });
}
