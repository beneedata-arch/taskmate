import 'dart:async';

/// Standalone notification service for UI mode.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  Future<void> init() async {
    // No-op for standalone UI mode
  }
}
