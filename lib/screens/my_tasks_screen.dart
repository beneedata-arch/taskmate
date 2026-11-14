import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_item.dart';
import '../services/task_service.dart';
import '../utils/theme.dart';
import '../utils/ui.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

enum TaskStatusFilter { all, pending, inProgress, completed }

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  final _tasks = TaskService();
  final _searchCtrl = TextEditingController();
  late final Stream<List<TaskItem>> _stream;

  TaskStatusFilter _statusFilter = TaskStatusFilter.all;
  String? _selectedSubject;
  String _searchQuery = '';
  final Set<String> _hidden = {};

  @override
  void initState() {
    super.initState();
    _stream = _tasks.watchTasks();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TaskItem> _applyFilters(List<TaskItem> list) {
    return list.where((t) {
      if (_hidden.contains(t.id)) return false;

      // Status filter
      if (_statusFilter == TaskStatusFilter.pending) {
        if (t.isCompleted || t.status == 'In Progress') return false;
      } else if (_statusFilter == TaskStatusFilter.inProgress) {
        if (t.isCompleted || t.status != 'In Progress') return false;
      } else if (_statusFilter == TaskStatusFilter.completed) {
        if (!t.isCompleted) return false;
      }

      // Subject filter
      if (_selectedSubject != null && t.subject != _selectedSubject) {
        return false;
      }

      // Search query (title, subject, description)
      if (_searchQuery.isNotEmpty) {
        final title = t.title.toLowerCase();
        final subject = t.subject.toLowerCase();
        final desc = t.description.toLowerCase();
        if (!title.contains(_searchQuery) &&
            !subject.contains(_searchQuery) &&
            !desc.contains(_searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();
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

  void _resetFilters() {
    setState(() {
      _statusFilter = TaskStatusFilter.all;
      _selectedSubject = null;
      _searchCtrl.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
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
          final subjects = allTasks
              .map((t) => t.subject)
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          final totalCount = allTasks.length;
          final completedCount = allTasks.where((t) => t.isCompleted).length;
          final pendingCount =
              allTasks.where((t) => !t.isCompleted && t.status != 'In Progress').length;
          final inProgressCount =
              allTasks.where((t) => !t.isCompleted && t.status == 'In Progress').length;

          final visible = _applyFilters(allTasks);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Task Counter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'My Tasks',
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
                                  color: TaskMateColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  '($totalCount tasks)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: TaskMateColors.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: TaskMateColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.tune_rounded,
                                  size: 14,
                                  color: TaskMateColors.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Due Date',
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
                      const SizedBox(height: 14),

                      // Weekly Milestone Progress Capsule
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: TaskMateColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TaskMateColors.outlineVariant),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 16,
                                      color: TaskMateColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Weekly Milestone',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: TaskMateColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$completedCount of $totalCount completed',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    color: TaskMateColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9999),
                              child: LinearProgressIndicator(
                                value: totalCount == 0
                                    ? 0.0
                                    : (completedCount / totalCount),
                                backgroundColor: TaskMateColors.surfaceContainer,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  TaskMateColors.primary,
                                ),
                                minHeight: 7,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Search Input
                      Container(
                        decoration: BoxDecoration(
                          color: TaskMateColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: TaskMateColors.outlineVariant),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search tasks by title, subject...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: TaskMateColors.onSurfaceVariant,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () => _searchCtrl.clear(),
                                  )
                                : null,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Horizontal Filter Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterPill(
                              label: 'All ($totalCount)',
                              active: _statusFilter == TaskStatusFilter.all,
                              onTap: () {
                                setState(() => _statusFilter = TaskStatusFilter.all);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildFilterPill(
                              label: 'Pending ($pendingCount)',
                              active: _statusFilter == TaskStatusFilter.pending,
                              onTap: () {
                                setState(() => _statusFilter = TaskStatusFilter.pending);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildFilterPill(
                              label: 'In Progress ($inProgressCount)',
                              active: _statusFilter == TaskStatusFilter.inProgress,
                              onTap: () {
                                setState(
                                  () => _statusFilter = TaskStatusFilter.inProgress,
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildFilterPill(
                              label: 'Completed ($completedCount)',
                              active: _statusFilter == TaskStatusFilter.completed,
                              onTap: () {
                                setState(
                                  () => _statusFilter = TaskStatusFilter.completed,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Optional Subject Filter Pills
                      if (subjects.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              Text(
                                'Subject: ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TaskMateColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _buildSubjectPill(
                                label: 'All Courses',
                                selected: _selectedSubject == null,
                                onTap: () => setState(() => _selectedSubject = null),
                              ),
                              ...subjects.map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: _buildSubjectPill(
                                    label: s,
                                    selected: _selectedSubject == s,
                                    onTap: () => setState(() => _selectedSubject = s),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Task List or Empty State
              if (visible.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: TaskMateColors.secondaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.spa_rounded,
                                size: 32,
                                color: TaskMateColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'All clear for now!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: TaskMateColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No tasks match your search or selected filter.\nTake a breath and enjoy the open calendar.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: TaskMateColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: TaskMateColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            onPressed: _resetFilters,
                            child: Text(
                              'Reset Filters',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = visible[index];
                      return Dismissible(
                        key: ValueKey(task.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: TaskMateColors.errorContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: TaskMateColors.error,
                            size: 24,
                          ),
                        ),
                        confirmDismiss: (_) => confirmDialog(
                          context,
                          title: 'Delete task?',
                          message: '"${task.title}" will be permanently deleted.',
                        ),
                        onDismissed: (_) {
                          setState(() => _hidden.add(task.id));
                          _tasks.deleteTask(task).catchError((Object e) {
                            showMessage('Could not delete task: $e');
                          });
                          showMessage('Task deleted');
                        },
                        child: TaskCard(
                          task: task,
                          onTap: () => _openDetail(task),
                          onToggle: (v) => _toggle(task, v),
                          onEdit: () => _openEdit(task),
                        ),
                      );
                    },
                    childCount: visible.length,
                  ),
                ),

              // Micro-interaction Quick Add Prompt Footer
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: TaskMateColors.surfaceContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: TaskMateColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: TaskMateColors.onSurfaceVariant,
                              ),
                              children: const [
                                TextSpan(text: 'Tap the green '),
                                TextSpan(
                                  text: '+ button ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: 'below anytime to log sudden syllabus changes.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? TaskMateColors.primary : TaskMateColors.surfaceContainer,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: TaskMateColors.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : TaskMateColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? TaskMateColors.secondaryContainer
              : TaskMateColors.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected
                ? TaskMateColors.primary
                : TaskMateColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

