import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/session_service.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final userId = SessionService().userId;
    if (userId == null) return;

    try {
      final data = await ApiService.getNotifications(userId);
      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = SessionService().userId;
    if (userId == null) return;
    try {
      await ApiService.markAllNotificationsAsRead(userId);
      _fetchNotifications();
    } catch (e) { /* silent */ }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => !(n['isRead'] ?? false)))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text("Mark all as read", style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchNotifications),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final note = _notifications[index];
                    final isEnrolled = note['type'] == 'enrollment';
                    
                    return InkWell(
                      onTap: () async {
                        if (!(note['isRead'] ?? false)) {
                          await ApiService.markNotificationAsRead(note['id']);
                          _fetchNotifications();
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isEnrolled ? AppTheme.successGreen : AppTheme.primaryPurple).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isEnrolled ? Icons.school_rounded : Icons.notifications_rounded,
                                color: isEnrolled ? AppTheme.successGreen : AppTheme.primaryPurple,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note['title'] ?? 'New Notification',
                                    style: TextStyle(
                                      fontWeight: (note['isRead'] ?? false) ? FontWeight.normal : FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    note['message'] ?? '',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                      fontWeight: (note['isRead'] ?? false) ? FontWeight.normal : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatTime(note['createdAt']),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            if (!(note['isRead'] ?? false))
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppTheme.secondaryOrange, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("No notifications yet", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          TextButton(onPressed: _fetchNotifications, child: const Text("Refresh")),
        ],
      ),
    );
  }

  String _formatTime(String isoTime) {
    try {
      final date = DateTime.parse(isoTime).toLocal();
      final now = DateTime.now();
      if (date.day == now.day && date.month == now.month && date.year == now.year) {
        return "Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
      }
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "";
    }
  }
}
