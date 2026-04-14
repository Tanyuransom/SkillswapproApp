import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';

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
        title: Text(_currentIndex == 0 ? 'User Management' : _currentIndex == 1 ? 'Verifications' : 'System Control'),
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
            icon: Icon(Icons.settings_suggest_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          const PlatformStatsWidget(),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                final isTutor = index % 2 == 0;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isTutor ? AppTheme.secondaryOrange : AppTheme.primaryPurple,
                      child: Icon(isTutor ? Icons.school : Icons.person, color: Colors.white, size: 20),
                    ),
                    title: Text(isTutor ? 'Tutor Name ${index + 1}' : 'Student Name ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(isTutor ? 'Subject: Flutter Dev • Since Jan 2024' : 'Learning: UI Design • Since Feb 2024'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                         if (value == 'delete') {
                            // Mock delete logic
                         }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit Profile'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'cert',
                          child: ListTile(
                            leading: Icon(Icons.workspace_premium),
                            title: Text('Issue Certificate'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: AppTheme.errorRed),
                            title: Text('Delete User', style: TextStyle(color: AppTheme.errorRed)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
  }
}

class VerificationQueueScreen extends StatelessWidget {
  const VerificationQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pending_actions_rounded, size: 100, color: AppTheme.secondaryOrange),
            const SizedBox(height: 16),
            Text('No Pending Verifications', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Tutor application queue is currently empty.', style: TextStyle(color: Colors.grey)),
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
  int _activeStudents = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() async {
    try {
      final stats = await ApiService.getAdminStats();
      setState(() {
        _activeStudents = stats['activeStudents'] ?? 0;
        _isLoading = false;
      });
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
                label: "Active Students",
                value: _isLoading ? "..." : _activeStudents.toString(),
                icon: Icons.people_alt_rounded,
              ),
              const _StatTile(
                label: "Revenue",
                value: "1.2M fr",
                icon: Icons.payments_rounded,
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
