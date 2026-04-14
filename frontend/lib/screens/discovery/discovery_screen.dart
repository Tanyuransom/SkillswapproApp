import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../home/course_detail_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _filteredCourses = [];
  List<dynamic> _categories = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  void _fetchInitialData() async {
    try {
      final cats = await ApiService.getCategories();
      final courses = await ApiService.getCourses();
      if (mounted) {
        setState(() {
          _categories = cats;
          _filteredCourses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
     _fetchFilteredCourses(query, _selectedCategory);
  }

  Future<void> _fetchFilteredCourses(String query, String categoryName) async {
    setState(() => _isLoading = true);
    try {
      String? catId;
      if (categoryName != 'All') {
        final cat = _categories.firstWhere((c) => c['name'] == categoryName, orElse: () => null);
        if (cat != null) catId = cat['id'];
      }

      final results = await ApiService.getCourses(categoryId: catId, query: query.isEmpty ? null : query);
      if (mounted) {
        setState(() {
          _filteredCourses = results;
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

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enrolling in ${course['title']}...")));

    try {
      await ApiService.enrollCourse(courseId: course['id'], studentId: studentId);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Skills'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search for courses or tutors...',
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
            const SizedBox(height: 24),

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
                : _filteredCourses.isEmpty
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
                  : ListView.builder(
                      itemCount: _filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = _filteredCourses[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 5, offset: const Offset(0, 2))
                            ]
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: const Icon(Icons.school, color: AppTheme.primaryPurple, size: 30),
                            ),
                            title: Text(course['title'] ?? 'Course', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Instructor: ${course['instructorId']?.substring(0,8)}...', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: AppTheme.accentYellow),
                                    const Text(' 4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    ElevatedButton(
                                      onPressed: () => _enroll(course),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                        minimumSize: const Size(60, 28),
                                        backgroundColor: AppTheme.primaryPurple,
                                      ),
                                      child: const Text("Enroll", style: TextStyle(fontSize: 11, color: Colors.white)),
                                    )
                                  ],
                                )
                              ],
                            ),
                            trailing: Text("${course['price']??0}fr", style: const TextStyle(color: AppTheme.secondaryOrange, fontWeight: FontWeight.bold)),
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course)));
                            },
                          ),
                        );
                      },
                    ),
            ),
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
}
