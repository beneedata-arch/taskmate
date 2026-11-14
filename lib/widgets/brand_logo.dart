import 'package:flutter/material.dart';
import '../utils/theme.dart';

class TaskMateLogo extends StatelessWidget {
  const TaskMateLogo({
    super.key,
    this.size = 64,
    this.showBadge = true,
  });

  final double size;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF386440),
                  TaskMateColors.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(size * 0.28),
              boxShadow: [
                BoxShadow(
                  color: TaskMateColors.primary.withValues(alpha: 0.25),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.auto_stories_rounded,
                size: size * 0.52,
                color: Colors.white,
              ),
            ),
          ),
          if (showBadge)
            Positioned(
              right: -size * 0.04,
              bottom: -size * 0.04,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: TaskMateColors.secondaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.eco_rounded,
                    size: size * 0.18,
                    color: TaskMateColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

