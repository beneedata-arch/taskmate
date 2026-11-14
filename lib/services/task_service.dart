import 'dart:async';

import '../models/task_item.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// In-memory mock task repository for UI preview and standalone use.
class TaskService {
  TaskService({
    StorageService? storage,
  }) : _storage = storage ?? StorageService();

  final StorageService _storage;

  static final List<TaskItem> _tasks = _initialTasks();
  static final StreamController<List<TaskItem>> _streamController =
      StreamController<List<TaskItem>>.broadcast();

  static List<TaskItem> _initialTasks() {
    final now = DateTime.now();
    return [
      TaskItem(
        id: 'tsk_1',
        userId: 'USR-94821038',
        title: 'Mobile App Project Submission',
        description: 'Complete Stitch UI integration, add responsive layout and prepare APK demo.',
        subject: 'Mobile Development',
        category: 'Project',
        status: 'In Progress',
        dueDate: now.add(const Duration(hours: 18)),
        isCompleted: false,
        createdAt: now.subtract(const Duration(days: 3)),
        attachmentName: 'Project_Specification.pdf',
        attachmentUrl: 'https://example.com/spec.pdf',
      ),
      TaskItem(
        id: 'tsk_2',
        userId: 'USR-94821038',
        title: 'Database Schema 3NF Normalization',
        description: 'Normalize relations up to BCNF and write SQL migration script.',
        subject: 'Database Systems',
        category: 'Assignment',
        status: 'Pending',
        dueDate: now.add(const Duration(days: 2)),
        isCompleted: false,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      TaskItem(
        id: 'tsk_3',
        userId: 'USR-94821038',
        title: 'Linear Algebra Quiz 4 Preparation',
        description: 'Eigenvalues, eigenvectors, and matrix diagonalization review.',
        subject: 'Mathematics',
        category: 'Quiz',
        status: 'Pending',
        dueDate: now.add(const Duration(days: 4)),
        isCompleted: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      TaskItem(
        id: 'tsk_4',
        userId: 'USR-94821038',
        title: 'Computer Networks Packet Trace Lab',
        description: 'Wireshark TCP handshake analysis and report.',
        subject: 'Networking',
        category: 'Assignment',
        status: 'Pending',
        dueDate: now.subtract(const Duration(days: 1)), // Overdue
        isCompleted: false,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      TaskItem(
        id: 'tsk_5',
        userId: 'USR-94821038',
        title: 'Software Engineering Term Paper',
        description: 'Agile vs Waterfall comparative case study.',
        subject: 'Software Engineering',
        category: 'Project',
        status: 'Completed',
        dueDate: now.subtract(const Duration(days: 2)),
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }

  String newId() => 'tsk_${DateTime.now().millisecondsSinceEpoch}';

  String get currentUserId => AuthService.instance.currentUser?.uid ?? 'USR-94821038';

  Stream<List<TaskItem>> watchTasks() async* {
    yield _sortedTasks();
    yield* _streamController.stream.map((_) => _sortedTasks());
  }

  Stream<TaskItem?> watchTask(String id) async* {
    yield _findTask(id);
    yield* _streamController.stream.map((_) => _findTask(id));
  }

  List<TaskItem> _sortedTasks() {
    final list = List<TaskItem>.from(_tasks);
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  TaskItem? _findTask(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  void _notify() {
    _streamController.add(_sortedTasks());
  }

  Future<void> addTask(TaskItem task) async {
    _tasks.removeWhere((t) => t.id == task.id);
    _tasks.add(task);
    _notify();
  }

  Future<void> updateTask(TaskItem task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
    } else {
      _tasks.add(task);
    }
    _notify();
  }

  Future<void> setCompleted(String id, bool completed) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final existing = _tasks[index];
      _tasks[index] = existing.copyWith(
        isCompleted: completed,
        status: completed ? 'Completed' : 'Pending',
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  Future<void> setStatus(String id, String status) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final existing = _tasks[index];
      final completed = status == 'Completed';
      _tasks[index] = existing.copyWith(
        status: status,
        isCompleted: completed,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  Future<void> deleteTask(TaskItem task) async {
    _tasks.removeWhere((t) => t.id == task.id);
    if (task.attachmentPath != null) {
      unawaited(_storage.delete(task.attachmentPath!).catchError((_) {}));
    }
    _notify();
  }
}
