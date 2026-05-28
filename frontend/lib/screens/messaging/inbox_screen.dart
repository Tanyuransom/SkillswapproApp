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

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    final myId = SessionService().userId;
    if (myId == null) return;

    try {
      final conversations = await ApiService.getConversations(myId);
      
      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(conversations);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchConversations),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
               ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conv = _conversations[index];
                    final avatarUrl = conv['partnerAvatar'];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                            ? NetworkImage(UrlHelper.fixIp(avatarUrl)) as ImageProvider
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty) 
                            ? Text(conv['partnerName'][0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryPurple))
                            : null,
                      ),
                      title: Text(conv['partnerName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(conv['latestMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_formatTime(conv['time']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          if (conv['unreadCount'] > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.primaryPurple, borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                conv['unreadCount'].toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      onTap: () async {
                         await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              partnerId: conv['partnerId'], 
                              partnerName: conv['partnerName'],
                              partnerAvatar: conv['partnerAvatar'],
                            )
                          )
                        );
                        _fetchConversations(); // Refresh on back
                      },
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
          const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("No conversations yet", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          TextButton(onPressed: _fetchConversations, child: const Text("Refresh")),
        ],
      ),
    );
  }

  String _formatTime(String isoTime) {
    try {
      final date = DateTime.parse(isoTime).toLocal();
      final now = DateTime.now();
      if (date.day == now.day && date.month == now.month && date.year == now.year) {
        return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
      }
      return "${date.day}/${date.month}";
    } catch (e) {
      return "";
    }
  }
}
