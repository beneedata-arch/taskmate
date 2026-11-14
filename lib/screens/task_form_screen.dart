import 'dart:io';

import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_item.dart';
import '../services/storage_service.dart';
import '../services/task_service.dart';
import '../utils/theme.dart';
import '../utils/ui.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final TaskItem? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _tasks = TaskService();
  final _storage = StorageService();

  String _category = kCategories.first;
  String _status = 'Pending';
  late DateTime _due;
  bool _saving = false;

  // Attachment existing on the task
  String? _url;
  String? _path;
  String? _name;

  // Newly picked file
  PlatformFile? _picked;

  bool get _isEditing => widget.task != null;

  final List<String> _courseSuggestions = [
    'CS 301 - Database Systems',
    'SWE 410 - Mobile Dev',
    'SEC 402 - Cyber Security',
    'MATH 220 - Applied Algebra',
    'BIO 105 - Cellular Biology',
    'ENG 204 - Academic Rhetoric',
  ];

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleCtrl.text = task.title;
      _descCtrl.text = task.description;
      _subjectCtrl.text = task.subject;
      _category = kCategories.contains(task.category)
          ? task.category
          : kCategories.first;
      _status = task.isCompleted ? 'Completed' : task.status;
      _due = task.dueDate;
      _url = task.attachmentUrl;
      _path = task.attachmentPath;
      _name = task.attachmentName;
    } else {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _due = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: TaskMateColors.primary,
              onPrimary: Colors.white,
              surface: TaskMateColors.surfaceCard,
              onSurface: TaskMateColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: TaskMateColors.primary,
              onPrimary: Colors.white,
              surface: TaskMateColors.surfaceCard,
              onSurface: TaskMateColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null || !mounted) return;

    setState(() {
      _due = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg', 'txt'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      if (file.size > 25 * 1024 * 1024) {
        showMessage('File is larger than 25 MB.');
        return;
      }

      setState(() => _picked = file);
    } catch (e) {
      showMessage('Could not pick file: $e');
    }
  }

  void _removeAttachment() {
    setState(() {
      _picked = null;
      _url = null;
      _path = null;
      _name = null;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final taskId = widget.task?.id ?? _tasks.newId();
      String? attachmentUrl = _url;
      String? attachmentPath = _path;
      String? attachmentName = _name;

      if (_picked != null && _picked!.path != null) {
        final uploaded = await _storage.upload(
          taskId: taskId,
          file: File(_picked!.path!),
          fileName: _picked!.name,
        );
        attachmentUrl = uploaded.url;
        attachmentPath = uploaded.path;
        attachmentName = uploaded.name;
      }

      final item = TaskItem(
        id: taskId,
        userId: _tasks.currentUserId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        subject: _subjectCtrl.text.trim(),
        category: _category,
        status: _status,
        dueDate: _due,
        isCompleted: _status == 'Completed',
        attachmentUrl: attachmentUrl,
        attachmentPath: attachmentPath,
        attachmentName: attachmentName,
      );

      if (_isEditing) {
        await _tasks.updateTask(item);
        showMessage('Task updated!', isSuccess: true);
      } else {
        await _tasks.addTask(item);
        showMessage('Task created successfully!', isSuccess: true);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      showMessage('Could not save task: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final studentName = user?.displayName ?? 'Emma Keller';
    final taskIdPreview = widget.task?.id.substring(0, 6).toUpperCase() ?? 'TSK-NEW';

    return Scaffold(
      backgroundColor: TaskMateColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Task' : 'Create Task',
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
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ambient Student & Task Meta Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: TaskMateColors.surfaceLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TaskMateColors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: TaskMateColors.secondaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                studentName.isNotEmpty
                                    ? studentName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
                                    : 'ST',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: TaskMateColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ASSIGNED STUDENT',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: TaskMateColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                studentName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: TaskMateColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'ENTITY ID',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: TaskMateColors.onSurfaceVariant,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: TaskMateColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#$taskIdPreview',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: TaskMateColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title & Academic Course Block
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: TaskMateColors.surfaceCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: TaskMateColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Input
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Task Title',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TaskMateColors.onSurface,
                                ),
                              ),
                              const Text(
                                ' *',
                                style: TextStyle(color: TaskMateColors.error),
                              ),
                            ],
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _titleCtrl,
                            builder: (context, val, _) {
                              return Text(
                                '${val.text.length}/80',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: TaskMateColors.outline,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleCtrl,
                        maxLength: 80,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Database Systems Assignment',
                          counterText: '',
                        ),
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return 'Please enter a task title.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Subject / Course Module
                      Row(
                        children: [
                          Text(
                            'Subject / Course Module',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TaskMateColors.onSurface,
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(color: TaskMateColors.error),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _subjectCtrl,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'e.g. CS 301 - Database Systems',
                          prefixIcon: Icon(Icons.school_outlined, size: 20),
                        ),
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return 'Please enter a course or subject.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Suggestion Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _courseSuggestions.map((course) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(
                                  course.split(' - ').first,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: TaskMateColors.surfaceContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                onPressed: () {
                                  setState(() => _subjectCtrl.text = course);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Pill Selector
                      Text(
                        'Category',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TaskMateColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kCategories.map((cat) {
                          final isSelected = _category == cat;
                          return ChoiceChip(
                            label: Text(
                              cat,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : TaskMateColors.onSurfaceVariant,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: TaskMateColors.primary,
                            backgroundColor: TaskMateColors.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _category = cat);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Timeline & Status Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: TaskMateColors.surfaceCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: TaskMateColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Due Date & Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Due Date & Time',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TaskMateColors.onSurface,
                                ),
                              ),
                              const Text(
                                ' *',
                                style: TextStyle(color: TaskMateColors.error),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.event_available_rounded,
                                size: 14,
                                color: TaskMateColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Fall Term',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: TaskMateColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDue,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: TaskMateColors.surfaceLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: TaskMateColors.secondary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                dueFormat.format(_due),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: TaskMateColors.onSurface,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.edit_calendar_rounded,
                                size: 18,
                                color: TaskMateColors.outline,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Segmented Control
                      Text(
                        'Status',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TaskMateColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: TaskMateColors.surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: kStatuses.map((st) {
                            final isSelected = _status == st;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _status = st),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? TaskMateColors.surfaceCard
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      st,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? TaskMateColors.primary
                                            : TaskMateColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description Textarea
                      Text(
                        'Description & Rubric Notes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TaskMateColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 4,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText:
                              'Enter detailed task instructions, rubric notes, team members or lecture references...',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Attachment Section
                Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.attach_file_rounded,
                                size: 18,
                                color: TaskMateColors.secondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Task Attachments',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: TaskMateColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: TaskMateColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              (_picked != null || _name != null)
                                  ? '1 File'
                                  : '0 Files',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: TaskMateColors.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Upload / Drop Zone
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: TaskMateColors.surfaceLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: TaskMateColors.outlineVariant,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: TaskMateColors.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 22,
                                  color: TaskMateColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to browse or drop items',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TaskMateColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'PDF, DOCX, PNG up to 25MB',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: TaskMateColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Attachment Preview
                      if (_picked != null || _name != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: TaskMateColors.surfaceLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: TaskMateColors.surfaceContainerHigh,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  size: 20,
                                  color: TaskMateColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _picked?.name ?? _name ?? 'File',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _picked != null
                                          ? formatFileSize(_picked!.size)
                                          : 'Uploaded file',
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
                                  Icons.close_rounded,
                                  size: 18,
                                  color: TaskMateColors.outline,
                                ),
                                onPressed: _removeAttachment,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Form Action Buttons
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TaskMateColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isEditing ? 'Save Changes' : 'Save Task',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: 46,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TaskMateColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
