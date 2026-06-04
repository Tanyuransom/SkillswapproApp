import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/session_service.dart';
import '../../services/api_service.dart';
import '../../utils/url_helper.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _fetchConversations(silent: true);
    });
  }

  Future<void> _fetchConversations({bool silent = false}) async {
    final myId = SessionService().userId;
    if (myId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final conversations = await ApiService.getConversations(myId);

      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(conversations);
          if (!silent) _isLoading = false;
          if (_isLoading) _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Inbox'),
            if (_conversations.any((c) => (c['unreadCount'] ?? 0) > 0)) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _conversations.fold<int>(0, (sum, c) => sum + ((c['unreadCount'] as num?)?.toInt() ?? 0)).toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchConversations(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchConversations,
              color: AppTheme.primaryPurple,
              child: _conversations.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _conversations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final conv = _conversations[index];
                        final avatarUrl = conv['partnerAvatar'] as String?;
                        final partnerName = (conv['partnerName'] as String?)?.isNotEmpty == true
                            ? conv['partnerName'] as String
                            : 'User';
                        final unreadCount = (conv['unreadCount'] as num?)?.toInt() ?? 0;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.15),
                                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                    ? NetworkImage(UrlHelper.fixIp(avatarUrl)) as ImageProvider
                                    : null,
                                child: (avatarUrl == null || avatarUrl.isEmpty)
                                    ? Text(
                                        partnerName[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: AppTheme.primaryPurple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryPurple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        unreadCount > 9 ? '9+' : '$unreadCount',
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            partnerName,
                            style: TextStyle(
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            conv['latestMessage'] as String? ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              color: unreadCount > 0 ? AppTheme.primaryPurple : Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Text(
                            _formatTime(conv['time']),
                            style: TextStyle(
                              fontSize: 11,
                              color: unreadCount > 0 ? AppTheme.primaryPurple : Colors.grey,
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  partnerId: conv['partnerId'] as String,
                                  partnerName: partnerName,
                                  partnerAvatar: conv['partnerAvatar'] as String?,
                                ),
                              ),
                            );
                            _fetchConversations(); // Refresh unread counts on return
                          },
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 72, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text(
                "No conversations yet",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                "Message a tutor from any course page",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _fetchConversations,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(dynamic rawTime) {
    try {
      if (rawTime == null) return '';
      final date = rawTime is DateTime
          ? rawTime.toLocal()
          : DateTime.parse(rawTime.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inSeconds < 60) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (date.day == now.day && date.month == now.month && date.year == now.year) {
        return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }
}
