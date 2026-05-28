import 'package:flutter/material.dart';
import '../shorts/shorts_feed_screen.dart';
import 'package:skill_swap_pro/services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../services/session_service.dart';
import '../../utils/url_helper.dart';
import '../category/category_screen.dart';
import '../category/all_categories_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _trendingCourses = [];
  List<dynamic> _filteredCourses = [];
  List<dynamic> _shorts = [];
  bool _isLoading = true;
  bool _isLoadingShorts = true;
  String _searchQuery = "";
  List<dynamic> _notifications = [];
  int _selectedLevel = 1;
  String? _selectedSpecialty;
  List<dynamic> _categories = [];
  final session = SessionService();

  final List<String> _specialties = ['ICT', 'ISN', 'CS', 'SEN', 'CYS'];

  @override
  void initState() {
    super.initState();
    _refreshSession();
    _fetchTrending();
    _fetchShorts();
  }

  Future<void> _refreshSession() async {
    await session.init();
    _fetchNotifications();
    _selectedLevel = session.academicLevel;
    _selectedSpecialty = session.academicSpecialty ?? 'SEN';
    _fetchCategories();
    if (mounted) setState(() {});
    _fetchTrending();
    _fetchShorts();
  }

  void _fetchCategories() async {
    try {
      final cats = await ApiService.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (e) { /* silent */ }
  }

  void _fetchNotifications() async {
    try {
      if (session.userId != null) {
        final data = await ApiService.getNotifications(session.userId!);
        if (mounted) setState(() => _notifications = data);
      }
    } catch (e) { /* silent */ }
  }

  void _fetchTrending() async {
    try {
      final courses = await ApiService.getTrendingCourses(level: _selectedLevel, specialty: _selectedSpecialty);
      if (mounted) {
        setState(() {
          _trendingCourses = courses;
          _filteredCourses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoading = query.isNotEmpty; // Show shimmer during search
    });
    
    if (query.isEmpty) {
      setState(() {
        _filteredCourses = _trendingCourses;
        _isLoading = false;
      });
      return;
    }

    // Debounce or immediate search
    try {
      final results = await ApiService.getCourses(query: query, level: _selectedLevel, specialty: _selectedSpecialty);
      if (mounted && _searchQuery == query) {
        setState(() {
          _filteredCourses = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to local filter if API fails
      setState(() {
        _filteredCourses = _trendingCourses.where((c) {
          final title = (c['title'] ?? "").toLowerCase();
          final desc = (c['description'] ?? "").toLowerCase();
          return title.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
        }).toList();
        _isLoading = false;
      });
    }
  }

  void _fetchShorts() async {
    try {
      final shorts = await ApiService.getShorts(level: _selectedLevel, specialty: _selectedSpecialty);
      if (mounted) {
        setState(() {
          _shorts = shorts;
          _isLoadingShorts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingShorts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillProf Platform'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _isLoadingShorts = true;
              });
              _fetchTrending();
              _fetchShorts();
              _refreshSession();
            },
            tooltip: 'Refresh Content',
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.pushNamed(context, '/notifications').then((_) => _fetchNotifications()),
              ),
              if (_notifications.any((n) => !(n['isRead'] ?? false)))
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.secondaryOrange, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchTrending();
          _fetchShorts();
          await _refreshSession();
        },
        color: AppTheme.primaryPurple,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello, ${_getDisplayName()}👋", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                      Text("What will you learn today?", style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22)),
                    ],
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: (session.avatarUrl != null && session.avatarUrl!.isNotEmpty)
                        ? NetworkImage(UrlHelper.fixIp(session.avatarUrl!)) as ImageProvider
                        : const AssetImage('assets/images/tutor.png'),
                    backgroundColor: AppTheme.primaryPurple,
                  )
                ],
              ),
  
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ]
                ),
                child: TextField(
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: "Search for a skill...",
                    hintStyle: TextStyle(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                    suffixIcon: const Icon(Icons.mic, color: AppTheme.primaryPurple),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // --- LEVEL SELECTOR ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Your Level", style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18)),
                  if (session.userId != null)
                    TextButton(
                      onPressed: () async {
                        // Move to next level logic
                        final nextLevel = (_selectedLevel % 4) + 1;
                        await ApiService.moveUserLevel(session.userId!, nextLevel);
                        await session.updateAcademicPreferences(nextLevel, _selectedSpecialty);
                        setState(() {
                          _selectedLevel = nextLevel;
                          _isLoading = true;
                          _isLoadingShorts = true;
                        });
                        _fetchTrending();
                        _fetchShorts();
                      },
                      child: Text("Move to Level ${(_selectedLevel % 4) + 1}", style: const TextStyle(color: AppTheme.secondaryOrange)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [1, 2, 3, 4].map((level) {
                    final isSelected = _selectedLevel == level;
                    return GestureDetector(
                      onTap: () async {
                        await session.updateAcademicPreferences(level, _selectedSpecialty);
                        setState(() {
                          _selectedLevel = level;
                          _isLoading = true;
                          _isLoadingShorts = true;
                        });
                        _fetchTrending();
                        _fetchShorts();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryPurple : AppTheme.primaryPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          "Level $level",
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),
              Text("Select Specialty", style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _specialties.map((specialty) {
                    final isSelected = _selectedSpecialty == specialty;
                    return GestureDetector(
                      onTap: () async {
                        await session.updateAcademicPreferences(_selectedLevel, specialty);
                        setState(() {
                          _selectedSpecialty = specialty;
                          _isLoading = true;
                          _isLoadingShorts = true;
                        });
                        _fetchTrending();
                        _fetchShorts();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.secondaryOrange : AppTheme.secondaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.secondaryOrange.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          specialty,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.secondaryOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Categories", style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AllCategoriesScreen())).then((_) => _fetchShorts());
                    },
                    child: const Text("See All", style: TextStyle(color: AppTheme.primaryPurple))
                  )
                ],
              ),
              const SizedBox(height: 16),
              _categories.isEmpty 
                ? const SizedBox(height: 100, child: Center(child: Text("No categories found", style: TextStyle(color: Colors.grey))))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.take(5).map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildCategoryCard(context, cat['name'] ?? 'Category', _getCategoryIcon(cat['name'])),
                      )).toList(),
                    ),
                  ),
              const SizedBox(height: 32),
  
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Quick Tips", style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20)),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Explore all shorts in the Shorts tab!")));
                    }, 
                    child: const Text("See All", style: TextStyle(color: AppTheme.primaryPurple))
                  )
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160, // Increased height
                child: _isLoadingShorts
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (_, _) => _buildShimmerShortCard(),
                    )
                  : _shorts.isEmpty
                    ? Center(child: Text("no shorts yet", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _shorts.length,
                        itemBuilder: (context, index) {
                          final short = _shorts[index];
                          return _buildShortCard(context, short).animate().fadeIn(delay: (50 * index).ms).slideX();
                        },
                      ),
              ),
              const SizedBox(height: 32),
              
              Text("Trending Offers", style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20)),
              const SizedBox(height: 16),
              SizedBox(
                height: 280,
                child: _isLoading 
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (_, _) => _buildShimmerCourseCard(context),
                    )
                  : _filteredCourses.isEmpty 
                    ? const Center(child: Text("no matching courses", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filteredCourses.length,
                        itemBuilder: (context, index) {
                          final course = _filteredCourses[index];
                          return _buildCourseCard(context, course)
                              .animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.2);
                        },
                      ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? name) {
    if (name == null) return Icons.school;
    switch (name.toLowerCase()) {
      case 'engineering': return Icons.engineering;
      case 'bms': return Icons.business_center;
      case 'ict': return Icons.phone_android;
      case 'isn': return Icons.router;
      case 'cs': return Icons.computer;
      case 'sen': return Icons.developer_mode;
      case 'cys': return Icons.security;
      case 'ren': return Icons.wb_sunny;
      case 'jmc': return Icons.newspaper;
      default: return Icons.school;
    }
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(categoryName: title)));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100, // Fixed width for scrolling row
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryPurple, size: 28),
            const SizedBox(height: 12),
            Text(
              title, 
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryPurple, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayName() {
    final name = session.fullName;
    if (name == null || name.trim().isEmpty) return "Learner";
    return name.split(' ').first;
  }

  Widget _buildShortCard(BuildContext context, dynamic short) {
    final avatarUrl = short['tutorAvatarUrl'];
    final videoUrl = UrlHelper.fixIp(short['videoUrl'] ?? '');
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShortsFeedScreen(initialShortId: short['id']),
          ),
        ).then((_) {
          _fetchShorts();
        });
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Thumbnail
              Positioned.fill(
                child: VideoThumbnailWidget(videoUrl: videoUrl),
              ),
              
              // Dark overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    )
                  ),
                ),
              ),

              const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 36)),
              
              // Tutor avatar
              Positioned(
                top: 8,
                left: 8,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white,
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(UrlHelper.fixIp(avatarUrl)) as ImageProvider
                      : const AssetImage('assets/images/tutor.png'),
                ),
              ),

              // Interaction Counts
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, color: Colors.white, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          short['likes']?.toString() ?? '0',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.comment, color: Colors.white, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          short['comments']?.toString() ?? '0',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Description/Course Name
              Positioned(
                bottom: 12,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      short['courseName'] ?? 'Quick Tip',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      short['description'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 9),
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
    );
  }

  Widget _buildCourseCard(BuildContext context, dynamic course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = course['title'] ?? 'Course';
    final subtitle = course['description'] ?? '';
    final price = "${course['price']?.toString() ?? '0'}fr";
    final rawRating = course['averageRating'];
    final rating = (rawRating is num ? rawRating.toDouble() : double.tryParse(rawRating?.toString() ?? '0') ?? 0.0).toStringAsFixed(1);
    final reviews = course['reviewCount']?.toString() ?? "0";
    final views = course['viewsCount']?.toString() ?? "0";
    final instructorName = course['instructorName'] ?? "Tutor";
    final avatarUrl = course['instructorAvatarUrl'];

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ]
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/course-detail', arguments: course),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.school, size: 54, color: Colors.white)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.remove_red_eye, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(views, style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? NetworkImage(UrlHelper.fixIp(avatarUrl)) as ImageProvider
                            : const AssetImage('assets/images/tutor.png'),
                      ),
                      const SizedBox(width: 6),
                      Text(instructorName, style: TextStyle(color: AppTheme.primaryPurple, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle, 
                    style: TextStyle(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price, 
                        style: const TextStyle(color: AppTheme.secondaryOrange, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: AppTheme.accentYellow, size: 14),
                          Text(" $rating ($reviews)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerShortCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildShimmerCourseCard(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  const VideoThumbnailWidget({super.key, required this.videoUrl});

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  String? _thumbnailPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final fileName = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 150,
        quality: 50,
      );
      if (mounted) {
        setState(() {
          _thumbnailPath = fileName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(color: Colors.grey.shade800);
    }
    if (_thumbnailPath == null) {
      return Container(color: AppTheme.primaryPurple.withValues(alpha: 0.2));
    }
    return Image.file(File(_thumbnailPath!), fit: BoxFit.cover);
  }
}
