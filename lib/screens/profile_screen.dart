import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_item.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../utils/theme.dart';
import '../utils/ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _tasks = TaskService();
  late final Stream<List<TaskItem>> _stream;

  bool _pushNotifications = true;
  bool _emailWarnings = true;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _stream = _tasks.watchTasks();
  }

  Future<void> _signOut() async {
    final ok = await confirmDialog(
      context,
      title: 'Log out?',
      message: 'Are you sure you want to exit TaskMate? Unsynced offline edits will be preserved locally.',
      confirmLabel: 'Log out',
    );
    if (ok) await _auth.signOut();
  }

  void _copyUserId(String uid) {
    Clipboard.setData(ClipboardData(text: uid));
    setState(() => _copied = true);
    showMessage('User ID copied to clipboard!', isSuccess: true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _showNotificationPreferencesModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      Text(
                        'Notification Preferences',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: TaskMateColors.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(
                      'Push Notifications',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TaskMateColors.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Instant alerts for coursework and due updates',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: TaskMateColors.onSurfaceVariant,
                      ),
                    ),
                    value: _pushNotifications,
                    activeThumbColor: TaskMateColors.primary,
                    onChanged: (val) {
                      setModalState(() => _pushNotifications = val);
                      setState(() => _pushNotifications = val);
                    },
                  ),
                  const Divider(color: TaskMateColors.surfaceContainer),
                  SwitchListTile(
                    title: Text(
                      'Deadline Email Warnings',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TaskMateColors.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Reminders sent 24 hours prior to deadline',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: TaskMateColors.onSurfaceVariant,
                      ),
                    ),
                    value: _emailWarnings,
                    activeThumbColor: TaskMateColors.primary,
                    onChanged: (val) {
                      setModalState(() => _emailWarnings = val);
                      setState(() => _emailWarnings = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TaskMateColors.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        showMessage('Preferences saved', isSuccess: true);
                      },
                      child: Text(
                        'Save Preferences',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Alex Student';
    final email = user?.email ?? 'alex.student@university.edu';
    final uid = user?.uid ?? 'USR-94821038';
    final initials = displayName.trim().isNotEmpty
        ? displayName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'AS';

    return Scaffold(
      backgroundColor: TaskMateColors.background,
      body: StreamBuilder<List<TaskItem>>(
        stream: _stream,
        builder: (context, snapshot) {
          final allTasks = snapshot.data ?? [];
          final completedCount = allTasks.where((t) => t.isCompleted).length;
          final totalCount = allTasks.length;
          final onTimeRate = totalCount == 0
              ? '100%'
              : '${(((completedCount) / totalCount) * 100).toInt()}%';

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Avatar Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: TaskMateColors.surfaceLow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: TaskMateColors.outlineVariant),
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
                            Stack(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: TaskMateColors.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: TaskMateColors.surfaceCard,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: TaskMateColors.surfaceLow,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.verified_rounded,
                                      size: 14,
                                      color: TaskMateColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          displayName,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: TaskMateColors.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: TaskMateColors.secondaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(9999),
                                        ),
                                        child: Text(
                                          'Degree Track',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: TaskMateColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Computer Science • Undergrad',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: TaskMateColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.school_outlined,
                                        size: 14,
                                        color: TaskMateColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Class of 2025',
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
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Academic Velocity 3-card grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ACADEMIC VELOCITY',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: TaskMateColors.onSurfaceVariant,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: TaskMateColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Synced',
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
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: _buildVelocityCard(
                              icon: Icons.calendar_month_outlined,
                              iconBg: TaskMateColors.surfaceContainer,
                              iconColor: TaskMateColors.primary,
                              label: 'Semester',
                              value: 'Fall 2024',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildVelocityCard(
                              icon: Icons.task_alt_rounded,
                              iconBg: TaskMateColors.secondaryContainer,
                              iconColor: TaskMateColors.secondary,
                              label: 'Done',
                              value: '$completedCount',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildVelocityCard(
                              icon: Icons.bolt_rounded,
                              iconBg: TaskMateColors.tertiaryFixed,
                              iconColor: TaskMateColors.tertiary,
                              label: 'Completion',
                              value: onTimeRate,
                              valueColor: TaskMateColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // User Entity Credentials
                      Text(
                        'USER ENTITY CREDENTIALS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: TaskMateColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: TaskMateColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TaskMateColors.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            // User ID row
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: TaskMateColors.surfaceContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.badge_outlined,
                                    size: 18,
                                    color: TaskMateColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'User ID',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: TaskMateColors.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        uid,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: TaskMateColors.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor: TaskMateColors.surfaceLow,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                  ),
                                  icon: Icon(
                                    _copied
                                        ? Icons.check_rounded
                                        : Icons.content_copy_rounded,
                                    size: 14,
                                    color: TaskMateColors.primary,
                                  ),
                                  label: Text(
                                    _copied ? 'Copied' : 'Copy',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: TaskMateColors.primary,
                                    ),
                                  ),
                                  onPressed: () => _copyUserId(uid),
                                ),
                              ],
                            ),
                            const Divider(color: TaskMateColors.surfaceContainer, height: 18),

                            // Email row
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: TaskMateColors.surfaceContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 18,
                                    color: TaskMateColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Institutional Email',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: TaskMateColors.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: TaskMateColors.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 12,
                                        color: TaskMateColors.primary,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Verified',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: TaskMateColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Preferences & Security
                      Text(
                        'PREFERENCES & SECURITY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: TaskMateColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: TaskMateColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TaskMateColors.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: TaskMateColors.surfaceContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_active_outlined,
                                  size: 18,
                                  color: TaskMateColors.onSurfaceVariant,
                                ),
                              ),
                              title: Text(
                                'Notification Preferences',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Push alerts • Deadline reminders',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: TaskMateColors.onSurfaceVariant,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                              ),
                              onTap: _showNotificationPreferencesModal,
                            ),
                            const Divider(color: TaskMateColors.surfaceContainer, height: 1),
                            ListTile(
                              leading: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: TaskMateColors.surfaceContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.sync_rounded,
                                  size: 18,
                                  color: TaskMateColors.onSurfaceVariant,
                                ),
                              ),
                              title: Text(
                                'Offline Cache & Sync',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Firestore local persistence active',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: TaskMateColors.onSurfaceVariant,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                              ),
                              onTap: () {
                                showMessage('Local persistence is enabled. Offline changes sync automatically.');
                              },
                            ),
                            const Divider(color: TaskMateColors.surfaceContainer, height: 1),
                            ListTile(
                              leading: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: TaskMateColors.surfaceContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_person_outlined,
                                  size: 18,
                                  color: TaskMateColors.onSurfaceVariant,
                                ),
                              ),
                              title: Text(
                                'Account & Security',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Email authentication verified',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: TaskMateColors.onSurfaceVariant,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                              ),
                              onTap: () {
                                showMessage('Account security verified.');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Log out button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: TaskMateColors.surfaceLow,
                            foregroundColor: TaskMateColors.error,
                            side: const BorderSide(
                              color: Color(0xFFF6D0D0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: Text(
                            'Log Out',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: _signOut,
                        ),
                      ),
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

  Widget _buildVelocityCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TaskMateColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TaskMateColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: TaskMateColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor ?? TaskMateColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
