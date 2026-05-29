import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppVersion();
    });
  }

  Future<void> _checkAppVersion() async {
    const int currentVersionCode = 1;
    try {
      final latest = await ApiService.getLatestAppVersion();
      final serverVersionCode = latest['versionCode'] as int? ?? 1;
      final serverVersionName = latest['versionName'] as String? ?? '1.0.0';
      final downloadUrl = latest['url'] as String? ?? '';

      if (serverVersionCode > currentVersionCode && mounted) {
        _showUpdateDialog(serverVersionName, downloadUrl);
      }
    } catch (e) {
      // Silent on startup failure to prevent locking the app if offline
    }
  }

  void _showUpdateDialog(String versionName, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.system_update_rounded, color: AppTheme.primaryPurple, size: 28),
            SizedBox(width: 12),
            Text("Update Available", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "A new version ($versionName) of SkillProf is available. Update now to access the latest features and fixes.",
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("LATER", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse(downloadUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("UPDATE NOW", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        
                        // App Icon
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
                            Icons.school_rounded,
                            size: 48,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Text(
                          "Master Any Skill,\nAnywhere.",
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 42,
                            height: 1.1,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          "SkillSwap Pro is the ultimate peer-to-peer ecosystem designed to connect eager learners with experienced professionals.",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        _buildDetailItem(
                          context, 
                          Icons.ondemand_video_rounded, 
                          "Learn via Shorts", 
                          "Scroll through micro-learning 'Shorts' created by real tutors to instantly grasp new concepts before committing to a full course."
                        ),
                        const SizedBox(height: 16),
                        _buildDetailItem(
                          context, 
                          Icons.chat_bubble_outline_rounded, 
                          "Direct Mentorship", 
                          "Connect directly with your tutors through our real-time messaging platform. Get immediate feedback, ask questions, and collaborate."
                        ),
                        const SizedBox(height: 16),
                        _buildDetailItem(
                          context, 
                          Icons.monetization_on_outlined, 
                          "Earn as a Tutor", 
                          "Share your expertise with the world. Upload courses, manage your students via the Command Center, and get paid directly."
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // Get Started Button
                Container(
                  padding: const EdgeInsets.all(32.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -10),
                      )
                    ]
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to the Welcome screen where they actually authenticate/choose role
                      Navigator.pushNamed(context, '/welcome');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      "GET STARTED WITH US",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
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
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
