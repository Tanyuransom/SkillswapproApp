import 'package:flutter/material.dart';
import 'package:skill_swap_pro/services/api_service.dart';
import '../../theme/app_theme.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryName;
  
  const CategoryScreen({super.key, required this.categoryName});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  void _fetchCourses() async {
    try {
      // Find category ID if possible (assuming categoryName matches for now)
      final cats = await ApiService.getCategories();
      String? catId;
      for (var cat in cats) {
        if (cat['name'] == widget.categoryName) {
          catId = cat['id'];
          break;
        }
      }

      final results = await ApiService.getCourses(categoryId: catId);
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
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final course = _courses[index];
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
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text("${course['price']??0}fr", style: const TextStyle(color: AppTheme.secondaryOrange, fontWeight: FontWeight.bold, fontSize: 16)),
                                            Row(
                                              children: [
                                                const Icon(Icons.star, color: AppTheme.accentYellow, size: 16),
                                                const Text(' 4.9', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                      childCount: _courses.length,
                    ),
                  ),
                ),
            ],
          ),
    );
  }
}
