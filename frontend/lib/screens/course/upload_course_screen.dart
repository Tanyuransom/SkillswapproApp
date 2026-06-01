import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';

class UploadCourseScreen extends StatefulWidget {
  const UploadCourseScreen({super.key});

  @override
  State<UploadCourseScreen> createState() => _UploadCourseScreenState();
}

class _UploadCourseScreenState extends State<UploadCourseScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _newCategoryController = TextEditingController();
  
  String? _selectedCategoryId;
  List<dynamic> _categories = [];
  File? _imageFile;
  final List<Map<String, dynamic>> _materials = []; // { 'title': '', 'path': '', 'type': '' }
  bool _isLoading = false;
  bool _isManuallyEnteringCategory = false;
  int _selectedLevel = 1;
  String? _selectedSpecialty;
  final ImagePicker _picker = ImagePicker();

  // Recommended courses
  List<dynamic> _recommendedCourses = [];
  String? _selectedRelatedCourseId;
  bool _isLoadingCourses = false;
  bool _showAllCourses = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }
  final session = SessionService();

  @override
  void initState() {
    super.initState();
    _selectedLevel = session.academicLevel;
    _selectedSpecialty = session.academicSpecialty;
    _fetchCategories();
    _fetchRecommendedCourses();
  }

  void _fetchRecommendedCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final courses = await ApiService.getCourses(
        level: _selectedLevel,
        specialty: _showAllCourses ? null : _selectedSpecialty,
      );
      if (mounted) {
        setState(() {
          _recommendedCourses = courses;
          if (_selectedRelatedCourseId != null &&
              !courses.any((c) => c['id'] == _selectedRelatedCourseId)) {
            _selectedRelatedCourseId = null;
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
      setState(() => _categories = cats);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _pickMaterial() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'mp4', 'mov', 'avi', 'txt', 'doc', 'docx'],
      );

      if (result != null) {
        final file = result.files.first;
        String type = 'video';
        if (file.extension == 'pdf') {
          type = 'pdf';
        } else if (['txt', 'doc', 'docx'].contains(file.extension)) type = 'document';
        
        setState(() {
          _materials.add({
            'title': file.name.split('.').first,
            'path': file.path!,
            'type': type,
          });
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking material: $e')));
    }
  }

  void _uploadCourse() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final priceStr = _priceController.text.trim();
    final newCatName = _newCategoryController.text.trim();
    final tutorId = session.userId;
    if (tutorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }

    if (title.isEmpty || description.isEmpty || priceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (!_isManuallyEnteringCategory && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final price = double.tryParse(priceStr);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid price format')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? catId = _selectedCategoryId;

      // 1. Handle new category
      if (_isManuallyEnteringCategory && newCatName.isNotEmpty) {
        final newCat = await ApiService.createCategory(newCatName);
        catId = newCat['id'];
      }

      // 2. Upload cover image
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await ApiService.uploadCourseImage(_imageFile!.path);
      } else {
        imageUrl = "/uploads/courses/placeholder.png"; 
      }

      // 3. Create Course
      final course = await ApiService.createCourse(
        title: title,
        description: description,
        price: price,
        instructorId: tutorId,
        categoryId: catId,
        imageUrl: imageUrl,
        level: _selectedLevel,
        specialty: _selectedSpecialty,
        instructorName: session.fullName ?? 'Tutor',
        instructorAvatarUrl: session.avatarUrl,
      );

      final courseId = course['id'];

      // 4. Upload Materials
      for (var mat in _materials) {
        // Update UI to show progress for this material (optional enhancement)
        final fileUrl = await ApiService.uploadCourseFile(mat['path']);
        await ApiService.addCourseMaterial(
          courseId: courseId,
          title: mat['title'],
          url: fileUrl,
          type: mat['type'],
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course and Materials Uploaded Successfully!'), backgroundColor: AppTheme.successGreen));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload New Course')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Picker Section
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Gallery'),
                          onTap: () {
                            _pickImage(ImageSource.gallery);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_camera),
                          title: const Text('Camera'),
                          onTap: () {
                            _pickImage(ImageSource.camera);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('Add Course Cover Image', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Course Title', prefixIcon: Icon(Icons.title)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Course Description', prefixIcon: Icon(Icons.description)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price (FR)', prefixIcon: Icon(Icons.monetization_on)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      if (!_isManuallyEnteringCategory)
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategoryId,
                          decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
                          items: _categories.map((cat) => DropdownMenuItem(
                            value: cat['id'] as String,
                            child: Text(cat['name'] as String),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        )
                      else
                        TextField(
                          controller: _newCategoryController,
                          decoration: const InputDecoration(labelText: 'New Category Name', prefixIcon: Icon(Icons.add_box)),
                        ),
                      TextButton(
                        onPressed: () => setState(() => _isManuallyEnteringCategory = !_isManuallyEnteringCategory),
                        child: Text(_isManuallyEnteringCategory ? "Select Existing" : "Manual Input?", style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _selectedLevel,
              decoration: const InputDecoration(labelText: 'University Level', prefixIcon: Icon(Icons.layers)),
              items: [1, 2, 3, 4].map((l) => DropdownMenuItem(
                value: l,
                child: Text('Level $l'),
              )).toList(),
              onChanged: (val) => setState(() => _selectedLevel = val ?? 1),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _selectedSpecialty ?? 'SEN',
              decoration: const InputDecoration(
                labelText: 'Specialty (Locked to your profile)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: 16),
            // ── Related Course (recommended by specialty) ──────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isLoadingCourses)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedRelatedCourseId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: _showAllCourses
                          ? 'Related Course – All (${_recommendedCourses.length})'
                          : _recommendedCourses.isEmpty
                              ? 'No recommended courses found'
                              : 'Related Course – Recommended (${_recommendedCourses.length})',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.link),
                      helperText: 'Optional: link this course to a related course',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('None'),
                      ),
                      ..._recommendedCourses.map((c) {
                        final t = (c['title'] ?? '') as String;
                        return DropdownMenuItem<String>(
                          value: c['id'] as String,
                          child: Text(
                            t,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedRelatedCourseId = val),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() => _showAllCourses = !_showAllCourses);
                      _fetchRecommendedCourses();
                    },
                    icon: Icon(
                      _showAllCourses ? Icons.star : Icons.star_border,
                      size: 16,
                      color: AppTheme.primaryPurple,
                    ),
                    label: Text(
                      _showAllCourses
                          ? 'Show Recommended Only'
                          : 'Other Courses',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text("Course Materials", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _materials.length,
              itemBuilder: (context, index) {
                final mat = _materials[index];
                return ListTile(
                  leading: Icon(mat['type'] == 'video' ? Icons.video_library : Icons.picture_as_pdf),
                  title: Text(mat['title']),
                  subtitle: Text(mat['path'].split('/').last, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _materials.removeAt(index)),
                  ),
                );
              },
            ),
            OutlinedButton.icon(
              onPressed: _pickMaterial,
              icon: const Icon(Icons.add),
              label: const Text("Add Lesson (Video or PDF)"),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadCourse,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.accentYellow,
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("PUBLISH COURSE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
