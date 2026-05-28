import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../messaging/chat_screen.dart';
import '../../utils/url_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../course/course_video_player.dart';

class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  String? _instructorName;
  String? _instructorAvatar;
  bool _isFetchingTutor = false;
  List<dynamic> _reviews = [];
  bool _isFetchingReviews = true;
  bool _isEnrolled = false;
  bool _isCheckingEnrollment = true;

  @override
  void initState() {
    super.initState();
    _instructorName = widget.course['instructorName'];
    _instructorAvatar = widget.course['instructorAvatarUrl'];
    _recordView();
    if (_instructorName == null) {
      _fetchInstructorInfo();
    }
    _fetchReviews();
    _checkEnrollment();
  }

  Future<void> _checkEnrollment() async {
    final userId = SessionService().userId;
    if (userId == null) {
      if (mounted) setState(() => _isCheckingEnrollment = false);
      return;
    }
    if (userId == widget.course['instructorId']) {
      if (mounted) {
        setState(() {
          _isEnrolled = true;
          _isCheckingEnrollment = false;
        });
      }
      return;
    }
    
    try {
      final enrollments = await ApiService.getStudentEnrollments(userId);
      final isEnrolled = enrollments.any((e) => e['courseId'] == widget.course['id']);
      if (mounted) {
        setState(() {
          _isEnrolled = isEnrolled;
          _isCheckingEnrollment = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCheckingEnrollment = false);
    }
  }

  Future<void> _fetchReviews() async {
    try {
      final reviews = await ApiService.getCourseReviews(widget.course['id']);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isFetchingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingReviews = false);
    }
  }

  Future<void> _fetchInstructorInfo() async {
    final tutorId = widget.course['instructorId'];
    if (tutorId == null) return;
    
    setState(() => _isFetchingTutor = true);
    try {
      final user = await ApiService.getUserById(tutorId);
      if (mounted) {
        setState(() {
          _instructorName = user['fullName'];
          _instructorAvatar = user['avatarUrl'];
          _isFetchingTutor = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingTutor = false);
    }
  }

  void _recordView() {
    if (widget.course['id'] != null) {
      ApiService.recordCourseView(widget.course['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final course = widget.course;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(course['title'] ?? 'Course Details', style: const TextStyle(fontSize: 16)),
              background: Container(
                color: AppTheme.primaryPurple,
                child: const Icon(Icons.school, size: 100, color: Colors.white24),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Best Seller",
                          style: TextStyle(color: AppTheme.secondaryOrange, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, color: AppTheme.accentYellow, size: 20),
                      Text(" ${(course['averageRating'] ?? 0).toString()} (${course['reviewCount'] ?? 0} reviews)", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.message_rounded, color: AppTheme.primaryPurple),
                        onPressed: () => _startChat(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    course['title'] ?? 'Full Stack Development',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    course['description'] ?? 'Master the skills of modern web development with this comprehensive course.',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text("Instructor", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: (_instructorAvatar != null && _instructorAvatar!.isNotEmpty)
                          ? NetworkImage(UrlHelper.fixIp(_instructorAvatar!))
                          : const AssetImage('assets/images/tutor.png') as ImageProvider,
                    ),
                    title: Text(
                      _instructorName ?? 'Expert Tutor',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: const Text("Content Creator & Expert"),
                    trailing: OutlinedButton(
                      onPressed: () => _startChat(),
                      child: const Text("Message"),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text("Modules", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_isCheckingEnrollment)
                    const Center(child: CircularProgressIndicator())
                  else if (!_isEnrolled)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          children: [
                            const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text("Enroll in this course to view materials", style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    )
                  else if (course['materials'] != null && (course['materials'] as List).isNotEmpty)
                    ...List.generate((course['materials'] as List).length, (index) {
                      final mat = course['materials'][index];
                      return _buildModuleItem(context, "${index + 1}", mat['title'] ?? 'Lesson', mat['url'] ?? '', false);
                    })
                  else
                    const Center(child: Text('No course materials have been added yet.', style: TextStyle(color: Colors.grey))),
                    
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Reviews", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (SessionService().userId != null && SessionService().userId != course['instructorId'])
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text("Write Review"),
                          onPressed: () => _showReviewDialog(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isFetchingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    const Text('No reviews yet. Be the first to review!', style: TextStyle(color: Colors.grey))
                  else
                    ..._reviews.map((r) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(child: Text((r['userName'] as String?)?.substring(0, 1) ?? 'U')),
                          title: Row(
                            children: [
                              Text(r['userName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Icon(Icons.star, size: 14, color: AppTheme.accentYellow),
                              Text(" ${r['rating']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          subtitle: Text(r['comment'] ?? ''),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: ElevatedButton(
          onPressed: () async {
            final userId = SessionService().userId;
            if (userId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please sign in first")));
              return;
            }
            if (userId == course['instructorId']) {
              _showAddMaterialDialog();
            } else if (_isEnrolled) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You are already enrolled! Scroll up to view modules.")));
            } else {
              // Enroll
              try {
                await ApiService.enrollCourse(courseId: course['id'] ?? '', studentId: userId);
                if (context.mounted) {
                  setState(() {
                    _isEnrolled = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enrolled successfully!"), backgroundColor: AppTheme.successGreen));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.errorRed));
                }
              }
            }
          },
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: Text(SessionService().userId == course['instructorId'] 
              ? "ADD COURSE MATERIAL" 
              : _isEnrolled ? "TAKE COURSE" : "ENROLL NOW"),
        ),
      ),
    );
  }

  void _showAddMaterialDialog() {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    bool isUploading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add Course Material'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Material Title (e.g. Video 3)')),
              const SizedBox(height: 12),
              TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL (or select file below)')),
              const SizedBox(height: 16),
              isUploading 
                ? const CircularProgressIndicator()
                : OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload Video/PDF"),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.any);
                      if (result != null && result.files.single.path != null) {
                        setStateDialog(() => isUploading = true);
                        try {
                          final uploadedUrl = await ApiService.uploadCourseFile(result.files.single.path!);
                          setStateDialog(() {
                            urlCtrl.text = uploadedUrl;
                            isUploading = false;
                          });
                        } catch (e) {
                          setStateDialog(() => isUploading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                          }
                        }
                      }
                    },
                  )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;
                Navigator.pop(context);
              try {
                await ApiService.addCourseMaterial(
                  courseId: widget.course['id'],
                  title: titleCtrl.text,
                  url: urlCtrl.text,
                  type: 'video',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material added! Refresh to see changes.')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
              },
              child: const Text('Save Material'),
            ),
          ],
        ),
      ),
    );
  }

  void _startChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          partnerId: widget.course['instructorId'] ?? '',
          partnerName: _instructorName ?? 'Course Tutor',
          partnerAvatar: _instructorAvatar ?? '', 
        ),
      ),
    );
  }

  void _showReviewDialog() {
    final commentCtrl = TextEditingController();
    int rating = 5;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Text('Write a Review'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) => IconButton(
                    icon: Icon(index < rating ? Icons.star : Icons.star_border, color: AppTheme.accentYellow),
                    onPressed: () => setStateSB(() => rating = index + 1),
                  )),
                ),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Review Comment', border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final userId = SessionService().userId;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in first')));
                    return;
                  }
                  if (commentCtrl.text.trim().isEmpty) return;
                  
                  Navigator.pop(context);
                  try {
                    await ApiService.addCourseReview(
                      courseId: widget.course['id'],
                      userId: userId,
                      userName: SessionService().fullName ?? 'User',
                      rating: rating,
                      comment: commentCtrl.text.trim(),
                    );
                    _fetchReviews();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review added successfully!')));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildModuleItem(BuildContext context, String index, String title, String url, bool isCompleted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () async {
        if (url.isEmpty) return;
        final fixedUrl = UrlHelper.fixIp(url);
        
        final lowerUrl = fixedUrl.toLowerCase();
        if (lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.mov') || lowerUrl.endsWith('.avi') || lowerUrl.endsWith('.mkv')) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => CourseVideoPlayerScreen(videoUrl: fixedUrl, title: title)
          ));
          return;
        }

        final uri = Uri.parse(fixedUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: isCompleted ? AppTheme.successGreen : Colors.grey.shade300,
              child: Icon(isCompleted ? Icons.check : Icons.play_arrow, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Module $index: $title", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text("Video / PDF", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
