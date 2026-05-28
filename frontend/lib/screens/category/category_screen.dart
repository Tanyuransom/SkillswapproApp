import 'package:flutter/material.dart';
import 'package:skill_swap_pro/services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../services/session_service.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryName;
  
  const CategoryScreen({super.key, required this.categoryName});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<dynamic> _courses = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
    _fetchCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchCourses() async {
    try {
      final session = SessionService();
      await session.init();
      
      // Find category ID if possible (assuming categoryName matches for now)
      final cats = await ApiService.getCategories();
      String? catId;
      for (var cat in cats) {
        if (cat['name'] == widget.categoryName) {
          catId = cat['id'];
          break;
        }
      }

      String? specialtyFilter = session.academicSpecialty;
      if (['ICT', 'ISN', 'CS', 'SEN', 'CYS', 'REN', 'JMC', 'BMS'].contains(widget.categoryName)) {
        specialtyFilter = widget.categoryName;
      }

      final results = await ApiService.getCourses(
        categoryId: catId,
        level: session.academicLevel,
        specialty: specialtyFilter,
      );
      if (mounted) {
        setState(() {
          _courses = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData getCategoryIcon() {
    switch (widget.categoryName.toLowerCase()) {
      case 'design': return Icons.brush;
      case 'coding': return Icons.code;
      case 'marketing': return Icons.trending_up;
      default: return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredCourses = _courses.where((course) {
      final String title = (course['title'] ?? '').toLowerCase();
      final String code = (course['code'] ?? '').toLowerCase();
      final String query = _searchQuery.trim().toLowerCase();
      return title.contains(query) || code.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryName} Skills'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryPurple, Color(0xFF9F7AEA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(getCategoryIcon(), size: 60, color: Colors.white),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Explore ${widget.categoryName}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text("Find top rated tutors and start learning today.", style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search within ${widget.categoryName}...',
                      prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.primaryPurple),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              if (_courses.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("no courses yet", style: TextStyle(color: Colors.grey, fontSize: 18)),
                        Text("Check back soon for tutor uploads!", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else if (filteredCourses.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No matches found", style: TextStyle(color: Colors.grey, fontSize: 18)),
                        Text("Try searching for a different keyword", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final course = filteredCourses[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                                blurRadius: 10, offset: const Offset(0, 4)
                              )
                            ]
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 120,
                                  color: AppTheme.primaryPurple.withValues(alpha: 0.8),
                                  child: Icon(getCategoryIcon(), size: 48, color: Colors.white),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(course['title'] ?? 'Course', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text('Instructor: ${course['instructorId']?.substring(0,8)}...', style: TextStyle(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight, fontSize: 12)),
                                        
                                        // Dynamic Compulsory/Elective Badge
                                        (() {
                                          final int courseLevel = course['level'] ?? 1;
                                          final String courseTitle = course['title'] ?? '';
                                          if (courseLevel == 2) {
                                            final t = courseTitle.toLowerCase();
                                            final isElective = t.contains("civics and ethics") ||
                                                t.contains("computer networking and security") ||
                                                t.contains("game dev") ||
                                                t.contains("game developmen") ||
                                                (t.contains("introduction to iot") && t.contains("embedded"));
                                            return Container(
                                              margin: const EdgeInsets.only(top: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isElective ? Colors.blue.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: isElective ? Colors.blue : Colors.red, width: 0.5),
                                              ),
                                              child: Text(
                                                isElective ? "Elective (L2)" : "Compulsory (L2)",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isElective ? Colors.blue.shade700 : Colors.red.shade700,
                                                ),
                                              ),
                                            );
                                          } else if (courseLevel == 1) {
                                            return Container(
                                              margin: const EdgeInsets.only(top: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.red, width: 0.5),
                                              ),
                                              child: Text(
                                                "Compulsory (L1)",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red.shade700,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        })(),
                                        
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text("${course['price']??0}fr", style: const TextStyle(color: AppTheme.secondaryOrange, fontWeight: FontWeight.bold, fontSize: 16)),
                                            Row(
                                              children: [
                                                const Icon(Icons.star, color: AppTheme.accentYellow, size: 16),
                                                Text(
                                                  ' ${(() {
                                                    final rawRating = course['averageRating'];
                                                    final double rating = (rawRating is num ? rawRating.toDouble() : double.tryParse(rawRating?.toString() ?? '0') ?? 0.0);
                                                    return rating.toStringAsFixed(1);
                                                  })()} (${course['reviewCount'] ?? 0})',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ],
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filteredCourses.length,
                    ),
                  ),
                ),
            ],
          ),
    );
  }
}
