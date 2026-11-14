import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_item.dart';
import '../utils/theme.dart';
import '../utils/ui.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  final TaskItem task;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDone = task.isCompleted;
    final overdue = task.isOverdue;

    // Status pill resolution
    String statusLabel;
    Color statusTextColor;
    Color statusBgColor;

    if (isDone) {
      statusLabel = 'Completed';
      statusTextColor = TaskMateColors.statusCompletedText;
      statusBgColor = TaskMateColors.statusCompletedBg;
    } else if (overdue) {
      statusLabel = 'Overdue';
      statusTextColor = TaskMateColors.statusOverdueText;
      statusBgColor = TaskMateColors.statusOverdueBg;
    } else if (task.status == 'In Progress') {
      statusLabel = 'In Progress';
      statusTextColor = TaskMateColors.statusInProgressText;
      statusBgColor = TaskMateColors.statusInProgressBg;
    } else {
      statusLabel = 'Pending';
      statusTextColor = TaskMateColors.statusPendingText;
      statusBgColor = TaskMateColors.statusPendingBg;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDone ? 0.72 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: TaskMateColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: TaskMateColors.outlineVariant,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Checkbox, Title, and Status Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Interactive Checkbox
                      GestureDetector(
                        key: const ValueKey('task_checkbox'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onToggle(!isDone),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(top: 2, right: 10),
                          decoration: BoxDecoration(
                            color: isDone
                                ? TaskMateColors.primary
                                : TaskMateColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDone
                                  ? TaskMateColors.primary
                                  : TaskMateColors.outlineVariant,
                              width: 1.5,
                            ),
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
                      // Title
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: isDone
                                ? TaskMateColors.onSurfaceVariant
                                : TaskMateColors.onSurface,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Description Snippet (if available)
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: TaskMateColors.onSurfaceVariant,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],

                  // Badges: Subject and Category
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (task.subject.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: TaskMateColors.secondaryContainer.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.subject,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: TaskMateColors.onSecondaryContainer,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: TaskMateColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: TaskMateColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Divider & Metadata Row
                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.only(top: 8, left: 32),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFFF1F5F2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Due date
                        Row(
                          children: [
                            Icon(
                              overdue
                                  ? Icons.warning_amber_rounded
                                  : Icons.event_rounded,
                              size: 14,
                              color: overdue
                                  ? TaskMateColors.error
                                  : TaskMateColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              shortDueFormat.format(task.dueDate),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: overdue
                                    ? TaskMateColors.error
                                    : TaskMateColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),

                        // Attachment & Actions
                        Row(
                          children: [
                            if (task.hasAttachment) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: TaskMateColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.attach_file_rounded,
                                      size: 12,
                                      color: TaskMateColors.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'File',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: TaskMateColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (onEdit != null)
                              GestureDetector(
                                onTap: onEdit,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    Icons.edit_note_rounded,
                                    size: 18,
                                    color: TaskMateColors.onSurfaceVariant,
                                  ),
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
      ),
    );
  }
}
