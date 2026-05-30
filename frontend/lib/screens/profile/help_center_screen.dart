import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryPurple, Colors.indigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome to SkillSwap Pro!",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Your ultimate platform for exchanging academic skills, courses, and educational video shorts.",
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              "How to use the App",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),

            _buildHelpSection(
              context,
              Icons.school_outlined,
              "As a Student",
              "Learn, engage, and grow your expertise:",
              [
                "Select your Level and Specialty during registration or profile setup to automatically filter recommended courses.",
                "Explore the Discover tab to search and enroll in academic courses related to your field.",
                "Access modules, study resources, PDFs, and lecture videos under each enrolled course.",
                "Send direct messages to your course tutors to ask questions and clear doubts.",
                "Leave honest course reviews to help others choose the best instructors.",
              ],
            ),

            const SizedBox(height: 16),

            _buildHelpSection(
              context,
              Icons.co_present_outlined,
              "As a Tutor",
              "Share your knowledge and mentor students:",
              [
                "Create courses and write custom specialties to help students find your material.",
                "Upload rich course materials like study PDFs and video lessons under course modules.",
                "Upload educational video Shorts (up to 60s) to share quick micro-tips, hacks, or summaries.",
                "Get real-time message inquiries from enrolled students in your Inbox.",
                "Receive instant notifications when students enroll in your courses.",
              ],
            ),

            const SizedBox(height: 16),

            _buildHelpSection(
              context,
              Icons.play_circle_outline,
              "Interactive Features",
              "Unique features that keep you engaged:",
              [
                "Shorts Feed: Slide through bite-sized academic video feeds. Tap a video to pause or resume playback.",
                "Tutors reviews: Check the 'See available tutors' button under any course description to find all other tutors teaching the same subject and read reviews left by other students.",
                "Unread Badge: Spot notifications instantly through the unread badge in your top dashboard bar, linking directly to your Inbox.",
              ],
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                "Version 1.0.1 • SkillSwap Pro Support",
                style: TextStyle(color: isDark ? Colors.white30 : Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    List<String> items,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: AppTheme.primaryPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
