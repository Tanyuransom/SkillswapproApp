import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/session_service.dart';
import '../../services/api_service.dart';
import '../../utils/url_helper.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final userId = SessionService().userId;
      if (userId != null) {
        final data = await ApiService.getUser(userId);
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final userId = SessionService().userId;
      if (userId == null) return;

      // Real upload to backend
      final String secureUrl = await ApiService.uploadAvatar(image.path);
      
      await ApiService.updateUser(
        id: userId,
        fullName: _userData?['fullName'] ?? '',
        avatarUrl: secureUrl,
      );

      await _fetchProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Picture Updated!"), backgroundColor: AppTheme.successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload Error: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = _userData?['fullName'] ?? "User";
    final email = _userData?['email'] ?? "email@example.com";
    final avatarUrl = _userData?['avatarUrl'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProfile,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: AppTheme.primaryPurple,
              padding: const EdgeInsets.only(bottom: 32),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
                            backgroundImage: (avatarUrl != null && avatarUrl.toString().startsWith('http')) 
                              ? NetworkImage(UrlHelper.fixIp(avatarUrl)) 
                              : const AssetImage('assets/images/tutor.png') as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 18, color: AppTheme.primaryPurple),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol(context, "3", "Enrolled"),
                    Container(height: 40, width: 1, color: isDark ? Colors.white12 : Colors.grey.shade300),
                    _buildStatCol(context, "12", "Hours"),
                    Container(height: 40, width: 1, color: isDark ? Colors.white12 : Colors.grey.shade300),
                    _buildStatCol(context, "0", "Certificates"),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight)),
                  const SizedBox(height: 16),
                  _buildProfileOption(context, Icons.person_outline, "Edit Profile", onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                    _fetchProfile(); // Refresh after edit
                  }),
                  _buildProfileOption(context, Icons.payment, "Payment Methods", subtitle: "MTN / Orange Money"),
                  _buildProfileOption(context, Icons.notifications_outlined, "Notifications"),
                  _buildProfileOption(context, Icons.history, "Transaction History"),
                  _buildProfileOption(context, Icons.help_outline, "Help Center"),
                  const SizedBox(height: 24),
                  _buildProfileOption(context, Icons.logout, "Log Out", isDestructive: true, onTap: () {
                    SessionService().clearSession();
                    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(BuildContext context, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryPurple)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight, fontSize: 12)),
      ],
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title, {String? subtitle, bool isDestructive = false, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive ? AppTheme.errorRed.withValues(alpha: 0.1) : AppTheme.primaryPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isDestructive ? AppTheme.errorRed : AppTheme.primaryPurple),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDestructive ? AppTheme.errorRed : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight))),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: Icon(Icons.chevron_right, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
        onTap: onTap ?? () {},
      ),
    );
  }
}
