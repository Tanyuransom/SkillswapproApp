import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';

class UploadShortScreen extends StatefulWidget {
  const UploadShortScreen({super.key});

  @override
  State<UploadShortScreen> createState() => _UploadShortScreenState();
}

class _UploadShortScreenState extends State<UploadShortScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _courseNameController = TextEditingController();
  XFile? _selectedVideo;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _selectedCategoryId;
  List<dynamic> _categories = [];
  bool _isManuallyEnteringCategory = false;
  final _newCategoryController = TextEditingController();
  int _selectedLevel = 1;
  String? _selectedSpecialty;
  final List<String> _specialties = ['ICT', 'ISN', 'CS', 'SEN', 'CYS', 'REN', 'JMC', 'BMS'];

  List<dynamic> _coursesForLevelAndSpecialty = [];
  String? _selectedCourseId;
  bool _isLoadingCourses = false;

  @override
  void initState() {
    super.initState();
    final session = SessionService();
    _selectedLevel = session.academicLevel;
    _selectedSpecialty = session.academicSpecialty;
    _fetchCategories();
    _fetchCoursesForShort();
  }

  void _fetchCoursesForShort() async {
    setState(() => _isLoadingCourses = true);
    try {
      final courses = await ApiService.getCourses(
        level: _selectedLevel,
        specialty: _selectedSpecialty,
      );
      if (mounted) {
        setState(() {
          _coursesForLevelAndSpecialty = courses;
          // Reset selected course if it's no longer in the filtered list
          if (_selectedCourseId != null &&
              !courses.any((c) => c['id'] == _selectedCourseId)) {
            _selectedCourseId = null;
            _courseNameController.clear();
          }
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  void _fetchCategories() async {
    try {
      final cats = await ApiService.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (e) {
      // Silent
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (pickedFile != null) {
      setState(() => _selectedVideo = pickedFile);
    }
  }

  Future<void> _uploadShort() async {
    if (_selectedVideo == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video and enter a title')),
      );
      return;
    }

    final tutorId = SessionService().userId;
    if (tutorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Not authenticated')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.2;
    });

    try {
      final videoUrl = await ApiService.uploadVideo(_selectedVideo!.path);
      setState(() => _uploadProgress = 0.7);

      String? catId = _selectedCategoryId;
      if (_isManuallyEnteringCategory && _newCategoryController.text.trim().isNotEmpty) {
        final newCat = await ApiService.createCategory(_newCategoryController.text.trim());
        catId = newCat['id'];
      }

      await ApiService.createShort(
        tutorId: tutorId,
        videoUrl: videoUrl,
        tutorName: SessionService().fullName ?? 'Tutor',
        courseName: _courseNameController.text.isNotEmpty
            ? _courseNameController.text
            : 'General Tips',
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : _titleController.text,
        level: _selectedLevel,
        specialty: _selectedSpecialty,
        categoryId: catId,
      );

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Short uploaded successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Short')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Video Picker ──────────────────────────────────────────
              GestureDetector(
                onTap: _isUploading ? null : _pickVideo,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A3C) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedVideo != null
                          ? AppTheme.primaryPurple
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedVideo != null
                              ? Icons.video_collection
                              : Icons.video_call,
                          size: 44,
                          color: _selectedVideo != null
                              ? AppTheme.primaryPurple
                              : Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _selectedVideo != null
                              ? 'Video Selected ✓'
                              : 'Tap to select video',
                          style: TextStyle(
                            color: _selectedVideo != null
                                ? AppTheme.primaryPurple
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.secondaryOrange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.secondaryOrange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Tip: Videos are limited to 60 seconds. Shorter videos upload significantly faster!",
                        style: TextStyle(color: AppTheme.secondaryOrange, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Title ─────────────────────────────────────────────────
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Short Title',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isUploading,
              ),

              const SizedBox(height: 12),

              // ── Description ───────────────────────────────────────────
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description / Topics (Optional)',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isUploading,
              ),

              const SizedBox(height: 12),

              // ── Category ──────────────────────────────────────────────
              if (!_isManuallyEnteringCategory)
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories
                      .map((cat) => DropdownMenuItem(
                            value: cat['id'] as String,
                            child: Text(cat['name'] as String),
                          ))
                      .toList(),
                  onChanged: _isUploading
                      ? null
                      : (val) => setState(() => _selectedCategoryId = val),
                )
              else
                TextField(
                  controller: _newCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'New Category Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.add_box),
                  ),
                  enabled: !_isUploading,
                ),

              TextButton(
                onPressed: () => setState(
                    () => _isManuallyEnteringCategory = !_isManuallyEnteringCategory),
                child: Text(
                  _isManuallyEnteringCategory
                      ? 'Select Existing Category'
                      : 'Category not listed? Add manually',
                  style: const TextStyle(fontSize: 12),
                ),
              ),

              const SizedBox(height: 4),

              // ── Level ─────────────────────────────────────────────────
              DropdownButtonFormField<int>(
                initialValue: _selectedLevel,
                decoration: const InputDecoration(
                  labelText: 'Target Level (University Year)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.layers),
                ),
                items: [1, 2, 3, 4]
                    .map((l) => DropdownMenuItem(value: l, child: Text('Level $l')))
                    .toList(),
                onChanged: _isUploading
                    ? null
                    : (val) {
                        setState(() => _selectedLevel = val ?? 1);
                        _fetchCoursesForShort();
                      },
              ),

              const SizedBox(height: 12),

              // ── Specialty ─────────────────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _selectedSpecialty,
                decoration: const InputDecoration(
                  labelText: 'Specialty',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                items: [
                  const DropdownMenuItem<String>(
                      value: null, child: Text('All Specialties')),
                  ..._specialties
                      .map((s) => DropdownMenuItem(value: s, child: Text(s))),
                ],
                onChanged: _isUploading
                    ? null
                    : (val) {
                        setState(() {
                          _selectedSpecialty = val;
                          _selectedCourseId = null;
                          _courseNameController.clear();
                        });
                        _fetchCoursesForShort();
                      },
              ),

              const SizedBox(height: 12),

              // ── Target Course (filtered by level + specialty) ──────────
              if (_isLoadingCourses)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedCourseId,
                  decoration: InputDecoration(
                    labelText: _coursesForLevelAndSpecialty.isEmpty
                        ? 'No courses for selected filters'
                        : 'Target Course (${_coursesForLevelAndSpecialty.length})',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.book),
                  ),
                  items: _coursesForLevelAndSpecialty.map((c) {
                    final t = (c['title'] ?? '') as String;
                    return DropdownMenuItem<String>(
                      value: c['id'] as String,
                      child: Text(
                        t.length > 38 ? '${t.substring(0, 35)}...' : t,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: _coursesForLevelAndSpecialty.isEmpty || _isUploading
                      ? null
                      : (val) {
                          if (val == null) return;
                          setState(() {
                            _selectedCourseId = val;
                            final sc = _coursesForLevelAndSpecialty
                                .firstWhere((c) => c['id'] == val);
                            _courseNameController.text = sc['title'] ?? '';
                            if (sc['categoryId'] != null) {
                              _selectedCategoryId = sc['categoryId'];
                            }
                          });
                        },
                ),

              const SizedBox(height: 12),

              // ── Manual Course Name ─────────────────────────────────────
              TextField(
                controller: _courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Or Type Course Name Manually',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isUploading,
              ),

              const SizedBox(height: 28),

              // ── Progress / Publish ─────────────────────────────────────
              if (_isUploading) ...[
                LinearProgressIndicator(
                    value: _uploadProgress, color: AppTheme.primaryPurple),
                const SizedBox(height: 10),
                const Center(child: Text('Uploading Short... Please wait.')),
              ] else
                ElevatedButton(
                  onPressed: _uploadShort,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryPurple,
                  ),
                  child: const Text('PUBLISH SHORT',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
