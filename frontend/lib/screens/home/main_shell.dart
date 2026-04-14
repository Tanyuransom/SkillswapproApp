import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/session_service.dart';
import 'dashboard_screen.dart';
import '../discovery/discovery_screen.dart';
import '../shorts/shorts_feed_screen.dart';
import '../messaging/inbox_screen.dart';
import '../profile/profile_screen.dart';
import '../tutor/tutor_dashboard.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  List<Widget> _getScreens() {
    final session = SessionService();
    return [
      const DashboardScreen(),
      const DiscoveryScreen(),
      const ShortsFeedScreen(),
      if (session.isTutor) const TutorDashboard(),
      const InboxScreen(),
      const ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> _getNavItems(bool isDark) {
    final session = SessionService();
    return [
      const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Discover'),
      const BottomNavigationBarItem(icon: Icon(Icons.play_circle_filled), label: 'Shorts'),
      if (session.isTutor) 
        const BottomNavigationBarItem(
          icon: Icon(Icons.school_rounded, color: AppTheme.secondaryOrange), 
          label: 'Teaching',
          activeIcon: Icon(Icons.school_rounded, color: AppTheme.secondaryOrange),
        ),
      const BottomNavigationBarItem(icon: Icon(Icons.message_rounded), label: 'Inbox'),
      const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screens = _getScreens();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          // If already on Home tab, we can allow the user to exit the app
          // or show a confirm dialog. For now, let's keep it simple.
        }
      },
      child: Scaffold(
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: AppTheme.primaryPurple,
          unselectedItemColor: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          items: _getNavItems(isDark),
        ),
      ),
    );
  }
}
