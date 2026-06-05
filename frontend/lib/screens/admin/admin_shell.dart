import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../messaging/chat_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    UserManagementScreen(),
    VerificationQueueScreen(),
    CourseAllocationScreen(),
    FeedbackListScreen(),
    SystemSettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 
            ? 'User Management' 
            : _currentIndex == 1 
              ? 'Verifications' 
              : _currentIndex == 2
                ? 'Course Allocation'
                : _currentIndex == 3
                  ? 'User Feedback'
                  : 'System Control'
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.errorRed),
            onPressed: () {
              SessionService().clearSession();
              Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: AppTheme.primaryPurple,
        unselectedItemColor: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group_rounded),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_add_check_rounded),
            label: 'Verification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_rounded),
            label: 'Allocations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_rounded),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_suggest_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getUsers();
      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _confirmDeleteUser(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to delete ${user['fullName']} (${user['email']})? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await ApiService.deleteUser(user['id']);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted successfully!')));
                _fetchUsers();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete user: $e'), backgroundColor: AppTheme.errorRed));
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedRole = 'student';
    String? selectedSpecialty;
    final List<String> roles = ['student', 'tutor', 'admin'];
    final List<String> specialties = ['ICT', 'ISN', 'CS', 'SEN', 'CYS'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                  onChanged: (val) => setStateDialog(() => selectedRole = val ?? 'student'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedSpecialty,
                  decoration: const InputDecoration(labelText: 'Specialty (Optional)'),
                  items: specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setStateDialog(() => selectedSpecialty = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                final name = nameCtrl.text.trim();
                if (email.isEmpty || name.isEmpty) return;
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await ApiService.createUser(
                    email: email,
                    fullName: name,
                    role: selectedRole,
                    specialization: selectedSpecialty,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created successfully!')));
                  _fetchUsers();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create user: $e'), backgroundColor: AppTheme.errorRed));
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          const PlatformStatsWidget(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Registered Users (${_users.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchUsers,
                )
              ],
            ),
          ),
          Expanded(
            child: _users.isEmpty
                ? const Center(child: Text("No users found."))
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final String role = user['role'] ?? 'student';
                      final bool isTutor = role == 'tutor';
                      final bool isAdmin = role == 'admin';

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  partnerId: user['id'],
                                  partnerName: user['fullName'] ?? 'User',
                                  partnerAvatar: user['avatarUrl'],
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: isAdmin
                                ? Colors.red
                                : isTutor
                                    ? AppTheme.secondaryOrange
                                    : AppTheme.primaryPurple,
                            child: Icon(
                              isAdmin
                                  ? Icons.admin_panel_settings
                                  : isTutor
                                      ? Icons.school
                                      : Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            user['fullName'] ?? 'User',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Role: ${role.toUpperCase()} • Email: ${user['email'] ?? 'N/A'}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryPurple),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        partnerId: user['id'],
                                        partnerName: user['fullName'] ?? 'User',
                                        partnerAvatar: user['avatarUrl'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDeleteUser(user),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: AppTheme.primaryPurple,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }
}

class VerificationQueueScreen extends StatefulWidget {
  const VerificationQueueScreen({super.key});

  @override
  State<VerificationQueueScreen> createState() => _VerificationQueueScreenState();
}

class _VerificationQueueScreenState extends State<VerificationQueueScreen> {
  List<dynamic> _verifications = [];
  Map<String, dynamic> _userMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final logs = await ApiService.getAllVerifications();
      final users = await ApiService.getUsers();
      
      final Map<String, dynamic> tempUserMap = {};
      for (var u in users) {
        if (u['id'] != null) {
          tempUserMap[u['id']] = u;
        }
      }

      setState(() {
        _verifications = logs;
        _userMap = tempUserMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "AI Exam Attempts (${_verifications.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadData,
                )
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _verifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _verifications.length,
                    itemBuilder: (context, index) {
                      final log = _verifications[index];
                      final tutorId = log['tutorId'] ?? '';
                      final user = _userMap[tutorId];
                      final name = user != null ? user['fullName'] : 'Unknown Tutor';
                      final email = user != null ? user['email'] : 'N/A';
                      
                      final spec = log['specialization'] ?? 'GEN';
                      final score = log['score'] ?? 0;
                      final total = log['totalQuestions'] ?? 5;
                      final status = log['status'] ?? 'pending';
                      final dateStr = log['createdAt'] != null 
                          ? DateTime.parse(log['createdAt']).toLocal().toString().substring(0, 16)
                          : 'N/A';
                          
                      final bool isPass = status == 'passed';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPass ? AppTheme.successGreen.withValues(alpha: 0.1) : AppTheme.errorRed.withValues(alpha: 0.1),
                            child: Icon(
                              isPass ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                              color: isPass ? AppTheme.successGreen : AppTheme.errorRed,
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: $email'),
                              const SizedBox(height: 2),
                              Text('Exam: $spec • Score: $score/$total • Date: $dateStr', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isPass ? AppTheme.successGreen : AppTheme.errorRed).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: isPass ? AppTheme.successGreen : AppTheme.errorRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No exam logs found.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Exam verification records will appear here.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Admin level system settings go here.'));
  }
}

class PlatformStatsWidget extends StatefulWidget {
  const PlatformStatsWidget({super.key});

  @override
  State<PlatformStatsWidget> createState() => _PlatformStatsWidgetState();
}

class _PlatformStatsWidgetState extends State<PlatformStatsWidget> {
  int _studentCount = 0;
  int _tutorCount = 0;
  int _courseCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() async {
    try {
      final users = await ApiService.getUsers();
      final courses = await ApiService.getCourses();
      
      int students = 0;
      int tutors = 0;
      for (var u in users) {
        if (u['role'] == 'tutor') {
          tutors++;
        } else if (u['role'] == 'student') {
          students++;
        }
      }

      if (mounted) {
        setState(() {
          _studentCount = students;
          _tutorCount = tutors;
          _courseCount = courses.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryPurple, Color(0xFF6A1B9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryPurple.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                "Platform Overview",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatTile(
                label: "Students",
                value: _isLoading ? "..." : _studentCount.toString(),
                icon: Icons.people_alt_rounded,
              ),
              _StatTile(
                label: "Tutors",
                value: _isLoading ? "..." : _tutorCount.toString(),
                icon: Icons.school_rounded,
              ),
              _StatTile(
                label: "Courses",
                value: _isLoading ? "..." : _courseCount.toString(),
                icon: Icons.collections_bookmark_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class CourseAllocationScreen extends StatefulWidget {
  const CourseAllocationScreen({super.key});

  @override
  State<CourseAllocationScreen> createState() => _CourseAllocationScreenState();
}

class _CourseAllocationScreenState extends State<CourseAllocationScreen> {
  String _selectedSpecialty = 'SEN';
  int _selectedLevel = 1;
  List<dynamic> _courses = [];
  bool _isLoading = true;
  bool _isSaving = false;
  final Set<String> _modifiedCourseIds = {};

  final List<String> _specialties = const ['ICT', 'ISN', 'CS', 'SEN', 'CYS', 'REN', 'JMC', 'BMS'];
  final List<int> _levels = const [1, 2, 3, 4];
  
  static const List<String> _ictSpecialties = ['ICT', 'ISN', 'CS', 'CSC', 'SEN', 'CYS'];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _modifiedCourseIds.clear();
    });
    try {
      final courses = await ApiService.getCourses();
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading courses: $e'), backgroundColor: AppTheme.errorRed),
      );
    }
  }

  void _confirmDeleteCourse(dynamic course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course?'),
        content: Text('Are you sure you want to delete "${course['title']}"? This will delete the course and all associated lessons/materials permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await ApiService.deleteCourse(course['id']);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course deleted successfully!')));
                _loadCourses();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete course: $e'), backgroundColor: AppTheme.errorRed));
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddCourseDialog() {
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');
    int selectedLevel = 1;
    String selectedSpecialty = 'SEN';
    final semesterCtrl = TextEditingController(text: 'Spring 2026');
    String? selectedCategoryId;
    List<dynamic> categories = [];
    bool loadingCats = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          if (loadingCats) {
            ApiService.getCategories().then((cats) {
              setStateDialog(() {
                categories = cats;
                if (cats.isNotEmpty) selectedCategoryId = cats.first['id'];
                loadingCats = false;
              });
            });
          }

          return AlertDialog(
            title: const Text('Add New Course'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Course Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'Course Code (e.g. MTH 1221)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 8),
                  if (loadingCats)
                    const CircularProgressIndicator()
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories.map((c) => DropdownMenuItem<String>(
                        value: c['id'] as String,
                        child: Text(c['name'] as String),
                      )).toList(),
                      onChanged: (val) => setStateDialog(() => selectedCategoryId = val),
                    ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: selectedLevel,
                    decoration: const InputDecoration(labelText: 'Year / Level'),
                    items: [1, 2, 3, 4].map((l) => DropdownMenuItem(value: l, child: Text('Level $l'))).toList(),
                    onChanged: (val) => setStateDialog(() => selectedLevel = val ?? 1),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSpecialty,
                    decoration: const InputDecoration(labelText: 'Specialty'),
                    items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setStateDialog(() => selectedSpecialty = val ?? 'SEN'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: semesterCtrl,
                    decoration: const InputDecoration(labelText: 'Semester (e.g. Spring 2026, Fall 2026)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price (FR)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final code = codeCtrl.text.trim();
                  final desc = descCtrl.text.trim();
                  final price = double.tryParse(priceCtrl.text) ?? 0.0;
                  final semester = semesterCtrl.text.trim();

                  if (title.isEmpty || code.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and Code are required!')));
                    return;
                  }

                  Navigator.pop(context);
                  setState(() => _isLoading = true);

                  try {
                    await ApiService.createCourse(
                      title: "$title ($code)",
                      description: desc.isNotEmpty ? desc : "Course: $title",
                      price: price,
                      instructorId: SessionService().userId ?? 'mock-admin-id',
                      instructorName: SessionService().fullName ?? 'Admin',
                      instructorAvatarUrl: SessionService().avatarUrl,
                      categoryId: selectedCategoryId,
                      level: selectedLevel,
                      specialty: selectedSpecialty,
                      semester: semester,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course created successfully!')));
                    _loadCourses();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create course: $e'), backgroundColor: AppTheme.errorRed));
                    setState(() => _isLoading = false);
                  }
                },
                child: const Text('Add Course'),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isElectiveCourse(String title, int level) {
    if (level != 2) return false;
    final t = title.toLowerCase();
    return t.contains("civics and ethics") ||
        t.contains("computer networking and security") ||
        t.contains("game dev") ||
        t.contains("game developmen") ||
        (t.contains("introduction to iot") && t.contains("embedded"));
  }

  void _toggleAllocation(Map<String, dynamic> course, bool allocate) {
    final String currentSpecialties = course['specialty'] ?? '';
    final List<String> specList = currentSpecialties
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (_selectedLevel == 2) {
      // Level 2 rule: all year 2 courses apply for all specialty
      if (allocate) {
        for (var spec in _specialties) {
          if (!specList.contains(spec)) {
            specList.add(spec);
          }
        }
      } else {
        for (var spec in _specialties) {
          specList.remove(spec);
        }
      }
    } else if (_selectedLevel == 1 && _ictSpecialties.contains(_selectedSpecialty)) {
      // ICT Faculty Year One rule: they all do the same courses no matter the specialty
      if (allocate) {
        for (var spec in _ictSpecialties) {
          if (!specList.contains(spec)) {
            specList.add(spec);
          }
        }
      } else {
        for (var spec in _ictSpecialties) {
          specList.remove(spec);
        }
      }
    } else {
      if (allocate) {
        if (!specList.contains(_selectedSpecialty)) {
          specList.add(_selectedSpecialty);
        }
      } else {
        specList.remove(_selectedSpecialty);
      }
    }

    final newSpecialty = specList.join(',');
    final originalLevel = course['level'] ?? 1;
    final newLevel = allocate ? _selectedLevel : originalLevel;

    setState(() {
      course['specialty'] = newSpecialty;
      if (allocate) {
        course['level'] = newLevel;
      }
      _modifiedCourseIds.add(course['id']);
    });
  }

  Future<void> _saveChanges() async {
    if (_modifiedCourseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final List<Future> saveFutures = [];
      for (final courseId in _modifiedCourseIds) {
        final course = _courses.firstWhere((c) => c['id'] == courseId, orElse: () => null);
        if (course != null) {
          saveFutures.add(
            ApiService.updateCourse(
              courseId: courseId,
              level: course['level'] ?? 1,
              specialty: course['specialty'] ?? '',
            ),
          );
        }
      }

      await Future.wait(saveFutures);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully saved ${_modifiedCourseIds.length} course allocation(s)!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      setState(() {
        _modifiedCourseIds.clear();
        _isSaving = false;
      });
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: $e'), backgroundColor: AppTheme.errorRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter list:
    // If search is active, match course title/code
    // If search is empty, only show courses that are already assigned to this Level & Specialty
    final filteredCourses = _courses.where((course) {
      final String title = (course['title'] ?? '').toLowerCase();
      final String code = (course['code'] ?? '').toLowerCase();
      final String query = _searchQuery.trim().toLowerCase();

      if (query.isNotEmpty) {
        return title.contains(query) || code.contains(query);
      }

      final String currentSpecialties = course['specialty'] ?? '';
      final int currentLevel = course['level'] ?? 1;
      
      if (currentLevel == 2 && _selectedLevel == 2) {
        return true;
      }

      final List<String> specList = currentSpecialties
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      return specList.contains(_selectedSpecialty) && currentLevel == _selectedLevel;
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Course Allocator",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20),
                ),
                if (_modifiedCourseIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${_modifiedCourseIds.length} unsaved",
                      style: const TextStyle(
                        color: AppTheme.secondaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Note: Year 1 ICT courses & all Year 2 courses are automatically shared across their respective specialties.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search course by title or code to allocate...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Specialty", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSpecialty,
                            isExpanded: true,
                            items: _specialties.map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedSpecialty = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Level", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedLevel,
                            isExpanded: true,
                            items: _levels.map((l) => DropdownMenuItem(
                              value: l,
                              child: Text("Level $l"),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedLevel = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchQuery.isNotEmpty 
                      ? "Search Results (${filteredCourses.length})"
                      : "Assigned Courses (${filteredCourses.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadCourses,
                ),
              ],
            ),
            const SizedBox(height: 8),
  
            Expanded(
              child: filteredCourses.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? "No courses match your search."
                              : "No courses assigned to $_selectedSpecialty Level $_selectedLevel. Use the search bar above to find and assign courses.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = filteredCourses[index];
                        final String currentSpecialties = course['specialty'] ?? '';
                        final int currentLevel = course['level'] ?? 1;
                        
                        final List<String> specList = currentSpecialties
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
  
                        final bool isAllocated = specList.contains(_selectedSpecialty) && currentLevel == _selectedLevel;
                        final String courseTitle = course['title'] ?? 'Untitled Course';
  
                        // Level 2 compulsory/elective details:
                        Widget? typeBadge;
                        if (currentLevel == 2) {
                          final isElective = _isElectiveCourse(courseTitle, currentLevel);
                          typeBadge = Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isElective ? Colors.blue.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isElective ? Colors.blue : Colors.red, width: 0.5),
                            ),
                            child: Text(
                              isElective ? "Elective (L2)" : "Compulsory (L2)",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isElective ? Colors.blue.shade700 : Colors.red.shade700,
                              ),
                            ),
                          );
                        } else if (currentLevel == 1) {
                          typeBadge = Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red, width: 0.5),
                            ),
                            child: Text(
                              "Compulsory (L1)",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          );
                        }
  
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Checkbox(
                                  activeColor: AppTheme.primaryPurple,
                                  value: isAllocated,
                                  onChanged: (bool? checked) {
                                    if (checked != null) {
                                      _toggleAllocation(course, checked);
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        courseTitle,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Code: ${course['code'] ?? 'N/A'} • Category: ${course['category'] ?? 'N/A'}${course['semester'] != null ? ' • Semester: ${course['semester']}' : ''}",
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                      ?typeBadge,
                                      if (specList.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: specList.map((s) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: s == _selectedSpecialty && currentLevel == _selectedLevel
                                                  ? AppTheme.primaryPurple.withValues(alpha: 0.1)
                                                  : Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              "$s (L$currentLevel)",
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: s == _selectedSpecialty && currentLevel == _selectedLevel
                                                    ? AppTheme.primaryPurple
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                          )).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _confirmDeleteCourse(course),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            if (_modifiedCourseIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveChanges,
                  icon: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, color: Colors.white),
                  label: Text(
                    _isSaving ? "SAVING..." : "SAVE ALLOCATIONS (${_modifiedCourseIds.length})",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCourseDialog,
        backgroundColor: AppTheme.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class FeedbackListScreen extends StatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  State<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends State<FeedbackListScreen> {
  List<dynamic> _feedbackList = [];
  Map<String, dynamic> _userMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final feedback = await ApiService.getAppReviews();
      final users = await ApiService.getUsers();
      
      final Map<String, dynamic> userMap = {};
      for (var u in users) {
        if (u['id'] != null) {
          userMap[u['id']] = u;
        }
      }

      setState(() {
        _feedbackList = feedback;
        _userMap = userMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _feedbackList.isEmpty
            ? const Center(child: Text("No feedback received yet."))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _feedbackList.length,
                itemBuilder: (context, index) {
                  final fb = _feedbackList[index];
                  final userId = fb['userId'] ?? 'anonymous';
                  final bool isAnonymous = userId == 'anonymous';
                  
                  final user = _userMap[userId];
                  final String userName = fb['userName'] ?? (user != null ? (user['fullName'] ?? 'User') : (isAnonymous ? 'Anonymous' : 'User ($userId)'));
                  final String? avatarUrl = user?['avatarUrl'];
                  final int rating = fb['rating'] ?? 5;
                  final String comment = fb['comment'] ?? '';
                  final String dateStr = fb['createdAt'] != null
                      ? DateTime.parse(fb['createdAt']).toLocal().toString().substring(0, 16)
                      : 'N/A';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isAnonymous ? Colors.grey : AppTheme.primaryPurple,
                                backgroundImage: (avatarUrl != null && avatarUrl.startsWith('http'))
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: (avatarUrl == null || !avatarUrl.startsWith('http'))
                                    ? Text(
                                        userName[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateStr,
                                      style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isAnonymous)
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                  label: const Text('Inbox'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    backgroundColor: AppTheme.primaryPurple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          partnerId: userId,
                                          partnerName: userName,
                                          partnerAvatar: avatarUrl,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(5, (starIdx) {
                              return Icon(
                                starIdx < rating ? Icons.star : Icons.star_border,
                                color: AppTheme.accentYellow,
                                size: 20,
                              );
                            }),
                          ),
                          if (comment.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              comment,
                              style: const TextStyle(fontSize: 14, height: 1.3),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
