import 'dart:async';

/// Student user representation for UI view.
class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
  });

  final String uid;
  final String? email;
  final String? displayName;
}

/// Compatibility alias so any existing User references work seamlessly.
typedef User = AppUser;

/// Compatibility shim for FirebaseAuth.instance so screens calling
/// FirebaseAuth.instance.currentUser continue to work without Firebase.
class FirebaseAuth {
  FirebaseAuth._();
  static final FirebaseAuth instance = FirebaseAuth._();

  AppUser? get currentUser => AuthService.instance.currentUser;
  Stream<AppUser?> authStateChanges() => AuthService.instance.authStateChanges();
}

/// Authentication service for the standalone UI mode.
class AuthService {
  AuthService();

  static final AuthService instance = AuthService();

  static AppUser? _currentUser = const AppUser(
    uid: 'USR-94821038',
    email: 'alex.student@university.edu',
    displayName: 'Alex Student',
  );

  static final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();

  AppUser? get currentUser => _currentUser;

  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _authController.stream;
  }

  Future<void> signIn({required String email, required String password}) async {
    final cleanEmail = email.trim().isEmpty ? 'alex.student@university.edu' : email.trim();
    final name = cleanEmail.contains('@')
        ? cleanEmail.split('@').first
        : 'Student';
    final displayName = name[0].toUpperCase() + (name.length > 1 ? name.substring(1) : '');

    _currentUser = AppUser(
      uid: 'USR-94821038',
      email: cleanEmail,
      displayName: displayName,
    );
    _authController.add(_currentUser);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim().isEmpty ? 'Alex Student' : name.trim();
    final cleanEmail = email.trim().isEmpty ? 'alex.student@university.edu' : email.trim();

    _currentUser = AppUser(
      uid: 'USR-94821038',
      email: cleanEmail,
      displayName: cleanName,
    );
    _authController.add(_currentUser);
  }

  Future<void> sendPasswordReset(String email) async {
    // Simulated password reset
  }

  Future<void> signOut() async {
    _currentUser = null;
    _authController.add(null);
  }

  static String friendlyError(Object error) {
    return error.toString();
  }
}
