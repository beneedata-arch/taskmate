import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';
import '../utils/ui.dart';
import '../widgets/labeled_dropdown.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

enum StatusFilter { all, pending, completed }

/// Dashboard: counts, search, filters and the list of tasks.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tasks = TaskService();
  final _auth = AuthService();
  final _searchCtrl = TextEditingController();
  late final Stream<List<TaskItem>> _stream;

  StatusFilter _status = StatusFilter.all;
  String? _subject;
  String? _category;
  String _query = '';

  /// Tasks swiped away but not yet removed from the Firestore snapshot.
  final Set<String> _hidden = {};

  @override
  void initState() {
    super.initState();
    _stream = _tasks.watchTasks();
    unawaited(NotificationService.instance.init());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TaskItem> _applyFilters(List<TaskItem> tasks) {
    final q = _query.trim().toLowerCase();
    final result = tasks.where((t) {
      if (_status == StatusFilter.pending && t.isCompleted) return false;
      if (_status == StatusFilter.completed && !t.isCompleted) return false;
      if (_subject != null && t.subject != _subject) return false;
      if (_category != null && t.category != _category) return false;
      if (q.isNotEmpty && !t.title.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
    // Pending tasks first (soonest deadline first), completed tasks last.
    result.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return a.dueDate.compareTo(b.dueDate);
    });
    return result;
  }

  void _toggle(TaskItem task, bool completed) {
    _tasks.setCompleted(task.id, completed).catchError((Object e) {
      showMessage('Could not update task: $e');
    });
  }

  Future<void> _signOut() async {
    final ok = await confirmDialog(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to see your tasks.',
      confirmLabel: 'Log out',
    );
    if (ok) await _auth.signOut();
  }

  void _openForm() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TaskFormScreen()),
    );
  }

  void _openDetail(TaskItem task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailScreen(taskId: task.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskMate'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: StreamBuilder<List<TaskItem>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load your tasks.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all =
              snapshot.data!.where((t) => !_hidden.contains(t.id)).toList();
          final subjects = all
              .map((t) => t.subject)
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          final visible = _applyFilters(all);

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: 1 + (visible.isEmpty ? 1 : visible.length),
            itemBuilder: (context, index) {
              if (index == 0) return _buildHeader(context, all, subjects);
              if (visible.isEmpty) return _buildEmpty(context, all.isEmpty);
              return _buildTaskItem(context, visible[index - 1]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskItem task) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
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
        onToggle: (value) => _toggle(task, value),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool noTasksAtAll) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          Icon(
            noTasksAtAll ? Icons.task_alt : Icons.search_off,
            size: 64,
            color: scheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            noTasksAtAll
                ? 'No tasks yet.\nTap "New task" to add your first one.'
                : 'No tasks match your search or filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<TaskItem> all,
    List<String> subjects,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final total = all.length;
    final done = all.where((t) => t.isCompleted).length;
    final pending = total - done;
    final overdue = all.where((t) => t.isOverdue).length;
    final dueSoon =
        all.where((t) => t.isDueWithin(const Duration(hours: 24))).length;

    final user = FirebaseAuth.instance.currentUser;
    final display = user?.displayName?.trim();
    final name = (display != null && display.isNotEmpty)
        ? display
        : (user?.email ?? 'student');

    final subjectValue = subjects.contains(_subject) ? _subject : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $name',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatTile(label: 'Pending', value: pending, color: scheme.primary),
              const SizedBox(width: 8),
              _StatTile(label: 'Completed', value: done, color: Colors.green),
              const SizedBox(width: 8),
              _StatTile(label: 'Overdue', value: overdue, color: scheme.error),
            ],
          ),
          if (dueSoon > 0 || overdue > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_outlined,
                      color: scheme.onTertiaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      [
                        if (dueSoon > 0)
                          '$dueSoon task${dueSoon == 1 ? '' : 's'} due within 24 hours',
                        if (overdue > 0) '$overdue overdue',
                      ].join(' • '),
                      style: TextStyle(color: scheme.onTertiaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by title',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<StatusFilter>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: StatusFilter.all, label: Text('All')),
                ButtonSegment(
                    value: StatusFilter.pending, label: Text('Pending')),
                ButtonSegment(
                    value: StatusFilter.completed, label: Text('Completed')),
              ],
              selected: {_status},
              onSelectionChanged: (selection) =>
                  setState(() => _status = selection.first),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LabeledDropdown<String?>(
                  label: 'Subject',
                  value: subjectValue,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All subjects'),
                    ),
                    for (final s in subjects)
                      DropdownMenuItem<String?>(
                        value: s,
                        child: Text(s, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setState(() => _subject = value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LabeledDropdown<String?>(
                  label: 'Category',
                  value: _category,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All categories'),
                    ),
                    for (final c in kCategories)
                      DropdownMenuItem<String?>(value: c, child: Text(c)),
                  ],
                  onChanged: (value) => setState(() => _category = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
