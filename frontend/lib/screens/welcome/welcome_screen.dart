import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../models/user_role.dart';
import '../../utils/auth_helper.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with GoogleSignInMixin {
  bool _isLoading = false;

  @override
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

  Widget _buildChoiceCard(BuildContext context, String title, IconData icon, String role) {
    return InkWell(
      onTap: () async {
        final choice = await showModalBottomSheet<String>(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Join as ${role.toUpperCase()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.g_mobiledata, size: 40, color: AppTheme.primaryPurple),
                  title: const Text("Continue with Google"),
                  onTap: () => Navigator.pop(context, 'google'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded, size: 30, color: AppTheme.secondaryOrange),
                  title: const Text("Join manually with Email"),
                  onTap: () => Navigator.pop(context, 'manual'),
                ),
              ],
            ),
          ),
        );

        if (choice == 'google') {
          handleGoogleSignIn(initialRole: role);
        } else if (choice == 'manual') {
          Navigator.pushNamed(context, '/signup', arguments: {'role': role});
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryPurple, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 12,
                color: AppTheme.primaryPurple,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryPurple,
                  AppTheme.primaryPurple.withValues(alpha: 0.8),
                  isDark ? Colors.black : Colors.white,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60), // Replaced Spacer with fixed top padding for scrollable view
                  
                  // App Icon / Logo Placeholder
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 48,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    "Welcome to\nSkillProf",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 48,
                      height: 1.1,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    "The ultimate P2P skill exchange platform where experts teach and learners thrive.",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.9),
                      fontSize: 18,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Feature Highlights (from previously skipped onboarding)
                  _buildFeatureItem(
                    context, 
                    Icons.search_rounded, 
                    "Discover Skills", 
                    "Find the best tutors for any course."
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    context, 
                    Icons.school_rounded, 
                    "Share Expertise", 
                    "Become a tutor and earn on your schedule."
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    context, 
                    Icons.verified_user_rounded, 
                    "Secure & Verified", 
                    "Safe mobile money and skill verification."
                  ),
                  
                  const SizedBox(height: 48),
                  
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: Colors.white))
                  else ...[
                    // CHOICE BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: _buildChoiceCard(
                            context,
                            "JOIN AS STUDENT",
                            Icons.school_outlined,
                            "student",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildChoiceCard(
                            context,
                            "JOIN AS TUTOR",
                            Icons.workspace_premium_outlined,
                            "tutor",
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white30)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("ALREADY HAVE AN ACCOUNT?", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                        Expanded(child: Divider(color: Colors.white30)),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    // MANUAL SIGN IN BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, '/signin'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.all(20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "SIGN IN MANUALLY",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                        label: const Text("RESET APP STATE", style: TextStyle(fontSize: 12, color: Colors.white70)),
                        onPressed: () {
                          SessionService().clearSession();
                          Navigator.pushReplacementNamed(context, '/welcome');
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha:0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
