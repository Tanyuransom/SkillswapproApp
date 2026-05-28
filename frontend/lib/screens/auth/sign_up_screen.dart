import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_role.dart';
import '../../services/session_service.dart';
import '../../services/api_service.dart';
import '../../utils/auth_helper.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with GoogleSignInMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newCategoryController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _categories = [];
  String? _selectedCategory;
  bool _isAddingNewCategory = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Role is always tutor on this skill-swap platform — no action needed
  }

  void _fetchCategories() async {
    try {
      final cats = await ApiService.getCategories();
      setState(() => _categories = cats);
    } catch (e) {
      // Silent error for now
    }
  }

  void _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final isTutor = true; // Everyone uses the unified 'tutor' capability
    String? specialization = _isAddingNewCategory ? _newCategoryController.text.trim() : _selectedCategory;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final role = UserRole.tutor; // All users are tutors on SkillSwap
      
      // If new category, create it first in course-service
      if (isTutor && _isAddingNewCategory) {
        await ApiService.createCategory(specialization!);
      }

      final response = await ApiService.register(
        fullName: name,
        email: email,
        password: password,
        role: role,
        specialization: specialization,
      );

      // Save session info
      await SessionService().saveSession(
        userId: response['user']['id'],
        fullName: response['user']['fullName'] ?? 'User',
        token: response['token'] ?? '',
        role: role,
      );

      // Automatic Sync to user-service
      try {
        await ApiService.updateUser(
          id: response['user']['id'],
          fullName: response['user']['fullName'] ?? 'User',
          role: role.toString().split('.').last,
        );
      } catch (e) {
        // Silent sync failure
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful! Please Sign In.'), backgroundColor: AppTheme.successGreen),
        );
        Navigator.pushReplacementNamed(context, '/signin');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Join SkillProf",
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.primaryPurple,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Everyone on SkillProf is a tutor — share what you know and learn from others.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              Text(
                "Area of Specialization (Optional)",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (!_isAddingNewCategory) 
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Select Category (Optional)',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    ..._categories.map((cat) => DropdownMenuItem(
                      value: cat['name'] as String,
                      child: Text(cat['name'] as String),
                    )),
                    const DropdownMenuItem(
                      value: 'ADD_NEW',
                      child: Text("+ Add New Category", style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == 'ADD_NEW') {
                      setState(() => _isAddingNewCategory = true);
                    } else {
                      setState(() => _selectedCategory = val);
                    }
                  },
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'New Category Name',
                          hintText: 'e.g. Graphic Design',
                          prefixIcon: Icon(Icons.add_circle_outline),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.errorRed),
                      onPressed: () => setState(() => _isAddingNewCategory = false),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.primaryPurple,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("CREATE ACCOUNT"),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                   Expanded(child: Divider()),
                   Padding(
                     padding: EdgeInsets.symmetric(horizontal: 16),
                     child: Text("OR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                   ),
                   Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: isGoogleLoading ? null : () => handleGoogleSignIn(initialRole: 'tutor'),
                icon: isGoogleLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.g_mobiledata, size: 30, color: AppTheme.primaryPurple),
                label: const Text("Continue with Google"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.primaryPurple),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
