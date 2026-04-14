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
      final messages = await ApiService.getMessages(myId);
      
      // Group by partnerId
      final Map<String, List<dynamic>> grouped = {};
      for (var msg in messages) {
        final partnerId = msg['senderId'] == myId ? msg['receiverId'] : msg['senderId'];
        grouped.putIfAbsent(partnerId, () => []).add(msg);
      }

      // Fetch partner names and avatars
      final partnerIds = grouped.keys.toList();
      Map<String, String> nameMap = {};
      Map<String, String?> avatarMap = {};
      
      if (partnerIds.isNotEmpty) {
        final users = await ApiService.getUsersBatch(partnerIds);
        nameMap = {for (var u in users) u['id']: u['fullName']};
        avatarMap = {for (var u in users) u['id']: u['avatarUrl']};
      }

      // Create display list
      final List<Map<String, dynamic>> convs = [];
      for (var partnerId in grouped.keys) {
        // Sort individual messages by time to get the latest
        final convMessages = grouped[partnerId]!;
        convMessages.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
        
        final latest = convMessages.first;
        convs.add({
          'partnerId': partnerId,
          'partnerName': nameMap[partnerId] ?? 'User',
          'partnerAvatar': avatarMap[partnerId],
          'lastMessage': latest['content'],
          'time': latest['createdAt'],
          'isUnread': latest['receiverId'] == myId && !latest['isRead'],
        });
      }

      // Sort conversations by latest message time
      convs.sort((a, b) => DateTime.parse(b['time']).compareTo(DateTime.parse(a['time'])));

      if (mounted) {
        setState(() {
          _conversations = convs;
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
                      title: Text(conv['partnerName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(conv['lastMessage'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(_formatTime(conv['time']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
