import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/session_service.dart';
import '../../services/api_service.dart';
import '../../utils/url_helper.dart';

class ChatScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String? partnerAvatar;
  
  const ChatScreen({
    super.key, 
    required this.partnerId, 
    required this.partnerName,
    this.partnerAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}


class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  List<dynamic> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    final myId = SessionService().userId;
    if (myId == null) return;

    try {
      final allMessages = await ApiService.getMessages(myId);
      // Filter for this specific conversation
      final filtered = allMessages.where((msg) {
        return (msg['senderId'] == myId && msg['receiverId'] == widget.partnerId) ||
               (msg['senderId'] == widget.partnerId && msg['receiverId'] == myId);
      }).toList();

      // Sort by time ascending for chat view
      filtered.sort((a, b) => DateTime.parse(a['createdAt']).compareTo(DateTime.parse(b['createdAt'])));

      if (mounted) {
        setState(() {
          _messages = filtered;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final myId = SessionService().userId;
    if (myId == null) return;

    // Optimistic UI update
    setState(() {
      _messages.add({
        'senderId': myId,
        'receiverId': widget.partnerId,
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
      });
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      await ApiService.sendMessage(
        senderId: myId,
        receiverId: widget.partnerId,
        content: content,
        senderName: SessionService().fullName,
      );
      // Re-fetch to ensure sync with server timestamps
      _fetchMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = SessionService().userId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
              backgroundImage: (widget.partnerAvatar != null && widget.partnerAvatar!.isNotEmpty)
                  ? NetworkImage(UrlHelper.fixIp(widget.partnerAvatar!)) as ImageProvider
                  : null,
              child: (widget.partnerAvatar == null || widget.partnerAvatar!.isEmpty)
                  ? Text(widget.partnerName[0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 14))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.partnerName)),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['senderId'] == myId;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isMe ? AppTheme.primaryPurple : (isDark ? AppTheme.cardDark : Colors.grey.shade200),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  msg['content'],
                                  style: TextStyle(color: isMe ? Colors.white : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))
              ]
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryPurple,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
