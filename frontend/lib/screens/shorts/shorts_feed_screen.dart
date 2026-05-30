import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/session_service.dart';
import 'upload_short_screen.dart';

import 'package:skill_swap_pro/services/api_service.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/url_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ShortsFeedScreen extends StatefulWidget {
  final String? initialShortId;
  const ShortsFeedScreen({super.key, this.initialShortId});

  @override
  State<ShortsFeedScreen> createState() => _ShortsFeedScreenState();
}

class _ShortsFeedScreenState extends State<ShortsFeedScreen> {
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  List<dynamic> _shorts = [];
  bool _isLoading = true;
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    _fetchShorts();
  }

  Future<void> _fetchShorts() async {
    try {
      final session = SessionService();
      await session.init();
      
      final specialtyFilter = session.academicSpecialty;
      
      final shorts = await ApiService.getShorts(
        level: session.academicLevel,
        specialty: specialtyFilter,
      );
      if (mounted) {
        setState(() {
          _shorts = shorts;
          _isLoading = false;
        });

        // Jump to initial short if provided
        if (widget.initialShortId != null) {
          final index = _shorts.indexWhere((s) => s['id'] == widget.initialShortId);
          if (index != -1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(index);
                setState(() => _activePage = index);
              }
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUploadDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Share a Tip", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.videocam, color: AppTheme.primaryPurple),
              title: const Text("Record with Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.collections, color: AppTheme.primaryPurple),
              title: const Text("Pick from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _pickAndUpload(ImageSource source) async {
    final XFile? file = await _picker.pickVideo(source: source);
    if (file == null) return;

    final TextEditingController descriptionController = TextEditingController();
    
    if (!mounted) return;

    final bool? shouldPublish = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Add Tip Description"),
        content: TextField(
          controller: descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "What is this tip about?",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: AppTheme.errorRed)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Publish"),
          ),
        ],
      ),
    );

    if (shouldPublish != true) return;

    final session = SessionService();
    setState(() => _isUploading = true);

    try {
      final String videoUrl = await ApiService.uploadVideo(file.path);
      await ApiService.createShort(
        tutorId: session.userId ?? 'anonymous',
        tutorName: session.fullName ?? 'SkillProf Tutor',
        courseName: 'SkillProf Tips',
        description: descriptionController.text.trim().isEmpty 
            ? 'New tip uploaded'
            : descriptionController.text.trim(),
        videoUrl: videoUrl,
        tutorAvatarUrl: session.avatarUrl,
        level: session.academicLevel,
        specialty: session.academicSpecialty,
      );
      
      _fetchShorts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tip Published!"), backgroundColor: AppTheme.successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload Error: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionService();
    
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchShorts,
            color: AppTheme.secondaryOrange,
            child: _shorts.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_library_outlined, size: 60, color: Colors.white38),
                          SizedBox(height: 16),
                          Text("no shorts yet", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (index) => setState(() => _activePage = index),
                  itemCount: _shorts.length,
                  itemBuilder: (context, index) {
                    final short = _shorts[index];
                    final videoData = {
                      'id': short['id'],
                      'tutorId': short['tutorId'],
                      'tutor': short['tutorName'] ?? '@Tutor',
                      'course': short['courseName'] ?? 'Tips',
                      'description': short['description'] ?? '',
                      'likes': short['likes']?.toString() ?? '0',
                      'comments': short['comments']?.toString() ?? '0',
                      'videoUrl': UrlHelper.fixIp(short['videoUrl'] as String? ?? ''),
                      'tutorAvatarUrl': UrlHelper.fixIp(short['tutorAvatarUrl'] as String? ?? ''),
                      'isVerified': true,
                      'isLiked': short['isLiked'] ?? false,
                    };
                    return VideoFeedItem(
                      videoData: videoData,
                      isActive: index == _activePage,
                      onDelete: () async {
                        try {
                          await ApiService.deleteShort(short['id']);
                          _fetchShorts();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Short deleted successfully"), backgroundColor: AppTheme.successGreen),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.errorRed),
                          );
                        }
                      },
                      onLikeToggled: (newCount, isLiked) {
                        setState(() {
                          _shorts[index]['likes'] = newCount;
                          _shorts[index]['isLiked'] = isLiked;
                        });
                      },
                      onCommentAdded: (newCount) {
                        setState(() {
                          _shorts[index]['comments'] = newCount;
                        });
                      },
                    );
                  },
                ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Discover Shorts",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white, size: 28),
                    onPressed: () {},
                  )
                ],
              ),
            ),
          ),

          if (_isUploading)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryOrange),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: session.isTutor 
        ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadShortScreen()),
              ).then((uploaded) {
                if (uploaded == true) {
                  _fetchShorts();
                }
              });
            },
            backgroundColor: AppTheme.secondaryOrange,
            child: const Icon(Icons.add_a_photo, color: Colors.white),
          )
        : null,
    );
  }
}

