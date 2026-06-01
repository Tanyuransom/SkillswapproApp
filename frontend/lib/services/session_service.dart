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
  String? _specialization;
  String? _academicSpecialty;
  int _academicLevel = 1;

  UserRole get currentRole => _currentRole;
  String? get userId => _userId;
  String? get fullName => _fullName;
  String? get token => _token;
  String? get avatarUrl => _avatarUrl;
  String? get specialization => _specialization;
  String? get academicSpecialty => _academicSpecialty;
  int get academicLevel => _academicLevel;
  String get role => _currentRole.toString().split('.').last;

  List<String> _addedCourseIds = [];
  List<String> get addedCourseIds => _addedCourseIds;

  Future<void> addCourseId(String courseId) async {
    if (!_addedCourseIds.contains(courseId)) {
      _addedCourseIds.add(courseId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('addedCourseIds', _addedCourseIds);
    }
  }

  Future<void> removeCourseId(String courseId) async {
    if (_addedCourseIds.contains(courseId)) {
      _addedCourseIds.remove(courseId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('addedCourseIds', _addedCourseIds);
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    _fullName = prefs.getString('fullName');
    _token = prefs.getString('token');
    _avatarUrl = prefs.getString('avatarUrl');
    _specialization = prefs.getString('specialization');
    _academicSpecialty = prefs.getString('academicSpecialty');
    _academicLevel = prefs.getInt('academicLevel') ?? 1;
    _addedCourseIds = prefs.getStringList('addedCourseIds') ?? [];
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
    String? specialization,
  }) async {
    _userId = userId;
    _fullName = fullName;
    _token = token;
    _currentRole = role;
    _avatarUrl = avatarUrl;
    _specialization = specialization;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('fullName', fullName);
    await prefs.setString('token', token);
    await prefs.setString('role', role.toString());
    if (avatarUrl != null) await prefs.setString('avatarUrl', avatarUrl);
    if (specialization != null) await prefs.setString('specialization', specialization);
    if (_academicSpecialty != null) await prefs.setString('academicSpecialty', _academicSpecialty!);
    await prefs.setInt('academicLevel', _academicLevel);
  }

  Future<void> updateAcademicPreferences(int level, String? specialty) async {
    _academicLevel = level;
    _academicSpecialty = specialty;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('academicLevel', level);
    if (specialty != null) {
      await prefs.setString('academicSpecialty', specialty);
    } else {
      await prefs.remove('academicSpecialty');
    }
  }

  Future<void> clearSession() async {
    _userId = null;
    _fullName = null;
    _token = null;
    _avatarUrl = null;
    _currentRole = UserRole.student;
    _addedCourseIds.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  bool get isLoggedIn => _userId != null;
  bool get isStudent => _currentRole == UserRole.student;
  bool get isTutor => _currentRole == UserRole.tutor;
  bool get isAdmin => _currentRole == UserRole.admin;
}
