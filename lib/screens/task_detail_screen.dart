import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/task_item.dart';
import '../services/task_service.dart';
import '../utils/theme.dart';
import '../utils/ui.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _tasks = TaskService();
  late final Stream<TaskItem?> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _tasks.watchTask(widget.taskId);
  }

  Future<void> _delete(TaskItem task) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete assignment?',
      message: '"${task.title}" and its associated attachments will be permanently deleted.',
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    unawaited(_tasks.deleteTask(task).catchError((Object e) {
      showMessage('Could not delete task: $e');
    }));
    Navigator.of(context).pop();
    showMessage('Task deleted');
  }

  Future<void> _openAttachment(String url) async {
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) showMessage('No app found to open this attachment.');
    } catch (_) {
      showMessage('Could not open the attachment.');
    }
  }

  void _toggleCompletion(TaskItem task) {
    _tasks.setCompleted(task.id, !task.isCompleted).catchError((Object e) {
      showMessage('Could not update status: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TaskItem?>(
      stream: _stream,
      builder: (context, snapshot) {
        final task = snapshot.data;

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: TaskMateColors.background,
            appBar: AppBar(title: const Text('Task Details')),
            body: Center(
              child: Text(
                'Could not load task.\n${snapshot.error}',
                style: GoogleFonts.plusJakartaSans(),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: TaskMateColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (task == null) {
          return Scaffold(
            backgroundColor: TaskMateColors.background,
            appBar: AppBar(title: const Text('Task Details')),
            body: Center(
              child: Text(
                'This task no longer exists.',
                style: GoogleFonts.plusJakartaSans(),
              ),
            ),
          );
        }

        final isDone = task.isCompleted;
        final overdue = task.isOverdue;
        final shortId = task.id.length > 6 ? task.id.substring(0, 6).toUpperCase() : task.id.toUpperCase();

        Color statusColor;
        Color statusBg;
        String statusLabel;

        if (isDone) {
          statusColor = TaskMateColors.statusCompletedText;
          statusBg = TaskMateColors.statusCompletedBg;
          statusLabel = 'COMPLETED';
        } else if (overdue) {
          statusColor = TaskMateColors.statusOverdueText;
          statusBg = TaskMateColors.statusOverdueBg;
          statusLabel = 'OVERDUE';
        } else if (task.status == 'In Progress') {
          statusColor = TaskMateColors.statusInProgressText;
          statusBg = TaskMateColors.statusInProgressBg;
          statusLabel = 'IN PROGRESS';
        } else {
          statusColor = TaskMateColors.statusPendingText;
          statusBg = TaskMateColors.statusPendingBg;
          statusLabel = 'PENDING';
        }

        final createdDate = task.createdAt != null
            ? DateFormat('MMM d, y').format(task.createdAt!)
            : 'Recently';
        final updatedDate = task.updatedAt != null
            ? DateFormat('MMM d, y').format(task.updatedAt!)
            : 'Recently';

        return Scaffold(
          backgroundColor: TaskMateColors.background,
          appBar: AppBar(
            title: Text(
              'Task Details',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TaskMateColors.onSurface,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                tooltip: 'Edit Task',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TaskFormScreen(task: task),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Delete Task',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _delete(task),
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Pill Tag
                    if (task.subject.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: TaskMateColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: TaskMateColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              task.subject,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: TaskMateColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Main Focus Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: TaskMateColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: TaskMateColors.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status & Task ID Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      statusLabel,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'TASK-$shortId',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TaskMateColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Title
                          Text(
                            task.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: TaskMateColors.onSurface,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Quick Status Action Bar
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: TaskMateColors.surfaceLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _toggleCompletion(task),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: isDone
                                              ? TaskMateColors.primary
                                              : TaskMateColors.surfaceContainerHigh,
                                          shape: BoxShape.circle,
                                        ),
                                        child: isDone
                                            ? const Icon(
                                                Icons.check_rounded,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      isDone
                                          ? 'Completed on time'
                                          : 'Awaiting submission',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: TaskMateColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isDone
                                        ? TaskMateColors.surfaceContainer
                                        : TaskMateColors.primaryContainer,
                                    foregroundColor: isDone
                                        ? TaskMateColors.onSurfaceVariant
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                  ),
                                  onPressed: () => _toggleCompletion(task),
                                  child: Text(
                                    isDone ? 'Undo' : 'Complete',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Metadata Bento Grid (2 items)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: TaskMateColors.surfaceLow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.menu_book_rounded,
                                            size: 15,
                                            color: TaskMateColors.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Course & Category',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: TaskMateColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        task.subject.isNotEmpty ? task.subject.split(' - ').first : 'General',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: TaskMateColors.onSurface,
                                        ),
                                      ),
                                      Text(
                                        task.category,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: TaskMateColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: TaskMateColors.surfaceLow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule_rounded,
                                            size: 15,
                                            color: overdue
                                                ? TaskMateColors.error
                                                : TaskMateColors.tertiary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Due Date',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: TaskMateColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM d, y').format(task.dueDate),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: TaskMateColors.onSurface,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('h:mm a').format(task.dueDate),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: TaskMateColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Active Reminder Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TaskMateColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: TaskMateColors.tertiaryFixed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              size: 18,
                              color: TaskMateColors.tertiary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REMINDER SCHEDULED',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: TaskMateColors.onSurface,
                                  ),
                                ),
                                Text(
                                  'Alert scheduled 24 hours prior to deadline',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: TaskMateColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Assignment Description Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: TaskMateColors.surfaceCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: TaskMateColors.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.subject_rounded,
                                size: 18,
                                color: TaskMateColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Assignment Description',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: TaskMateColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            task.description.isEmpty
                                ? 'No additional description or rubric notes provided.'
                                : task.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: TaskMateColors.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Timestamps
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: TaskMateColors.surfaceLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Created: $createdDate',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: TaskMateColors.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  'Updated: $updatedDate',
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
                    const SizedBox(height: 16),

                    // Course Attachments Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.attach_file_rounded,
                              size: 18,
                              color: TaskMateColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Course Attachments',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: TaskMateColors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: TaskMateColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                task.hasAttachment ? '1' : '0',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (task.hasAttachment)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TaskMateColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TaskMateColors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: TaskMateColors.secondaryContainer.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.description_outlined,
                                size: 24,
                                color: TaskMateColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.attachmentName ?? 'Attached document',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: TaskMateColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Cloud Storage Attachment',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: TaskMateColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 20,
                                color: TaskMateColors.primary,
                              ),
                              onPressed: () => _openAttachment(task.attachmentUrl!),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: TaskMateColors.surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'No files attached to this task.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: TaskMateColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Floating Sticky Action Dock (Bottom Bar)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  decoration: BoxDecoration(
                    color: TaskMateColors.surfaceCard.withValues(alpha: 0.96),
                    border: const Border(
                      top: BorderSide(color: Color(0xFFE2E8E0)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: TaskMateColors.surfaceContainer,
                              foregroundColor: TaskMateColors.primary,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(
                              'Edit',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TaskFormScreen(task: task),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDone
                                  ? TaskMateColors.secondary
                                  : TaskMateColors.primaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(
                              isDone
                                  ? Icons.check_circle_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 18,
                            ),
                            label: Text(
                              isDone ? 'Completed' : 'Mark as Completed',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () => _toggleCompletion(task),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
