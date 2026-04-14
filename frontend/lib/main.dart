import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/main_shell.dart';
import 'screens/home/notifications_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize persistence
  final session = SessionService();
  await session.init();
  
  runApp(const SkillSwapApp());
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionService();
    
    return MaterialApp(
      title: 'SkillProf',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      // If already logged in, go straight to home
      initialRoute: session.isLoggedIn ? '/home' : '/welcome',
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          return MaterialPageRoute(
            builder: (context) {
              if (session.isAdmin) {
                return const AdminShell();
              }
              return const MainShell();
            },
          );
        }
        return null;
      },
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}
