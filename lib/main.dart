import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/main_shell_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'utils/theme.dart';
import 'utils/ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskMateApp());
}

class TaskMateApp extends StatefulWidget {
  const TaskMateApp({super.key});

  @override
  State<TaskMateApp> createState() => _TaskMateAppState();
}

class _TaskMateAppState extends State<TaskMateApp> {
  bool _splashFinished = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskMate',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: TaskMateTheme.lightTheme,
      home: _splashFinished
          ? const AuthGate()
          : SplashScreen(
              onFinished: () {
                setState(() => _splashFinished = true);
              },
            ),
    );
  }
}

/// Shows the dashboard for signed-in users and the login screen otherwise.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: TaskMateColors.background,
            body: Center(
              child: CircularProgressIndicator(color: TaskMateColors.primary),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainShellScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
