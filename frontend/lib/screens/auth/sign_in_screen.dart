import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_role.dart';
import '../../services/session_service.dart';
import '../../services/api_service.dart';
import '../../utils/auth_helper.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with GoogleSignInMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    final emailInput = _emailController.text.trim().toLowerCase();
    
    // Admin back-door for initial management tasks
    if (emailInput == 'admin@skillprof.com') {
      await SessionService().saveSession(
        userId: 'admin-1',
        fullName: 'System Administrator',
        token: 'admin-token',
        role: UserRole.admin,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    if (emailInput.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter credentials')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.login(
        email: emailInput,
        password: _passwordController.text,
      );

      // Extract role from response
      final roleStr = response['user']['role'] as String;
      UserRole role = UserRole.student;
      if (roleStr == 'tutor') role = UserRole.tutor;
      if (roleStr == 'admin') role = UserRole.admin;

      await SessionService().saveSession(
        userId: response['user']['id'],
        fullName: response['user']['fullName'] ?? 'User',
        token: response['token'] ?? '',
        avatarUrl: response['user']['avatarUrl'],
        role: role,
      );
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.lock_outline, size: 80, color: AppTheme.primaryPurple),
              const SizedBox(height: 32),
              Text(
                "Welcome Back",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.primaryPurple,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to continue learning",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.primaryPurple,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: const Text("Forgot Password?", style: TextStyle(color: AppTheme.primaryPurple)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("SIGN IN"),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                   Expanded(child: Divider()),
                   Padding(
                     padding: EdgeInsets.symmetric(horizontal: 16),
                     child: Text("OR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                   ),
                   Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: isGoogleLoading ? null : () => handleGoogleSignIn(),
                icon: isGoogleLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.g_mobiledata, size: 30, color: AppTheme.primaryPurple),
                label: const Text("Continue with Google"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.primaryPurple),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text("Don't have an account?", style: TextStyle(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text("Sign Up", style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
