import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';
import '../../../services/session_service.dart';
import '../../../utils/url_helper.dart';

class BlogDetailScreen extends StatefulWidget {
  final dynamic blog;

  const BlogDetailScreen({super.key, required this.blog});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoadingComments = true;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await ApiService.getComments(widget.blog['id'], 'blog');
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> _submitComment() async {
    final session = SessionService();
    if (!session.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to write a comment")),
      );
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingComment = true);

    try {
      final newComment = await ApiService.addComment(
        userId: session.userId!,
        userName: session.fullName ?? 'User',
        targetId: widget.blog['id'],
        targetType: 'blog',
        text: text,
      );

      _commentController.clear();
      _fetchComments(); // Reload comments
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to post comment: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  Future<void> _deleteComment(String id) async {
    try {
      final success = await ApiService.deleteComment(id);
      if (success) {
        _fetchComments(); // Reload
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Comment deleted"), backgroundColor: AppTheme.successGreen),
          );
        }
      } else {
        throw Exception("Delete request failed");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete comment: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final dt = DateTime.parse(dateString).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return "${months[dt.month - 1]} ${dt.day}, ${dt.year}";
    } catch (_) {
      return "Recent";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = SessionService();
    final blog = widget.blog;
    final hasImage = blog['imageUrl'] != null && (blog['imageUrl'] as String).isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Cover Image / Custom AppBar
          SliverAppBar(
            expandedHeight: 240.0,
            floating: false,
            pinned: true,
            stretch: true,
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.primaryPurple,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  hasImage
                      ? Image.network(
                          UrlHelper.fixIp(blog['imageUrl']),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildDefaultCover(),
                        )
                      : _buildDefaultCover(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryOrange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (blog['category'] ?? 'General').toString().toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          blog['title'] ?? 'Untitled Article',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // Content body
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author Block
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.1),
                          backgroundImage: blog['authorAvatarUrl'] != null && blog['authorAvatarUrl'].isNotEmpty
                              ? NetworkImage(UrlHelper.fixIp(blog['authorAvatarUrl']))
                              : null,
                          child: blog['authorAvatarUrl'] == null || blog['authorAvatarUrl'].isEmpty
                              ? const Icon(Icons.person, color: AppTheme.primaryPurple)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                blog['authorName'] ?? 'Anonymous Author',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    _formatDate(blog['createdAt'] ?? ''),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.circle, size: 4, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    blog['readTime'] ?? '3 min read',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Article text content
                    Text(
                      blog['content'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        height: 1.7,
                        color: isDark ? Colors.grey.shade300 : Colors.black87,
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 32),
                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    // Comments section header
                    Text(
                      "Comments (${_comments.length})",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Comments list
                    _isLoadingComments
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _comments.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded, size: 36, color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "No comments yet. Start the conversation!",
                                        style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _comments.length,
                                itemBuilder: (context, index) {
                                  final comment = _comments[index];
                                  final isOwn = session.isLoggedIn && session.userId == comment['userId'];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.cardDark : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.1),
                                          child: const Icon(Icons.person, size: 16, color: AppTheme.primaryPurple),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    comment['userName'] ?? 'User',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                  if (isOwn)
                                                    GestureDetector(
                                                      onTap: () => _deleteComment(comment['id']),
                                                      child: const Icon(Icons.delete_outline, size: 16, color: AppTheme.errorRed),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                comment['text'] ?? '',
                                                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.black87),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),

                    const SizedBox(height: 16),

                    // Add Comment Form
                    if (session.isLoggedIn)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: "Write a comment...",
                                hintStyle: const TextStyle(fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isSubmittingComment
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.primaryPurple,
                                  child: IconButton(
                                    icon: const Icon(Icons.send, color: Colors.white, size: 16),
                                    onPressed: _submitComment,
                                  ),
                                )
                        ],
                      )
                    else
                      Center(
                        child: Text(
                          "Log in to share your thoughts.",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ]),
          )
        ],
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryPurple, AppTheme.secondaryOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, color: Colors.white24, size: 80),
      ),
    );
  }
}