class VideoFeedItem extends StatefulWidget {
  final Map<String, dynamic> videoData;
  final bool isActive;
  final VoidCallback? onDelete;
  final Function(int, bool)? onLikeToggled;
  final Function(int)? onCommentAdded;

  const VideoFeedItem({
    super.key, 
    required this.videoData, 
    required this.isActive, 
    this.onDelete,
    this.onLikeToggled,
    this.onCommentAdded,
  });

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  late VideoPlayerController _controller;
  bool _isError = false;
  bool _isInitialized = false;
  bool _isFavorite = false;
  bool _isFollowingTutor = false;
  bool _isCheckingFollowTutor = true;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.videoData['isLiked'] ?? false;
    _initializeController();
    _checkFollowTutorStatus();
  }

  void _checkFollowTutorStatus() async {
    final followerId = SessionService().userId;
    final tutorId = widget.videoData['tutorId'];
    if (followerId == null || tutorId == null || followerId == tutorId) {
      if (mounted) setState(() => _isCheckingFollowTutor = false);
      return;
    }
    try {
      final isFollowing = await ApiService.checkFollowStatus(
        followerId: followerId,
        tutorId: tutorId,
      );
      if (mounted) {
        setState(() {
          _isFollowingTutor = isFollowing;
          _isCheckingFollowTutor = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCheckingFollowTutor = false);
    }
  }

  void _toggleFollowTutor() async {
    final followerId = SessionService().userId;
    final tutorId = widget.videoData['tutorId'];
    if (followerId == null || tutorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please sign in to follow")));
      return;
    }

    try {
      await ApiService.followTutor(followerId: followerId, tutorId: tutorId);
      if (mounted) {
        setState(() {
          _isFollowingTutor = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Followed ${widget.videoData['tutor']}!"),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  void _initializeController() {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoData['videoUrl'] as String),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() => _isInitialized = true);
        _controller.setLooping(true);
        if (widget.isActive) _controller.play();
      }
    }).catchError((e) {
      if (mounted) setState(() => _isError = true);
    });
  }

  @override
  void didUpdateWidget(VideoFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.play();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleLike() async {
    final userId = SessionService().userId;
    if (userId == null) return;
    
    setState(() => _isFavorite = !_isFavorite);
    try {
      final res = await ApiService.toggleLike(
        userId: userId,
        targetId: widget.videoData['id'],
        targetType: 'short',
      );
      setState(() {
        widget.videoData['likes'] = res['likesCount'].toString();
      });
      if (widget.onLikeToggled != null) {
        widget.onLikeToggled!(res['likesCount'], _isFavorite);
      }
    } catch (e) {
      setState(() => _isFavorite = !_isFavorite); // Revert
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentsSheet(
        shortId: widget.videoData['id'],
        onCommentAdded: () {
          final count = int.parse(widget.videoData['comments'].toString());
          final newCount = count + 1;
          setState(() {
            widget.videoData['comments'] = newCount.toString();
          });
          if (widget.onCommentAdded != null) {
            widget.onCommentAdded!(newCount);
          }
        },
      ),
    );
  }

  bool _showHeart = false;

  void _onDoubleTap() {
    if (!_isFavorite) {
      _toggleLike();
    }
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            });
          },
          onDoubleTap: _onDoubleTap,
          child: _isError 
              ? Container(color: Colors.black, child: const Center(child: Icon(Icons.error_outline, color: Colors.white, size: 40)))
              : _isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
        
        if (_showHeart)
          Center(
            child: const Icon(Icons.favorite, color: Colors.white, size: 100)
                .animate()
                .scale(begin: const Offset(0.2, 0.2), end: const Offset(1.2, 1.2), duration: 200.ms, curve: Curves.easeOutBack)
                .fadeOut(delay: 500.ms, duration: 300.ms),
          ),
        
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.6),
              ],
              stops: const [0.0, 0.5, 1.0],
            )
          ),
        ),

        if (_isInitialized && !_controller.value.isPlaying && !_isError)
          const Center(
            child: Icon(Icons.play_arrow_rounded, color: Colors.white54, size: 80),
          ),
        
        Positioned(
          right: 16,
          bottom: 100, 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildProfileIcon(),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _toggleLike,
                child: _buildActionIcon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border, 
                  widget.videoData['likes'].toString(),
                  color: _isFavorite ? AppTheme.errorRed : Colors.white
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showComments,
                child: _buildActionIcon(Icons.comment_rounded, widget.videoData['comments'].toString()),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  final userId = SessionService().userId;
                  if (userId != null) {
                    ApiService.recordShare(
                      userId: userId,
                      targetId: widget.videoData['id'],
                      targetType: 'short',
                    );
                  }
                  Share.share('Check out this tip from ${widget.videoData['tutor']} on SkillProf: ${widget.videoData['description']}');
                },
                child: _buildActionIcon(Icons.share_rounded, 'Share'),
              ),
              
              if (SessionService().userId == widget.videoData['tutorId']) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Delete Short?"),
                        content: const Text("Are you sure you want to delete this short?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                        ],
                      )
                    );
                    if (confirm == true && widget.onDelete != null) {
                      widget.onDelete!();
                    }
                  },
                  child: _buildActionIcon(Icons.delete_outline, 'Delete', color: Colors.redAccent),
                ),
              ]
            ],
          ),
        ),

        Positioned(
          left: 16,
          bottom: 100,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.videoData['tutor'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (widget.videoData['isVerified'] == true) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, color: AppTheme.accentYellow, size: 16),
                  ]
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryOrange.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.videoData['course'],
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.videoData['description'],
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildProfileIcon() {
    final avatarUrl = widget.videoData['tutorAvatarUrl'];
    final followerId = SessionService().userId;
    final tutorId = widget.videoData['tutorId'];
    
    final showFollowButton = followerId != null &&
        tutorId != null &&
        followerId != tutorId &&
        !_isCheckingFollowTutor &&
        !_isFollowingTutor;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: Colors.white, shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            image: DecorationImage(
              image: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl) as ImageProvider
                  : const AssetImage('assets/images/tutor.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showFollowButton)
          Positioned(
            bottom: -6,
            child: GestureDetector(
              onTap: _toggleFollowTutor,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppTheme.secondaryOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label, {Color color = Colors.white}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final String shortId;
  final VoidCallback? onCommentAdded;
  const _CommentsSheet({required this.shortId, this.onCommentAdded});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentCtrl = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await ApiService.getComments(
        targetId: widget.shortId,
        targetType: 'short',
      );
      if (mounted) setState(() { _comments = comments; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final session = SessionService();
    if (session.userId == null) return;

    _commentCtrl.clear();
    try {
      await ApiService.addComment(
        userId: session.userId!,
        userName: session.fullName ?? 'User',
        targetId: widget.shortId,
        targetType: 'short',
        text: text,
      );
      if (widget.onCommentAdded != null) widget.onCommentAdded!();
      _fetchComments();
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
          ),
          const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Divider(),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty
                ? const Center(child: Text("No comments yet", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (ctx, i) {
                      final c = _comments[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text(c['userName']?.substring(0, 1) ?? 'U')),
                        title: Text(c['userName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(c['text'] ?? ''),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 8, bottom: MediaQuery.of(context).viewInsets.bottom + 16
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.primaryPurple),
                  onPressed: _postComment,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

