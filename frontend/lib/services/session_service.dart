import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';

class SessionService {
  // Singleton pattern
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  UserRole _currentRole = UserRole.student;
  String? _userId;
  String? _fullName;
  String? _token;
  String? _avatarUrl;

  UserRole get currentRole => _currentRole;
  String? get userId => _userId;
  String? get fullName => _fullName;
  String? get token => _token;
  String? get avatarUrl => _avatarUrl;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    _fullName = prefs.getString('fullName');
    _token = prefs.getString('token');
    _avatarUrl = prefs.getString('avatarUrl');
    final roleStr = prefs.getString('role');
    if (roleStr != null) {
      _currentRole = UserRole.values.firstWhere(
        (e) => e.toString() == roleStr,
        orElse: () => UserRole.student,
      );
    }
  }

  Future<void> saveSession({
    required String userId,
    required String fullName,
    required String token,
    required UserRole role,
    String? avatarUrl,
  }) async {
    _userId = userId;
    _fullName = fullName;
    _token = token;
    _currentRole = role;
    _avatarUrl = avatarUrl;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('fullName', fullName);
    await prefs.setString('token', token);
    await prefs.setString('role', role.toString());
    if (avatarUrl != null) {
      await prefs.setString('avatarUrl', avatarUrl);
    } else {
      await prefs.remove('avatarUrl');
    }
  }

  Future<void> clearSession() async {
    _userId = null;
    _fullName = null;
    _token = null;
    _avatarUrl = null;
    _currentRole = UserRole.student;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  bool get isLoggedIn => _userId != null;
  bool get isStudent => _currentRole == UserRole.student;
  bool get isTutor => _currentRole == UserRole.tutor;
  bool get isAdmin => _currentRole == UserRole.admin;
}
