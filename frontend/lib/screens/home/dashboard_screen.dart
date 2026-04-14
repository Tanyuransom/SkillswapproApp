import 'package:flutter/material.dart';
import 'package:skill_swap_pro/services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../services/session_service.dart';
import '../../utils/url_helper.dart';
import '../category/category_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _trendingCourses = [];
  List<dynamic> _shorts = [];
  bool _isLoading = true;
  bool _isLoadingShorts = true;
  List<dynamic> _notifications = [];
  final session = SessionService();

  @override
  void initState() {
    super.initState();
    _refreshSession();
    _fetchTrending();
    _fetchShorts();
  }

  Future<void> _refreshSession() async {
    await session.init();
    _fetchNotifications();
    if (mounted) setState(() {});
  }

  void _fetchNotifications() async {
    try {
      if (session.userId != null) {
        final data = await ApiService.getNotifications(session.userId!);
        if (mounted) setState(() => _notifications = data);
      }
    } catch (e) { /* silent */ }
  }

  void _fetchTrending() async {
    try {
      final courses = await ApiService.getCourses();
      if (mounted) {
        setState(() {
          _trendingCourses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fetchShorts() async {
    try {
      final shorts = await ApiService.getShorts();
      if (mounted) {
        setState(() {
          _shorts = shorts;
          _isLoadingShorts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingShorts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillProf Platform'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.pushNamed(context, '/notifications').then((_) => _fetchNotifications()),
              ),
              if (_notifications.any((n) => !(n['isRead'] ?? false)))
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.secondaryOrange, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hello, ${_getDisplayName()}👋", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                    Text("What will you learn today?", style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22)),
                  ],
                ),
                CircleAvatar(
                  radius: 26,
                  backgroundImage: (session.avatarUrl != null && session.avatarUrl!.isNotEmpty)
                      ? NetworkImage(UrlHelper.fixIp(session.avatarUrl!)) as ImageProvider
                      : const AssetImage('assets/images/tutor.png'),
                  backgroundColor: AppTheme.primaryPurple,
                )
              ],
            ),

            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ]
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                  const SizedBox(width: 12),
                  Text("Search for a skill...", style: TextStyle(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight, fontSize: 16)),
                  const Spacer(),
                  const Icon(Icons.mic, color: AppTheme.primaryPurple),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Categories", style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20)),
                TextButton(onPressed: (){}, child: const Text("See All", style: TextStyle(color: AppTheme.primaryPurple)))
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryCard(context, "Design", Icons.brush),
                  const SizedBox(width: 16),
                  _buildCategoryCard(context, "Coding", Icons.code),
                  const SizedBox(width: 16),
                  _buildCategoryCard(context, "Marketing", Icons.trending_up),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Quick Tips", style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20)),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Explore all shorts in the Shorts tab!")));
                  }, 
                  child: const Text("See All", style: TextStyle(color: AppTheme.primaryPurple))
                )
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: _isLoadingShorts
                ? const Center(child: CircularProgressIndicator())
                : _shorts.isEmpty
                  ? Center(child: Text("no shorts yet", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _shorts.length,
                      itemBuilder: (context, index) {
                        final short = _shorts[index];
                        return _buildShortCard(context, short);
                      },
                    ),
            ),
            const SizedBox(height: 32),
            
            Text("Trending Offers", style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20)),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _trendingCourses.isEmpty 
                  ? const Center(child: Text("no courses yet", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _trendingCourses.length,
                      itemBuilder: (context, index) {
                        final course = _trendingCourses[index];
                        return _buildCourseCard(
                          context, 
                          course['title'] ?? 'Course', 
                          course['description'] ?? '', 
                          "${course['price']?.toString() ?? '0'}fr", 
                          Icons.school
                        );
                      },
                    ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(categoryName: title)));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100, // Fixed width for scrolling row
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryPurple, size: 28),
            const SizedBox(height: 12),
            Text(
              title, 
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryPurple, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayName() {
    final name = session.fullName;
    if (name == null || name.trim().isEmpty) return "Learner";
    return name.split(' ').first;
  }

  Widget _buildShortCard(BuildContext context, dynamic short) {
    // ... (rest of the method remains same, keeping placeholder consistent)
    return GestureDetector(
      onTap: () {
        // In a real app, navigate to a dedicated short player or the feed
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tip by ${short['tutorName']}")));
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            const Center(child: Icon(Icons.play_circle_outline, color: AppTheme.primaryPurple, size: 30)),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                short['courseName'] ?? 'Tip',
                style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 10, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, String title, String subtitle, String price, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            decoration: const BoxDecoration(
              color: AppTheme.primaryPurple,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(child: Icon(icon, size: 54, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  subtitle, 
                  style: TextStyle(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        price, 
                        style: const TextStyle(color: AppTheme.secondaryOrange, fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: AppTheme.accentYellow, size: 14),
                        Text(" 4.8", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
