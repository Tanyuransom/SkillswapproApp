import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../models/user_role.dart';
import '../theme/app_theme.dart';

mixin GoogleSignInMixin<T extends StatefulWidget> on State<T> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '103593137684-3uitoc6guj875oiks3r89s5i0kbp19oh.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  bool isGoogleLoading = false;

  Future<void> handleGoogleSignIn({String? initialRole}) async {
    setState(() => isGoogleLoading = true);
    try {
      // Force account selection by signing out previous account if any
      await _googleSignIn.signOut();
      
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => isGoogleLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) throw Exception("Could not get Google ID Token");

      // Try logging in with the token and pre-selected role
      final result = await ApiService.googleLogin(idToken: idToken, role: initialRole);

      if (result['requireRole'] == true) {
        if (!mounted) return;
        final selectedRole = await showRoleSelectionModal(context);
        if (selectedRole != null) {
          final finalResult = await ApiService.googleLogin(idToken: idToken, role: selectedRole);
          await handleAuthSuccess(finalResult);
        }
      } else {
        await handleAuthSuccess(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-In Error: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => isGoogleLoading = false);
    }
  }

  Future<void> handleAuthSuccess(Map<String, dynamic> result) async {
    final session = SessionService();
    final userData = result['user'];
    
    await session.saveSession(
      token: result['token'],
      userId: userData['id'],
      fullName: userData['fullName'],
      avatarUrl: userData['avatarUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().contains(userData['role'] ?? 'student'),
        orElse: () => UserRole.student,
      ),
    );
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<String?> showRoleSelectionModal(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "One last step!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "How would you like to use SkillProf?",
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildRoleCard(
                    context,
                    "Student",
                    Icons.school_outlined,
                    "student",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRoleCard(
                    context,
                    "Tutor",
                    Icons.workspace_premium_outlined,
                    "tutor",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String title, IconData icon, String role) {
    return InkWell(
      onTap: () => Navigator.pop(context, role),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryPurple, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryPurple, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
