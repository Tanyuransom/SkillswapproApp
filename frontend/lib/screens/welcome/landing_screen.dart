import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

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
