import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/notification_service.dart';
import '../utils/theme.dart';
import '../widgets/brand_logo.dart';
import 'home_dashboard_screen.dart';
import 'my_tasks_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'task_form_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.init();
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _openAddTask() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TaskFormScreen(),
      ),
    );
  }

  String _getSubtitle() {
    switch (_currentIndex) {
      case 0:
        return 'Home Dashboard';
      case 1:
        return 'My Tasks';
      case 2:
        return 'Alerts';
      case 3:
        return 'Profile';
      default:
        return 'Student Focus Space';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final initials = (user?.displayName?.isNotEmpty == true)
        ? user!.displayName!.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'S';

    return Scaffold(
      backgroundColor: TaskMateColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: TaskMateColors.surface.withValues(alpha: 0.95),
            border: const Border(
              bottom: BorderSide(
                color: Color(0xFFE2E8E0),
                width: 0.8,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Brand & Subtitle
                  Row(
                    children: [
                      const TaskMateLogo(size: 32, showBadge: false),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'TaskMate',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: TaskMateColors.primary,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            _getSubtitle(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: TaskMateColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Fall Term Pill & User Avatar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: TaskMateColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: TaskMateColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Fall Term',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: TaskMateColors.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _onTabSelected(3),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: TaskMateColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeDashboardScreen(
            onNavigateToTasks: () => _onTabSelected(1),
          ),
          const MyTasksScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: SizedBox(
          width: 54,
          height: 54,
          child: FloatingActionButton(
            backgroundColor: TaskMateColors.primaryContainer,
            elevation: 4,
            shape: const CircleBorder(),
            onPressed: _openAddTask,
            child: const Icon(
              Icons.add_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: TaskMateColors.surfaceCard.withValues(alpha: 0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.check_box_outlined,
                  label: 'Tasks',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.notifications_none_rounded,
                  label: 'Alerts',
                  showBadge: true,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.account_circle_outlined,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    bool showBadge = false,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? TaskMateColors.primary : TaskMateColors.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 23, color: color),
                if (showBadge)
                  Positioned(
                    top: -1,
                    right: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: TaskMateColors.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

