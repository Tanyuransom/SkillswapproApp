import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../course/upload_course_screen.dart';
import '../shorts/upload_short_screen.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../messaging/chat_screen.dart';
import '../messaging/inbox_screen.dart';
import '../../utils/url_helper.dart';
import 'my_courses_screen.dart';
import 'exam_screen.dart';

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
  bool _isVerified = false;
  int _activeStudentCount = 0;
  int _courseCount = 0;
  int _earnings = 0;

  double get _averageRating {
    if (_courses.isEmpty) return 0.0;
    double sum = 0.0;
    int count = 0;
    for (var c in _courses) {
      final rawRating = c['averageRating'];
      final rating = (rawRating is num ? rawRating.toDouble() : double.tryParse(rawRating?.toString() ?? '0') ?? 0.0);
      if (rating > 0.0) {
        sum += rating;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  int get _totalReviews {
    int total = 0;
    for (var c in _courses) {
      final int reviews = c['reviewCount'] ?? 0;
      total += reviews;
    }
    return total;
  }

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
      _fetchVerificationStatus(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchVerificationStatus() async {
    final tutorId = SessionService().userId;
    if (tutorId == null) return;
    try {
      final result = await ApiService.getVerificationStatus(tutorId);
      if (mounted) {
        setState(() {
          _isVerified = result['verified'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching verification status: $e");
    }
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
    final session = SessionService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Command Center'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            icon: const Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryPurple),
            onPressed: () => _handleUploadCourseAction(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- NEW PROFILE HEADER ---
              _buildProfileHeader(session),
              const SizedBox(height: 24),

              if (!_isVerified) ...[
                _buildUnverifiedBanner(session.specialization ?? "SEN"),
                const SizedBox(height: 24),
              ],
              
              // --- INTEGRATED STATS ---
              _buildStatBanner(),
              const SizedBox(height: 32),
              
              _buildSectionTitle('Quick Actions'),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildActionCard('My Courses', Icons.collections_bookmark_rounded, AppTheme.primaryPurple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCoursesScreen())).then((_) => _refreshAll())),
                  const SizedBox(width: 12),
                  _buildActionCard('New Short', Icons.video_call, AppTheme.secondaryOrange, () => _handleNewShortAction()),
                  const SizedBox(width: 12),
                  _buildActionCard('Messages', Icons.message_rounded, AppTheme.accentYellow, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen())).then((_) => _refreshAll())),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Active Students'),
              const SizedBox(height: 16),
              _buildStudentList(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(SessionService session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 5))
        ]
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppTheme.primaryPurple, AppTheme.secondaryOrange])
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: (session.avatarUrl != null && session.avatarUrl!.isNotEmpty)
                      ? NetworkImage(UrlHelper.fixIp(session.avatarUrl!)) as ImageProvider
                      : const AssetImage('assets/images/tutor.png'),
                ),
              ),
              if (_isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.successGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                )
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.fullName ?? "Expert Tutor",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  session.specialization ?? "Skill Instructor",
                  style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppTheme.accentYellow, size: 16),
                    Text(" ${_averageRating.toStringAsFixed(1)} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("($_totalReviews reviews)", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryPurple),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          )
        ],
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

  void _handleUploadCourseAction() {
    if (!_isVerified) {
      _showVerificationRequiredDialog("upload courses");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadCourseScreen())
    ).then((_) => _refreshAll());
  }

  void _handleNewShortAction() {
    if (!_isVerified) {
      _showVerificationRequiredDialog("upload shorts");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadShortScreen())
    ).then((_) => _refreshAll());
  }

  void _showVerificationRequiredDialog(String actionText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gpp_maybe_rounded, color: AppTheme.errorRed, size: 28),
            SizedBox(width: 12),
            Text('Verification Required'),
          ],
        ),
        content: Text('You must pass the AI Skill Exam in your specialization (${SessionService().specialization ?? "SEN"}) before you can $actionText.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startVerificationFlow();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
            child: const Text('TAKE EXAM', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUnverifiedBanner(String specialization) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gpp_maybe_rounded, color: AppTheme.errorRed, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Unverified',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.errorRed),
                ),
                const SizedBox(height: 4),
                Text(
                  'Take the AI Competency Exam in $specialization to verify your skills and enable uploads.',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _startVerificationFlow,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('VERIFY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _startVerificationFlow() {
    final specialization = SessionService().specialization ?? "SEN";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamScreen(specialization: specialization),
      ),
    ).then((passed) {
      if (passed == true) {
        _refreshAll();
      }
    });
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
