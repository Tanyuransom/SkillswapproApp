import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CourseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(course['title'] ?? 'Course Details', style: const TextStyle(fontSize: 16)),
              background: Container(
                color: AppTheme.primaryPurple,
                child: const Icon(Icons.school, size: 100, color: Colors.white24),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Best Seller",
                          style: TextStyle(color: AppTheme.secondaryOrange, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, color: AppTheme.accentYellow, size: 20),
                      const Text(" 4.9 (124 reviews)", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    course['title'] ?? 'Full Stack Development',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    course['description'] ?? 'Master the skills of modern web development with this comprehensive course. Learn frontend, backend, and everything in between.',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text("Modules", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildModuleItem(context, "1", "Introduction to the Skill", "15:00", true),
                  _buildModuleItem(context, "2", "Core Principles & Tools", "45:00", false),
                  _buildModuleItem(context, "3", "Advanced Techniques", "1:20:00", false),
                  _buildModuleItem(context, "4", "Final Capstone Project", "2:00:00", false),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Course content coming soon!"), backgroundColor: AppTheme.primaryPurple),
            );
          },
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text("RESUME LEARNING"),
        ),
      ),
    );
  }

  Widget _buildModuleItem(BuildContext context, String index, String title, String duration, bool isCompleted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isCompleted ? AppTheme.successGreen : Colors.grey.shade300,
            child: Icon(isCompleted ? Icons.check : Icons.play_arrow, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Module $index: $title", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(duration, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
