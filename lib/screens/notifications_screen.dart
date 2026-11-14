import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_item.dart';
import '../services/task_service.dart';
import '../utils/theme.dart';
import '../utils/ui.dart';
import 'task_detail_screen.dart';

class NotificationAlertItem {
  NotificationAlertItem({
    required this.id,
    required this.title,
    required this.message,
    required this.courseCode,
    required this.timeText,
    required this.icon,
    this.isUnread = true,
    this.task,
  });

  final String id;
  final String title;
  final String message;
  final String courseCode;
  final String timeText;
  final IconData icon;
  bool isUnread;
  final TaskItem? task;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _tasks = TaskService();
  late final Stream<List<TaskItem>> _stream;

  final Set<String> _readAlertIds = {};

  @override
  void initState() {
    super.initState();
    _stream = _tasks.watchTasks();
  }

  void _markAllRead(List<NotificationAlertItem> alerts) {
    setState(() {
      for (final a in alerts) {
        _readAlertIds.add(a.id);
      }
    });
    showMessage('All notifications marked as read', isSuccess: true);
  }

  void _showTaskQuickModal(NotificationAlertItem alert) {
    setState(() {
      _readAlertIds.add(alert.id);
    });

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: TaskMateColors.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TaskMateColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: TaskMateColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      alert.courseCode,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: TaskMateColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                alert.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TaskMateColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TaskMateColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  alert.message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: TaskMateColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (alert.task != null)
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TaskMateColors.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(
                      'Open Full Assignment',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              TaskDetailScreen(taskId: alert.task!.id),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaskMateColors.background,
      body: StreamBuilder<List<TaskItem>>(
        stream: _stream,
        builder: (context, snapshot) {
          final allTasks = snapshot.data ?? [];

          // Generate dynamic smart notification items based on actual user tasks!
          final List<NotificationAlertItem> todayAlerts = [];
          final List<NotificationAlertItem> earlierAlerts = [];

          for (final task in allTasks) {
            final shortId = task.id.length > 6 ? task.id.substring(0, 6).toUpperCase() : task.id.toUpperCase();
            final code = task.subject.isNotEmpty ? '#TSK-$shortId • ${task.subject}' : '#TSK-$shortId';

            if (task.isDueWithin(const Duration(hours: 24))) {
              final hoursLeft = task.dueDate.difference(DateTime.now()).inHours;
              todayAlerts.add(
                NotificationAlertItem(
                  id: 'due_${task.id}',
                  title: 'Deadline Approaching: ${task.title}',
                  message: 'Due in ~$hoursLeft hours (${shortDueFormat.format(task.dueDate)}). Don\'t forget to submit your work!',
                  courseCode: code,
                  timeText: 'Due in $hoursLeft hrs',
                  icon: Icons.timer_outlined,
                  isUnread: !_readAlertIds.contains('due_${task.id}'),
                  task: task,
                ),
              );
            } else if (task.isOverdue) {
              todayAlerts.add(
                NotificationAlertItem(
                  id: 'overdue_${task.id}',
                  title: 'Overdue: ${task.title}',
                  message: 'This assignment was due on ${shortDueFormat.format(task.dueDate)}. Complete it as soon as possible.',
                  courseCode: code,
                  timeText: 'Overdue alert',
                  icon: Icons.warning_amber_rounded,
                  isUnread: !_readAlertIds.contains('overdue_${task.id}'),
                  task: task,
                ),
              );
            } else if (task.isCompleted) {
              earlierAlerts.add(
                NotificationAlertItem(
                  id: 'done_${task.id}',
                  title: 'Task Completed: ${task.title}',
                  message: 'Great job! You marked "${task.title}" as completed.',
                  courseCode: code,
                  timeText: 'Completed',
                  icon: Icons.check_circle_rounded,
                  isUnread: !_readAlertIds.contains('done_${task.id}'),
                  task: task,
                ),
              );
            }
          }

          // If empty, add a default welcoming alert
          if (todayAlerts.isEmpty && earlierAlerts.isEmpty) {
            todayAlerts.add(
              NotificationAlertItem(
                id: 'welcome',
                title: 'Welcome to TaskMate!',
                message: 'Your push notifications and deadline reminders will appear here in real time.',
                courseCode: 'Campus Welcome',
                timeText: 'Just now',
                icon: Icons.notifications_active_outlined,
                isUnread: !_readAlertIds.contains('welcome'),
              ),
            );
          }

          final allAlerts = [...todayAlerts, ...earlierAlerts];
          final unreadCount = allAlerts.where((a) => a.isUnread).length;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Notifications',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: TaskMateColors.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: unreadCount > 0
                                      ? TaskMateColors.secondaryContainer
                                      : TaskMateColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  '$unreadCount new',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: unreadCount > 0
                                        ? TaskMateColors.onSecondaryContainer
                                        : TaskMateColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: TaskMateColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                            ),
                            icon: const Icon(Icons.done_all_rounded, size: 16),
                            label: Text(
                              'Mark all as read',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () => _markAllRead(allAlerts),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Study Cadence Gentle Reassurance Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: TaskMateColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TaskMateColors.outlineVariant),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: TaskMateColors.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                size: 20,
                                color: TaskMateColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Study Cadence',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: TaskMateColors.primary,
                                        ),
                                      ),
                                      Text(
                                        'Sync: Active',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11,
                                          color: TaskMateColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Reminders and approaching deadline alerts will notify you here so you never miss a course milestone.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: TaskMateColors.onSurfaceVariant,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Today Alerts Section
                      if (todayAlerts.isNotEmpty) ...[
                        Row(
                          children: [
                            Text(
                              'Today',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: TaskMateColors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: TaskMateColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${todayAlerts.length} alerts',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: TaskMateColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...todayAlerts.map(_buildAlertCard),
                        const SizedBox(height: 20),
                      ],

                      // Earlier Alerts Section
                      if (earlierAlerts.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Earlier',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: TaskMateColors.onSurface,
                              ),
                            ),
                            Text(
                              'Archived',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: TaskMateColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...earlierAlerts.map(_buildAlertCard),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(NotificationAlertItem alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: TaskMateColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert.isUnread
              ? TaskMateColors.primaryFixedDim
              : TaskMateColors.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showTaskQuickModal(alert),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading Icon with Unread Dot
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: alert.isUnread
                            ? TaskMateColors.tertiaryFixed
                            : TaskMateColors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        alert.icon,
                        size: 20,
                        color: alert.isUnread
                            ? TaskMateColors.tertiary
                            : TaskMateColors.primary,
                      ),
                    ),
                    if (alert.isUnread)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: TaskMateColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: TaskMateColors.surfaceCard,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              alert.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: TaskMateColors.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: alert.isUnread
                                  ? TaskMateColors.secondaryContainer
                                  : TaskMateColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              alert.isUnread ? 'Unread' : 'Read',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: alert.isUnread
                                    ? TaskMateColors.onSecondaryContainer
                                    : TaskMateColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: TaskMateColors.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: TaskMateColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              alert.courseCode,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: TaskMateColors.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            alert.timeText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: TaskMateColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

