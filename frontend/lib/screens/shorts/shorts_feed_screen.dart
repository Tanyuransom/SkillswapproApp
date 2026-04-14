import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/session_service.dart';

import 'package:skill_swap_pro/services/api_service.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/url_helper.dart';

class ShortsFeedScreen extends StatefulWidget {
  const ShortsFeedScreen({super.key});

  @override
  State<ShortsFeedScreen> createState() => _ShortsFeedScreenState();
}

class _ShortsFeedScreenState extends State<ShortsFeedScreen> {
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  List<dynamic> _shorts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchShorts();
  }

  Future<void> _fetchShorts() async {
    try {
      final shorts = await ApiService.getShorts();
      if (mounted) {
        setState(() {
          _shorts = shorts;
          _isLoading = false;
        });
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

    // Show description dialog
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
      // 1. Upload Video File
      final String videoUrl = await ApiService.uploadVideo(file.path);

      // 2. Create Short Metadata
      await ApiService.createShort(
        tutorId: session.userId ?? 'anonymous',
        tutorName: session.fullName ?? 'SkillProf Tutor',
        courseName: 'SkillProf Tips',
        description: descriptionController.text.trim().isEmpty 
            ? 'New tip uploaded'
            : descriptionController.text.trim(),
        videoUrl: videoUrl,
        tutorAvatarUrl: session.avatarUrl,
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
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _shorts.length,
                  itemBuilder: (context, index) {
                    final short = _shorts[index];
                    // Adapt API response to expected UI format
                    final videoData = {
                      'tutor': short['tutorName'] ?? '@Tutor',
                      'course': short['courseName'] ?? 'Tips',
                      'description': short['description'] ?? '',
                      'likes': short['likes']?.toString() ?? '0',
                      'comments': short['comments']?.toString() ?? '0',
                      'videoUrl': UrlHelper.fixIp(short['videoUrl'] as String? ?? ''),
                      'tutorAvatarUrl': UrlHelper.fixIp(short['tutorAvatarUrl'] as String? ?? ''),
                      'isVerified': true,
                    };
                    return VideoFeedItem(videoData: videoData);
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
            onPressed: _showUploadDialog,
            backgroundColor: AppTheme.secondaryOrange,
            child: const Icon(Icons.add_a_photo, color: Colors.white),
          )
        : null,
    );
  }
}

class VideoFeedItem extends StatefulWidget {
  final Map<String, dynamic> videoData;

  const VideoFeedItem({super.key, required this.videoData});

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  late VideoPlayerController _controller;
  bool _isError = false;
  bool _isPlaying = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(UrlHelper.fixIp(widget.videoData['videoUrl'] as String)))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.setLooping(true);
          _controller.play();
          _isPlaying = true;
        }
      }).catchError((e) {
        if (mounted) setState(() => _isError = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: _isError 
              ? Container(color: Colors.black, child: const Center(child: Icon(Icons.error_outline, color: Colors.white, size: 40)))
              : _controller.value.isInitialized
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

        if (!_isPlaying && !_isError)
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
                onTap: () => setState(() => _isFavorite = !_isFavorite),
                child: _buildActionIcon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border, 
                  widget.videoData['likes'],
                  color: _isFavorite ? AppTheme.errorRed : Colors.white
                ),
              ),
              const SizedBox(height: 20),
              _buildActionIcon(Icons.comment_rounded, widget.videoData['comments']),
              const SizedBox(height: 20),
              _buildActionIcon(Icons.share_rounded, 'Share'),
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
    return Container(
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

