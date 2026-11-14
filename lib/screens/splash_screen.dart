import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/theme.dart';
import '../widgets/brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.28;
  int _stageIndex = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _stages = [
    {'pct': 0.28, 'text': 'Preparing your desk...'},
    {'pct': 0.55, 'text': 'Synchronizing semester schedule...'},
    {'pct': 0.85, 'text': 'Organizing priority milestones...'},
    {'pct': 1.00, 'text': 'Welcome back!'},
  ];

  @override
  void initState() {
    super.initState();
    _startProgression();
  }

  void _startProgression() {
    _timer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (!mounted) return;
      if (_stageIndex < _stages.length - 1) {
        setState(() {
          _stageIndex++;
          _progress = _stages[_stageIndex]['pct'] as double;
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) widget.onFinished();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStage = _stages[_stageIndex];
    final stageText = currentStage['text'] as String;
    final pctText = '${(_progress * 100).toInt()}%';

    return Scaffold(
      backgroundColor: TaskMateColors.background,
      body: Stack(
        children: [
          // Ambient organic glowing light elements
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TaskMateColors.secondaryContainer.withValues(alpha: 0.4),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TaskMateColors.primaryFixed.withValues(alpha: 0.3),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Brand Icon
                    const TaskMateLogo(size: 88, showBadge: true),
                    const SizedBox(height: 28),

                    // "Focus & Flow" pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: TaskMateColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.eco_rounded,
                            size: 15,
                            color: TaskMateColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'FOCUS & FLOW',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: TaskMateColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // App Name
                    Text(
                      'TaskMate',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        color: TaskMateColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Your tasks, organized.\nYour deadlines, managed.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: TaskMateColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Feature Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeaturePill(Icons.school_outlined, 'Syllabus Sync'),
                        const SizedBox(width: 10),
                        _buildFeaturePill(Icons.timer_outlined, 'Gentle Pacing'),
                      ],
                    ),

                    const Spacer(),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        height: 6,
                        width: 260,
                        color: TaskMateColors.surfaceContainer,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: TaskMateColors.primary,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Stage label and percent
                    SizedBox(
                      width: 260,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                              const SizedBox(width: 6),
                              Text(
                                stageText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: TaskMateColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            pctText,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: TaskMateColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Academic encryption badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 14,
                          color: TaskMateColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Encrypted academic workspace',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: TaskMateColors.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: TaskMateColors.surfaceContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: TaskMateColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: TaskMateColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TaskMateColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

