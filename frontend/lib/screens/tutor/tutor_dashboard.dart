import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../course/upload_course_screen.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../messaging/chat_screen.dart';
import '../messaging/inbox_screen.dart';
import '../../utils/url_helper.dart';

class TutorDashboard extends StatefulWidget {
  const TutorDashboard({super.key});

  @override
  State<TutorDashboard> createState() => _TutorDashboardState();
}

class _TutorDashboardState extends State<TutorDashboard> {
  List<dynamic> _students = [];
  List<dynamic> _courses = [];
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  int _activeStudentCount = 0;
  int _courseCount = 0;
  int _earnings = 0;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchStudents(),
      _fetchCourses(),
      _fetchNotifications(),
      _fetchStats(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchStats() async {
    final tutorId = SessionService().userId;
    if (tutorId == null) return;
    try {
      final stats = await ApiService.getTutorStats(tutorId);
      if (mounted) {
        setState(() {
          _activeStudentCount = stats['activeStudents'] ?? 0;
          _earnings = _activeStudentCount * 15000; // Mock calculation or real if added to stats
        });
      }
    } catch (e) { /* silent */ }
  }

  Future<void> _fetchStudents() async {
    final tutorId = SessionService().userId;
    if (tutorId == null) return;
    try {
      final enrollments = await ApiService.getEnrolledStudents(tutorId);
      if (mounted) {
        setState(() {
          _students = enrollments;
        });
      }
    } catch (e) { 
      print("Tutor Dashboard Error: $e");
    }
  }

  Future<void> _fetchCourses() async {
    final tutorId = SessionService().userId;
    if (tutorId == null) return;
    try {
      final courses = await ApiService.getTutorCourses(tutorId);
      if (mounted) {
        setState(() {
          _courses = courses;
          _courseCount = courses.length;
        });
      }
    } catch (e) { /* silent */ }
  }

  Future<void> _fetchNotifications() async {
    final userId = SessionService().userId;
    if (userId == null) return;
    try {
      _notifications = await ApiService.getNotifications(userId);
    } catch (e) { /* silent */ }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor Command Center'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () => Navigator.pushNamed(context, '/notifications').then((_) => _refreshAll()),
              ),
              if (_notifications.any((n) => !(n['isRead'] ?? false)))
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.secondaryOrange, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add_a_photo_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadCourseScreen())).then((_) => _refreshAll()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatBanner(),
              const SizedBox(height: 32),
              _buildSectionTitle('Quick Actions'),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildActionCard('New Lesson', Icons.video_call, AppTheme.primaryPurple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadCourseScreen())).then((_) => _refreshAll())),
                  const SizedBox(width: 16),
                  _buildActionCard('Messages', Icons.message_rounded, AppTheme.secondaryOrange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen())).then((_) => _refreshAll())),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Active Students'),
              const SizedBox(height: 16),
              _buildStudentList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20));
  }

  Widget _buildStatBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryPurple, Color(0xFF9F85FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primaryPurple.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Earnings', value: '$_earnings fr'),
          _StatItem(label: 'Students', value: '$_activeStudentCount'),
          _StatItem(label: 'Courses', value: '$_courseCount'),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_students.isEmpty) return _buildEmptyState('no students enrolled yet');
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryPurple,
              backgroundImage: (student['studentAvatar'] != null && student['studentAvatar']!.isNotEmpty)
                  ? NetworkImage(UrlHelper.fixIp(student['studentAvatar']!)) as ImageProvider
                  : null,
              child: (student['studentAvatar'] == null || student['studentAvatar']!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: Text(student['studentName'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Enrolled in your course'),
            trailing: const Icon(Icons.message_rounded, color: AppTheme.primaryPurple),
            onTap: () => _startChat(student),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.history_edu_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(msg, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: _notifications.isEmpty 
              ? const Center(child: Text('No new alerts'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: const Icon(Icons.notifications_active, color: AppTheme.secondaryOrange),
                    title: Text(_notifications[i]['title'] ?? 'Alert'),
                    subtitle: Text(_notifications[i]['message'] ?? ''),
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyCourses() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Teaching History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: _courses.isEmpty 
              ? const Center(child: Text('No courses created yet'))
              : ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (context, i) => Card(
                    child: ListTile(
                      title: Text(_courses[i]['title'] ?? 'Course'),
                      subtitle: Text('${_courses[i]['price']} fr'),
                      trailing: const Icon(Icons.edit_note_rounded),
                    ),
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  void _startChat(dynamic student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          partnerId: student['studentId'],
          partnerName: student['studentName'] ?? 'Student',
          partnerAvatar: UrlHelper.fixIp(student['studentAvatar'] ?? ''),
        ),
      ),
    ).then((_) => _refreshAll());
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
      ],
    );
  }
}
