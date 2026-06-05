import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../home/course_detail_screen.dart';
import '../course/checkout_screen.dart';
import 'blog/blog_detail_screen.dart';
import 'blog/create_blog_screen.dart';
import '../../utils/url_helper.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  
  List<dynamic> _specialtyCourses = [];
  List<dynamic> _allCourses = [];
  List<dynamic> _categories = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;

  int? _selectedLevel = 1;
  String? _selectedSpecialty;
  int? _lastLoadedLevel;
  String? _lastLoadedSpecialty;
  final List<String> _specialties = ['ICT', 'ISN', 'CS', 'SEN', 'CYS'];

  // Blogging state
  String _currentTab = 'courses'; // 'courses' or 'blogs'
  List<dynamic> _allBlogs = [];
  List<dynamic> _filteredBlogs = [];
  bool _isLoadingBlogs = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _fetchBlogs() async {
    if (mounted) setState(() => _isLoadingBlogs = true);
    try {
      final blogs = await ApiService.getBlogs();
      if (mounted) {
        setState(() {
          _allBlogs = blogs;
          _filteredBlogs = blogs;
          _isLoadingBlogs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBlogs = false);
    }
  }

  void _filterBlogs(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredBlogs = _allBlogs;
      });
      return;
    }
    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredBlogs = _allBlogs.where((blog) {
        final title = (blog['title'] ?? '').toString().toLowerCase();
        final content = (blog['content'] ?? '').toString().toLowerCase();
        final category = (blog['category'] ?? '').toString().toLowerCase();
        return title.contains(lowercaseQuery) ||
            content.contains(lowercaseQuery) ||
            category.contains(lowercaseQuery);
      }).toList();
    });
  }

  void _fetchInitialData() async {
    try {
      final session = SessionService();
      await session.init();
      final cats = await ApiService.getCategories();
      
      _selectedLevel = session.academicLevel;
      _selectedSpecialty = session.academicSpecialty ?? 'SEN';
      _lastLoadedLevel = _selectedLevel;
      _lastLoadedSpecialty = _selectedSpecialty;
      
      final results = await ApiService.getCourses();
      List<dynamic> allCourses = List.from(results);
      
      List<dynamic> specCourses = [];
      for (var course in allCourses) {
        final courseLevel = course['level'] ?? 1;
        final courseSpecialty = course['specialty'] ?? '';
        
        final matchesLevel = courseLevel == _selectedLevel;
        final matchesSpecialty = _selectedSpecialty != null &&
            courseSpecialty.toString().toUpperCase().contains(_selectedSpecialty!.toUpperCase());

        if (matchesLevel && matchesSpecialty) {
          specCourses.add(course);
        }
      }
      
      final addedIds = session.addedCourseIds;
      for (var id in addedIds) {
        if (specCourses.any((c) => c['id'] == id)) continue;
        try {
          final c = await ApiService.getCourseById(id);
          if (c != null) specCourses.add(c);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _categories = cats;
          _specialtyCourses = specCourses;
          _allCourses = allCourses;
          _isLoading = false;
        });
      }
      _fetchBlogs(); // Fetch blogs concurrently
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    setState(() {}); // trigger immediate rebuild to update suffix clear icon
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_currentTab == 'blogs') {
        _filterBlogs(query);
      } else {
        _fetchFilteredCourses(query, _selectedCategory);
      }
    });
  }

  Future<void> _fetchFilteredCourses(String query, String categoryName) async {
    setState(() => _isLoading = true);
    try {
      String? catId;
      if (categoryName != 'All') {
        final cat = _categories.firstWhere((c) => c['name'] == categoryName, orElse: () => null);
        if (cat != null) catId = cat['id'];
      }

      final results = await ApiService.getCourses(
        categoryId: catId,
        query: query.isEmpty ? null : query,
      );

      List<dynamic> allCourses = List.from(results);
      
      List<dynamic> specCourses = [];
      for (var course in allCourses) {
        final courseLevel = course['level'] ?? 1;
        final courseSpecialty = course['specialty'] ?? '';
        
        final matchesLevel = courseLevel == _selectedLevel;
        final matchesSpecialty = _selectedSpecialty != null &&
            courseSpecialty.toString().toUpperCase().contains(_selectedSpecialty!.toUpperCase());

        if (matchesLevel && matchesSpecialty) {
          specCourses.add(course);
        }
      }

      if (query.isEmpty) {
        final session = SessionService();
        final addedIds = session.addedCourseIds;
        for (var id in addedIds) {
          if (specCourses.any((c) => c['id'] == id)) continue;
          try {
            final c = await ApiService.getCourseById(id);
            if (c != null) specCourses.add(c);
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _specialtyCourses = specCourses;
          _allCourses = allCourses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enroll(Map<String, dynamic> course) async {
    final studentId = SessionService().userId;
    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please sign in to enroll")));
      return;
    }

    final double priceVal = double.tryParse(course['price']?.toString() ?? '0') ?? 0.0;
    if (priceVal > 0) {
      final checkoutSuccess = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(course: course),
        ),
      );
      if (checkoutSuccess == true) {
        _fetchFilteredCourses(_searchController.text, _selectedCategory);
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enrolling in ${course['title']}...")));

    try {
      await ApiService.enrollCourse(
        courseId: course['id'],
        studentId: studentId,
        instructorId: course['instructorId'],
        studentName: SessionService().fullName,
        courseTitle: course['title'],
        instructorName: course['instructorName'],
        instructorAvatar: course['instructorAvatarUrl'],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Enrolled successfully in ${course['title']}!"), backgroundColor: AppTheme.successGreen),
        );
        // Navigate to details
        Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Enrollment Failed: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<void> _teachCourse(Map<String, dynamic> course) async {
    final tutorId = SessionService().userId;
    if (tutorId == null) return;
    try {
      await ApiService.updateCourse(
        courseId: course['id'],
        instructorId: tutorId,
        instructorName: SessionService().fullName ?? 'Tutor',
        instructorAvatarUrl: SessionService().avatarUrl ?? '',
      );
      if (mounted) {
        setState(() {
          course['instructorId'] = tutorId;
          course['instructorName'] = SessionService().fullName ?? 'Tutor';
          course['instructorAvatarUrl'] = SessionService().avatarUrl ?? '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You are now teaching this course! 🎉"), backgroundColor: AppTheme.successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to claim course: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Widget _buildCoursesListView(bool isDark, SessionService session) {
    final activeSpecCourses = _specialtyCourses;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // Section 1: RECOMMENDED FOR YOU
        Row(
          children: [
            const Icon(Icons.star_rounded, color: AppTheme.accentYellow, size: 20),
            const SizedBox(width: 6),
            Text(
              "RECOMMENDED FOR YOU",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeSpecCourses.isNotEmpty) ...[
          ...activeSpecCourses.map((course) {
            final instId = course['instructorId'];
            final isUpcoming = instId == null || instId == 'system-seed' || instId == '';
            return _buildCourseItemCard(course, isDark, session, isUpcoming);
          }),
        ] else ...[
          const Card(
            elevation: 0,
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  "No courses available for your specialty yet.",
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Section 2: ALL OTHER COURSES (Button)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: const Text(
              "ALL OTHER COURSES",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllOtherCoursesScreen(
                    query: _searchController.text,
                    categoryName: _selectedCategory,
                    level: _selectedLevel,
                    specialty: _selectedSpecialty,
                  ),
                ),
              ).then((_) => _fetchFilteredCourses(_searchController.text, _selectedCategory));
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
              foregroundColor: AppTheme.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),

        // Section 3: See Upcoming Courses (Button)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.upcoming_outlined, size: 18, color: Colors.white),
            label: const Text("See Upcoming Courses", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpcomingCoursesScreen()),
              ).then((_) => _fetchFilteredCourses(_searchController.text, _selectedCategory));
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppTheme.secondaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCourseItemCard(dynamic course, bool isDark, SessionService session, bool isUpcoming) {
    final courseLevel = course['level'] ?? 1;
    final courseSpecialty = course['specialty'] ?? '';
    
    bool isOwn = false;
    if (session.academicSpecialty != null && 
        courseSpecialty.toString().toUpperCase().contains(session.academicSpecialty!.toUpperCase()) &&
        courseLevel == session.academicLevel) {
      isOwn = true;
    }

    final isAdded = session.addedCourseIds.contains(course['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 5, offset: const Offset(0, 2))
        ]
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course)))
                  .then((_) => _fetchFilteredCourses(_searchController.text, _selectedCategory));
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 36, 12), // Add extra right padding for the stack action button
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: const Icon(Icons.school, color: AppTheme.primaryPurple, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          course['title'] ?? 'Course',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isUpcoming 
                              ? 'No Tutor Yet' 
                              : 'Instructor: ${course['instructorName'] ?? (course['instructorId']?.substring(0, 8) ?? 'Unknown')}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: AppTheme.accentYellow),
                            const Text(' 4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${course['price'] ?? 0}fr",
                        style: const TextStyle(color: AppTheme.secondaryOrange, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      if (isUpcoming) ...[
                        if (session.isTutor)
                          ElevatedButton(
                            onPressed: () => _teachCourse(course),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              minimumSize: const Size(60, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: AppTheme.secondaryOrange,
                            ),
                            child: const Text("Teach", style: TextStyle(fontSize: 10, color: Colors.white)),
                          )
                        else
                          ElevatedButton(
                            onPressed: null, // Disabled
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              minimumSize: const Size(60, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text("Upcoming", style: TextStyle(fontSize: 9, color: Colors.white70)),
                          ),
                      ] else ...[
                        ElevatedButton(
                          onPressed: () => _enroll(course),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            minimumSize: const Size(60, 24),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: AppTheme.primaryPurple,
                          ),
                          child: const Text("Enroll", style: TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!isOwn && session.isLoggedIn)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(
                  isAdded ? Icons.check_circle : Icons.add_circle_outline,
                  color: isAdded ? AppTheme.successGreen : AppTheme.primaryPurple,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    if (isAdded) {
                      session.removeCourseId(course['id']);
                    } else {
                      session.addCourseId(course['id']);
                    }
                  });
                },
                tooltip: isAdded ? "Added to My Courses" : "Add to My Courses",
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = SessionService();

    if (_lastLoadedLevel != session.academicLevel ||
        _lastLoadedSpecialty != session.academicSpecialty) {
      _lastLoadedLevel = session.academicLevel;
      _lastLoadedSpecialty = session.academicSpecialty;
      _selectedLevel = session.academicLevel;
      _selectedSpecialty = session.academicSpecialty ?? 'SEN';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchFilteredCourses(_searchController.text, _selectedCategory);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Skills'),
        elevation: 0,
      ),
      floatingActionButton: (_currentTab == 'blogs' && (session.isTutor || session.isAdmin))
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateBlogScreen()),
                ).then((value) {
                  if (value == true) {
                    _fetchBlogs();
                  }
                });
              },
              backgroundColor: AppTheme.primaryPurple,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text("Write Article", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: _currentTab == 'blogs' ? 'Search articles...' : 'Search for courses or tutors...',
                prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.primaryPurple),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : const Icon(Icons.filter_list, color: AppTheme.primaryPurple),
              ),
            ),
            const SizedBox(height: 12),

            // Tab Selector Row
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _currentTab = 'courses';
                        _searchController.clear();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _currentTab == 'courses' ? AppTheme.primaryPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Explore Skills",
                          style: TextStyle(
                            color: _currentTab == 'courses' ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _currentTab = 'blogs';
                        _searchController.clear();
                        _fetchBlogs();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _currentTab == 'blogs' ? AppTheme.primaryPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Knowledge Blog",
                          style: TextStyle(
                            color: _currentTab == 'blogs' ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_currentTab == 'courses') ...[
              // --- LEVEL SELECTOR ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Select Level", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [1, 2, 3, 4].map((level) {
                    final isSelected = _selectedLevel == level;
                    return GestureDetector(
                      onTap: () async {
                        setState(() {
                          _selectedLevel = level;
                          _lastLoadedLevel = level;
                        });
                        await session.updateAcademicPreferences(level, _selectedSpecialty);
                        _fetchFilteredCourses(_searchController.text, _selectedCategory);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryPurple : AppTheme.primaryPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          "L$level",
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.primaryPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Select Specialty", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _specialties.map((specialty) {
                    final isSelected = _selectedSpecialty == specialty;
                    return GestureDetector(
                      onTap: () async {
                        setState(() {
                          _selectedSpecialty = specialty;
                          _lastLoadedSpecialty = specialty;
                        });
                        if (_selectedLevel != null) {
                          await session.updateAcademicPreferences(_selectedLevel!, specialty);
                        }
                        _fetchFilteredCourses(_searchController.text, _selectedCategory);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.secondaryOrange : AppTheme.secondaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.secondaryOrange.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          specialty,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.secondaryOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Categories list
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip('All'),
                    ..._categories.map((cat) => _buildCategoryChip(cat['name'] as String)),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                _searchController.text.isEmpty ? "Recommended For You" : "Search Results", 
                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18)
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : (_specialtyCourses.isEmpty && _allCourses.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty ? "no courses yet" : "No results found",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : _buildCoursesListView(isDark, session),
              ),
            ] else ...[
              Expanded(
                child: _buildBlogsDashboard(isDark, session),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = label);
        _fetchFilteredCourses(_searchController.text, label);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBlogsDashboard(bool isDark, SessionService session) {
    if (_isLoadingBlogs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredBlogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "No articles found.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Split between featured (first post) and remaining posts if search is empty
    final hasFeatured = _searchController.text.isEmpty && _filteredBlogs.isNotEmpty;
    final featuredBlog = hasFeatured ? _filteredBlogs.first : null;
    final remainingBlogs = hasFeatured ? _filteredBlogs.sublist(1) : _filteredBlogs;

    return RefreshIndicator(
      onRefresh: () async {
        _fetchBlogs();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (featuredBlog != null) ...[
            Text(
              "FEATURED ARTICLE",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.secondaryOrange,
                  ),
            ),
            const SizedBox(height: 12),
            _buildFeaturedBlogCard(featuredBlog, isDark),
            const SizedBox(height: 24),
          ],
          Text(
            _searchController.text.isEmpty ? "RECENT ARTICLES" : "SEARCH RESULTS",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: remainingBlogs.length,
            itemBuilder: (context, index) {
              final blog = remainingBlogs[index];
              return _buildBlogItemCard(blog, isDark).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBlogCard(dynamic blog, bool isDark) {
    final hasImage = blog['imageUrl'] != null && (blog['imageUrl'] as String).isNotEmpty;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            hasImage
                ? Image.network(
                    UrlHelper.fixIp(blog['imageUrl']),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildFeaturedDefaultCover(),
                  )
                : _buildFeaturedDefaultCover(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BlogDetailScreen(blog: blog)),
                ).then((_) => _fetchBlogs());
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (blog['category'] ?? 'General').toString().toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      blog['title'] ?? 'Untitled',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white24,
                          backgroundImage: blog['authorAvatarUrl'] != null && blog['authorAvatarUrl'].isNotEmpty
                              ? NetworkImage(UrlHelper.fixIp(blog['authorAvatarUrl']))
                              : null,
                          child: blog['authorAvatarUrl'] == null || blog['authorAvatarUrl'].isEmpty
                              ? const Icon(Icons.person, size: 10, color: Colors.white70)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          blog['authorName'] ?? 'Tutor',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.circle, size: 3, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          blog['readTime'] ?? '3 min read',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedDefaultCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryPurple, AppTheme.secondaryOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, color: Colors.white24, size: 60),
      ),
    );
  }

  Widget _buildBlogItemCard(dynamic blog, bool isDark) {
    final hasImage = blog['imageUrl'] != null && (blog['imageUrl'] as String).isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BlogDetailScreen(blog: blog)),
          ).then((_) => _fetchBlogs());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  image: hasImage
                      ? DecorationImage(
                          image: NetworkImage(UrlHelper.fixIp(blog['imageUrl'])),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasImage
                    ? const Icon(Icons.menu_book_rounded, color: AppTheme.primaryPurple, size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          (blog['category'] ?? 'General').toString().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          blog['readTime'] ?? '3 min read',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      blog['title'] ?? 'Untitled',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: blog['authorAvatarUrl'] != null && blog['authorAvatarUrl'].isNotEmpty
                              ? NetworkImage(UrlHelper.fixIp(blog['authorAvatarUrl']))
                              : null,
                          child: blog['authorAvatarUrl'] == null || blog['authorAvatarUrl'].isEmpty
                              ? const Icon(Icons.person, size: 8, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            blog['authorName'] ?? 'Tutor',
                            style: const TextStyle(fontSize: 11, color: Colors.grey, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class UpcomingCoursesScreen extends StatefulWidget {
  const UpcomingCoursesScreen({super.key});

  @override
  State<UpcomingCoursesScreen> createState() => _UpcomingCoursesScreenState();
}

class _UpcomingCoursesScreenState extends State<UpcomingCoursesScreen> {
  List<dynamic> _upcomingCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingCourses();
  }

  Future<void> _fetchUpcomingCourses() async {
    try {
      final courses = await ApiService.getCourses(); // Fetch all courses globally
      final upcoming = courses.where((c) {
        final instId = c['instructorId'];
        return instId == null || instId == 'system-seed' || instId == '';
      }).toList();
      if (mounted) {
        setState(() {
          _upcomingCourses = upcoming;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _teachCourse(Map<String, dynamic> course) async {
    final tutorId = SessionService().userId;
    if (tutorId == null) return;
    try {
      await ApiService.updateCourse(
        courseId: course['id'],
        instructorId: tutorId,
        instructorName: SessionService().fullName ?? 'Tutor',
        instructorAvatarUrl: SessionService().avatarUrl ?? '',
      );
      if (mounted) {
        setState(() {
          _upcomingCourses.removeWhere((c) => c['id'] == course['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You are now teaching this course! 🎉"), backgroundColor: AppTheme.successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to claim course: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = SessionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upcoming Courses"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _upcomingCourses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upcoming_outlined, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          "No upcoming courses available.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _upcomingCourses.length,
                    itemBuilder: (context, index) {
                      final course = _upcomingCourses[index];
                      return _buildUpcomingCourseCard(course, isDark, session);
                    },
                  ),
      ),
    );
  }

  Widget _buildUpcomingCourseCard(dynamic course, bool isDark, SessionService session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 5, offset: const Offset(0, 2))
        ]
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course)))
              .then((_) => _fetchUpcomingCourses());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: const Icon(Icons.school, color: AppTheme.primaryPurple, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      course['title'] ?? 'Course',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Text('No Tutor Yet', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${course['price'] ?? 0}fr",
                    style: const TextStyle(color: AppTheme.secondaryOrange, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (session.isTutor)
                    ElevatedButton(
                      onPressed: () => _teachCourse(course),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        minimumSize: const Size(60, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: AppTheme.secondaryOrange,
                      ),
                      child: const Text("Teach", style: TextStyle(fontSize: 10, color: Colors.white)),
                    )
                  else
                    ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: const Size(60, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text("Upcoming", style: TextStyle(fontSize: 9, color: Colors.white70)),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AllOtherCoursesScreen extends StatefulWidget {
  final String query;
  final String categoryName;
  final int? level;
  final String? specialty;

  const AllOtherCoursesScreen({
    super.key,
    required this.query,
    required this.categoryName,
    required this.level,
    required this.specialty,
  });

  @override
  State<AllOtherCoursesScreen> createState() => _AllOtherCoursesScreenState();
}

class _AllOtherCoursesScreenState extends State<AllOtherCoursesScreen> {
  List<dynamic> _otherCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOtherCourses();
  }

  Future<void> _fetchOtherCourses() async {
    try {
      String? catId;
      final cats = await ApiService.getCategories();
      if (widget.categoryName != 'All') {
        final cat = cats.firstWhere((c) => c['name'] == widget.categoryName, orElse: () => null);
        if (cat != null) catId = cat['id'];
      }

      final results = await ApiService.getCourses(
        categoryId: catId,
        query: widget.query.isEmpty ? null : widget.query,
      );

      // Filter out user's level/specialty courses (Recommended ones) to avoid duplicates
      final filtered = results.where((c) {
        final courseLevel = c['level'] ?? 1;
        final courseSpecialty = c['specialty'] ?? '';
        
        final isSpec = widget.specialty != null &&
            courseSpecialty.toString().toUpperCase().contains(widget.specialty!.toUpperCase()) &&
            courseLevel == widget.level;
            
        return !isSpec;
      }).toList();

      if (mounted) {
        setState(() {
          _otherCourses = filtered;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _teachCourse(Map<String, dynamic> course) async {
    final tutorId = SessionService().userId;
    if (tutorId == null) return;
    try {
      await ApiService.updateCourse(
        courseId: course['id'],
        instructorId: tutorId,
        instructorName: SessionService().fullName ?? 'Tutor',
        instructorAvatarUrl: SessionService().avatarUrl ?? '',
      );
      if (mounted) {
        setState(() {
          course['instructorId'] = tutorId;
          course['instructorName'] = SessionService().fullName ?? 'Tutor';
          course['instructorAvatarUrl'] = SessionService().avatarUrl ?? '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You are now teaching this course! 🎉"), backgroundColor: AppTheme.successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to claim course: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<void> _enroll(Map<String, dynamic> course) async {
    final studentId = SessionService().userId;
    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please sign in to enroll")));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enrolling in ${course['title']}...")));

    try {
      await ApiService.enrollCourse(
        courseId: course['id'],
        studentId: studentId,
        instructorId: course['instructorId'],
        studentName: SessionService().fullName,
        courseTitle: course['title'],
        instructorName: course['instructorName'],
        instructorAvatar: course['instructorAvatarUrl'],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Enrolled successfully in ${course['title']}!"), backgroundColor: AppTheme.successGreen),
        );
        Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to enroll: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = SessionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Other Courses"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _otherCourses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grid_off_rounded, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          "No other courses available.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _otherCourses.length,
                    itemBuilder: (context, index) {
                      final course = _otherCourses[index];
                      return _buildCourseItemCard(course, isDark, session);
                    },
                  ),
      ),
    );
  }

  Widget _buildCourseItemCard(dynamic course, bool isDark, SessionService session) {
    final isAdded = session.addedCourseIds.contains(course['id']);
    final instId = course['instructorId'];
    final isUpcoming = instId == null || instId == 'system-seed' || instId == '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 5, offset: const Offset(0, 2))
        ]
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course)))
                  .then((_) => _fetchOtherCourses());
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 36, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: const Icon(Icons.school, color: AppTheme.primaryPurple, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          course['title'] ?? 'Course',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isUpcoming 
                              ? 'No Tutor Yet' 
                              : 'Instructor: ${course['instructorName'] ?? (course['instructorId']?.substring(0, 8) ?? 'Unknown')}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: AppTheme.accentYellow),
                            const Text(' 4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${course['price'] ?? 0}fr",
                        style: const TextStyle(color: AppTheme.secondaryOrange, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      if (isUpcoming) ...[
                        if (session.isTutor)
                          ElevatedButton(
                            onPressed: () => _teachCourse(course),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              minimumSize: const Size(60, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: AppTheme.secondaryOrange,
                            ),
                            child: const Text("Teach", style: TextStyle(fontSize: 10, color: Colors.white)),
                          )
                        else
                          ElevatedButton(
                            onPressed: null, // Disabled
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              minimumSize: const Size(60, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text("Upcoming", style: TextStyle(fontSize: 9, color: Colors.white70)),
                          ),
                      ] else ...[
                        ElevatedButton(
                          onPressed: () => _enroll(course),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            minimumSize: const Size(60, 24),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: AppTheme.primaryPurple,
                          ),
                          child: const Text("Enroll", style: TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (session.isLoggedIn)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(
                  isAdded ? Icons.check_circle : Icons.add_circle_outline,
                  color: isAdded ? AppTheme.successGreen : AppTheme.primaryPurple,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    if (isAdded) {
                      session.removeCourseId(course['id']);
                    } else {
                      session.addCourseId(course['id']);
                    }
                  });
                },
                tooltip: isAdded ? "Added to My Courses" : "Add to My Courses",
              ),
            ),
        ],
      ),
    );
  }
}
