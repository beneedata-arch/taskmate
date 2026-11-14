/// One academic task (assignment, project, quiz, ...) owned by a student.
class TaskItem {
  const TaskItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.dueDate,
    this.description = '',
    this.subject = '',
    this.category = 'Assignment',
    this.status = 'Pending',
    this.isCompleted = false,
    this.createdAt,
    this.updatedAt,
    this.attachmentUrl,
    this.attachmentPath,
    this.attachmentName,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final String subject;
  final String category;
  final String status;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? attachmentUrl;
  final String? attachmentPath;
  final String? attachmentName;

  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  bool get isOverdue => !isCompleted && dueDate.isBefore(DateTime.now());

  bool isDueWithin(Duration window) {
    final now = DateTime.now();
    return !isCompleted &&
        dueDate.isAfter(now) &&
        dueDate.isBefore(now.add(window));
  }

  factory TaskItem.fromMap(String id, Map<String, dynamic> data) {
    DateTime? toDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return null;
    }

    final completed = data['isCompleted'] == true;
    final statusStr = data['status']?.toString() ?? (completed ? 'Completed' : 'Pending');

    return TaskItem(
      id: id,
      userId: data['userId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      subject: data['subject']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Assignment',
      status: completed ? 'Completed' : statusStr,
      dueDate: toDate(data['dueDate']) ?? DateTime.now(),
      isCompleted: completed,
      createdAt: toDate(data['createdAt']),
      updatedAt: toDate(data['updatedAt']),
      attachmentUrl: data['attachmentUrl'] as String?,
      attachmentPath: data['attachmentPath'] as String?,
      attachmentName: data['attachmentName'] as String?,
    );
  }

  TaskItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? subject,
    String? category,
    String? status,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? attachmentUrl,
    String? attachmentPath,
    String? attachmentName,
  }) {
    return TaskItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      attachmentName: attachmentName ?? this.attachmentName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'subject': subject,
      'category': category,
      'status': isCompleted ? 'Completed' : status,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'attachmentUrl': attachmentUrl,
      'attachmentPath': attachmentPath,
      'attachmentName': attachmentName,
      'reminderSent': false,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();
}
