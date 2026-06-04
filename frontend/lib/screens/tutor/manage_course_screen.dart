import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../utils/url_helper.dart';
import '../course/course_video_player.dart';

class ManageCourseScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const ManageCourseScreen({super.key, required this.course});

  @override
  State<ManageCourseScreen> createState() => _ManageCourseScreenState();
}

class _ManageCourseScreenState extends State<ManageCourseScreen> {
  late Map<String, dynamic> _courseData;
  bool _isLoading = false;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _courseData = Map<String, dynamic>.from(widget.course);
    _refreshCourse();
  }

  Future<void> _refreshCourse() async {
    final courseId = _courseData['id'];
    if (courseId == null) return;

    setState(() => _isLoading = true);
    try {
      final updatedCourse = await ApiService.getCourseById(courseId);
      if (updatedCourse != null) {
        setState(() {
          _courseData = updatedCourse;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load course details: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<void> _deleteMaterial(int index, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Are you sure you want to delete "$title" from this course? This will remove the file permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);
    try {
      final courseId = _courseData['id'];
      await ApiService.deleteCourseMaterial(courseId: courseId, materialIndex: index);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "$title" successfully!'), backgroundColor: AppTheme.successGreen),
        );
      }
      _refreshCourse();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  void _showAddLessonBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddLessonBottomSheet(
        courseId: _courseData['id'],
        onSuccess: () {
          Navigator.pop(context);
          _refreshCourse();
        },
      ),
    );
  }

  void _viewMaterial(Map<String, dynamic> material) async {
    final String url = material['url'] ?? '';
    final String title = material['title'] ?? 'Lesson';
    if (url.isEmpty) return;

    final fixedUrl = UrlHelper.fixIp(url);
    final lowerUrl = fixedUrl.toLowerCase();

    if (lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.mov') || lowerUrl.endsWith('.avi') || lowerUrl.endsWith('.mkv')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseVideoPlayerScreen(videoUrl: fixedUrl, title: title),
        ),
      );
      return;
    }

    final uri = Uri.parse(fixedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final materials = _courseData['materials'] as List<dynamic>? ?? [];

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Beautiful Custom Header
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Header background image or gradient
                      if (_courseData['imageUrl'] != null && (_courseData['imageUrl'] as String).isNotEmpty)
                        Image.network(
                          UrlHelper.fixIp(_courseData['imageUrl']),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryPurple, Color(0xFF9F8BFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryPurple, Color(0xFF9F8BFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      // Dark Overlay for text legibility
                      Container(
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                      // Title and metadata inside header
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryOrange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _courseData['specialty'] ?? 'General',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _courseData['title'] ?? 'Untitled Course',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 4,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Course Specs and Info Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick info row
                      Row(
                        children: [
                          _buildSpecCard(
                            context,
                            icon: Icons.monetization_on_outlined,
                            title: 'Price',
                            value: '${_courseData['price']} fr',
                          ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2),
                          const SizedBox(width: 12),
                          _buildSpecCard(
                            context,
                            icon: Icons.layers_outlined,
                            title: 'Level',
                            value: 'Level ${_courseData['level'] ?? 1}',
                          ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: 0.2),
                          const SizedBox(width: 12),
                          _buildSpecCard(
                            context,
                            icon: Icons.class_outlined,
                            title: 'Lessons',
                            value: '${materials.length} modules',
                          ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideX(begin: 0.2),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      if (_courseData['description'] != null && (_courseData['description'] as String).isNotEmpty) ...[
                        const Text(
                          'Course Description',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _courseData['description'],
                          style: TextStyle(
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Materials Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Course Materials',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Lesson'),
                            onPressed: _showAddLessonBottomSheet,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Materials List
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (materials.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 64,
                            color: isDark ? Colors.white30 : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Lessons Uploaded yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Provide files such as PDFs and video lessons so enrolled students can start learning.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showAddLessonBottomSheet,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('UPLOAD FIRST LESSON'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final mat = materials[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: _buildMaterialCard(context, mat, index),
                      );
                    },
                    childCount: materials.length,
                  ),
                ),
              
              // Bottom spacing padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              )
            ],
          ),

          // Loading overlay during deletion/actions
          if (_isActionLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryPurple, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialCard(BuildContext context, Map<String, dynamic> mat, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = mat['type'] ?? 'video';
    final title = mat['title'] ?? 'Lesson ${index + 1}';

    IconData iconData;
    Color iconColor;

    if (type == 'pdf') {
      iconData = Icons.picture_as_pdf;
      iconColor = AppTheme.errorRed;
    } else if (type == 'document') {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else {
      iconData = Icons.play_circle_fill;
      iconColor = AppTheme.primaryPurple;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
      ),
      child: InkWell(
        onTap: () => _viewMaterial(mat),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),

              // Title and category details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Delete action button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                onPressed: () => _deleteMaterial(index, title),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms, delay: (index * 50).ms).slideY(begin: 0.1);
  }
}

class _AddLessonBottomSheet extends StatefulWidget {
  final String courseId;
  final VoidCallback onSuccess;

  const _AddLessonBottomSheet({
    required this.courseId,
    required this.onSuccess,
  });

  @override
  State<_AddLessonBottomSheet> createState() => _AddLessonBottomSheetState();
}

class _AddLessonBottomSheetState extends State<_AddLessonBottomSheet> {
  final _titleController = TextEditingController();
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  String _statusText = '';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'mp4', 'mov', 'avi', 'txt', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
          // Pre-populate title field if empty
          if (_titleController.text.trim().isEmpty) {
            _titleController.text = _pickedFile!.name.split('.').first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<void> _uploadLesson() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a lesson title'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }

    if (_pickedFile == null || _pickedFile!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a file to upload'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _statusText = 'Uploading file to server...';
    });

    try {
      // 1. Upload physical file
      final fileUrl = await ApiService.uploadCourseFile(_pickedFile!.path!);
      
      setState(() {
        _statusText = 'Registering lesson details...';
      });

      // 2. Determine type
      String type = 'video';
      final extension = _pickedFile!.extension?.toLowerCase();
      if (extension == 'pdf') {
        type = 'pdf';
      } else if (['txt', 'doc', 'docx'].contains(extension)) {
        type = 'document';
      }

      // 3. Save material in database
      await ApiService.addCourseMaterial(
        courseId: widget.courseId,
        title: title,
        url: fileUrl,
        type: type,
      );

      widget.onSuccess();
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + keyboardSpace,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add New Lesson',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            if (_isUploading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Please wait, uploading...',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Text(
                  _statusText,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Lesson Title Input
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Lesson Title',
                  hintText: 'e.g., Introduction to Accounting',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),

              // File selection card
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _pickedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                        color: _pickedFile != null ? AppTheme.successGreen : AppTheme.primaryPurple,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pickedFile != null ? _pickedFile!.name : 'Choose Course File',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _pickedFile != null
                                    ? (isDark ? Colors.white : Colors.black)
                                    : Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _pickedFile != null
                                  ? '${(_pickedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB'
                                  : 'Supports PDFs, Video files (MP4, MOV, etc.)',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (_pickedFile != null)
                        TextButton(
                          onPressed: () => setState(() => _pickedFile = null),
                          child: const Text('Change'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _uploadLesson,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('UPLOAD'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
