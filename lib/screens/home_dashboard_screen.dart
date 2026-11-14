import 'dart:async';

import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/task_item.dart';
import '../services/task_service.dart';
import '../utils/theme.dart';
import '../utils/ui.dart';
import '../widgets/progress_ring.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    super.key,
    required this.onNavigateToTasks,
  });

  final VoidCallback onNavigateToTasks;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _tasks = TaskService();
  late final Stream<List<TaskItem>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _tasks.watchTasks();
  }

  void _toggle(TaskItem task, bool completed) {
    _tasks.setCompleted(task.id, completed).catchError((Object e) {
      showMessage('Could not update task: $e');
    });
  }

  void _openDetail(TaskItem task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailScreen(taskId: task.id),
      ),
    );
  }

  void _openEdit(TaskItem task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskFormScreen(task: task),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getFirstName() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(' ').first;
    }
    final email = user?.email?.split('@').first;
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase() + email.substring(1);
    }
    return 'Student';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    return Scaffold(
      backgroundColor: TaskMateColors.background,
      body: StreamBuilder<List<TaskItem>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load tasks.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(),
                ),
              ),
            );
          }

          final allTasks = snapshot.data ?? [];
          final pendingTasks = allTasks.where((t) => !t.isCompleted).toList();
          final completedTasks = allTasks.where((t) => t.isCompleted).toList();
          final overdueTasks = allTasks.where((t) => t.isOverdue).toList();

          final totalCount = allTasks.length;
          final completedCount = completedTasks.length;
          final progressRate = totalCount == 0 ? 0.0 : (completedCount / totalCount);
          final progressPct = (progressRate * 100).toInt();

          // Upcoming (pending tasks sorted by due date)
          final upcomingList = pendingTasks.take(3).toList();

          // Recently added (sorted by creation or due date)
          final recentList = List<TaskItem>.from(allTasks)
            ..sort((a, b) {
              final aDate = a.createdAt ?? a.dueDate;
              final bDate = b.createdAt ?? b.dueDate;
              return bDate.compareTo(aDate);
            });
          final recentDisplay = recentList.take(2).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Week Badge Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: TaskMateColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: TaskMateColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  dateStr,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: TaskMateColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: TaskMateColors.surfaceLow,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: TaskMateColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Focus Session',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: TaskMateColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Greeting Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getGreeting()}, ${_getFirstName()}!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: TaskMateColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pendingTasks.isEmpty
                                      ? 'All caught up! No pending tasks right now.'
                                      : 'You have ${pendingTasks.length} ${pendingTasks.length == 1 ? 'priority' : 'priorities'} scheduled for review.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: TaskMateColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: TaskMateColors.secondaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.energy_savings_leaf_rounded,
                                size: 22,
                                color: TaskMateColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Midterm Progress Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: TaskMateColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ACADEMIC PROGRESS',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.7,
                                      color: TaskMateColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$progressPct% Completed',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: TaskMateColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$completedCount of $totalCount assignments submitted',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: TaskMateColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TaskMateProgressRing(
                              progress: progressRate,
                              label: '$completedCount/$totalCount',
                              size: 58,
                              strokeWidth: 5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2x2 Metric Cards Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          // Card 1: Total Tasks
                          _buildMetricCard(
                            icon: Icons.format_list_bulleted_rounded,
                            iconColor: TaskMateColors.primary,
                            iconBg: TaskMateColors.surfaceContainer,
                            tag: 'Active',
                            tagColor: TaskMateColors.onSecondaryContainer,
                            tagBg: TaskMateColors.secondaryContainer,
                            count: '$totalCount',
                            label: 'Total Tasks',
                            countColor: TaskMateColors.onSurface,
                          ),
                          // Card 2: Pending Tasks
                          _buildMetricCard(
                            icon: Icons.hourglass_top_rounded,
                            iconColor: TaskMateColors.tertiary,
                            iconBg: TaskMateColors.tertiaryFixed,
                            tag: '${pendingTasks.length} Pending',
                            tagColor: TaskMateColors.tertiary,
                            tagBg: TaskMateColors.tertiaryFixedDim.withValues(alpha: 0.3),
                            count: '${pendingTasks.length}',
                            label: 'Pending',
                            countColor: TaskMateColors.tertiary,
                          ),
                          // Card 3: Completed Tasks
                          _buildMetricCard(
                            icon: Icons.task_alt_rounded,
                            iconColor: TaskMateColors.primary,
                            iconBg: TaskMateColors.primaryFixed,
                            tag: '$progressPct% Done',
                            tagColor: TaskMateColors.primary,
                            tagBg: TaskMateColors.primaryFixed,
                            count: '$completedCount',
                            label: 'Completed',
                            countColor: TaskMateColors.primary,
                          ),
                          // Card 4: Overdue Tasks
                          _buildMetricCard(
                            icon: Icons.warning_amber_rounded,
                            iconColor: TaskMateColors.error,
                            iconBg: TaskMateColors.errorContainer,
                            tag: overdueTasks.isEmpty ? 'All clear' : 'Urgent',
                            tagColor: TaskMateColors.error,
                            tagBg: TaskMateColors.errorContainer,
                            count: '${overdueTasks.length}',
                            label: 'Overdue',
                            countColor: TaskMateColors.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Upcoming Tasks Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.upcoming_rounded,
                                size: 19,
                                color: TaskMateColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Upcoming Tasks',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: TaskMateColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: widget.onNavigateToTasks,
                            child: Row(
                              children: [
                                Text(
                                  'See all',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: TaskMateColors.primary,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: TaskMateColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (upcomingList.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(18),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: TaskMateColors.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TaskMateColors.outlineVariant),
                          ),
                          child: Center(
                            child: Text(
                              'No pending assignments coming up! Enjoy your free time.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: TaskMateColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        ...upcomingList.map((task) => TaskCard(
                              task: task,
                              onTap: () => _openDetail(task),
                              onToggle: (v) => _toggle(task, v),
                              onEdit: () => _openEdit(task),
                            )),

                      const SizedBox(height: 18),

                      // Recently Added Section Header
                      if (recentDisplay.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.history_edu_rounded,
                                  size: 19,
                                  color: TaskMateColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Recently Added',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: TaskMateColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: widget.onNavigateToTasks,
                              child: Text(
                                'View All',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TaskMateColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...recentDisplay.map((task) => TaskCard(
                              task: task,
                              onTap: () => _openDetail(task),
                              onToggle: (v) => _toggle(task, v),
                              onEdit: () => _openEdit(task),
                            )),
                        const SizedBox(height: 18),
                      ],

                      // Campus Tip Delight Strip
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: TaskMateColors.surfaceLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: TaskMateColors.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: TaskMateColors.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                size: 18,
                                color: TaskMateColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '"Focus on being productive instead of busy."',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500,
                                      color: TaskMateColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Campus Tip • TaskMate Calm Engine',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: TaskMateColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
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

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String tag,
    required Color tagColor,
    required Color tagBg,
    required String count,
    required String label,
    required Color countColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TaskMateColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TaskMateColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: countColor,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: TaskMateColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
