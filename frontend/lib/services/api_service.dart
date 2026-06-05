import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user_role.dart';
import '../services/session_service.dart';

class ApiService {
  // --- CENTRAL GATEWAY CONFIGURATION ---
  static const String hostIp = '10.136.249.132'; 
  static const String baseUrl = 'http://$hostIp:3000/api';
  static const Duration timeoutDuration = Duration(seconds: 30);
  
  // --- MEDIA UPLOADS (Now routed through specific services via Gateway) ---
  
  static Future<String> uploadAvatar(String filePath) async {
    try {
      // Routed to User Service via Gateway
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/avatar'));
      request.files.add(await http.MultipartFile.fromPath('avatar', filePath));
      
      var response = await request.send().timeout(timeoutDuration);
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        // Important: Return relative URL to be handled by UrlHelper.fixIp
        return json['url']; 
      }
      throw Exception('Upload failed');
    } catch (e) {
      throw Exception('Upload Error: ${e.toString()}');
    }
  }


  // --- AUTHENTICATION (Identity Service) ---

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? specialization,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role.toString().split('.').last, 
          'specialization': specialization,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Registration failed';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Connection Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Login failed';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Auth Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> googleLogin({
    required String idToken,
    String? role,
  }) async {
    try {
      print("Sending Google Login to: $baseUrl/auth/google-login");
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'role': role,
        }),
      ).timeout(timeoutDuration);

      print("Google Login Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Google Login failed';
        throw Exception(error);
      }
    } catch (e) {
      print("Google Login API Error: $e");
      throw Exception('Google Auth Error: ${e.toString()}');
    }
  }

  // --- USER PROFILES (User Service) ---

  static Future<Map<String, dynamic>> getUser(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$id')).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('User fetch failed');
    } catch (e) {
      throw Exception('Fetch Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getUserById(String id) => getUser(id);

  static Future<Map<String, dynamic>> updateUser({
    required String id,
    required String fullName,
    String? specialization,
    String? avatarUrl,
    String? role,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'specialization': specialization,
          'avatarUrl': avatarUrl,
          'role': role,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Update failed';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Update Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> submitAppReview({
    required String userId,
    required String userName,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/app-reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'userName': userName,
          'rating': rating,
          'comment': comment,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Feedback submission failed';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Feedback submission error: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getAppReviews() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/app-reviews'),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getUsersBatch(List<String> ids) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ids': ids}),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<void> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
      ).timeout(timeoutDuration);
      if (response.statusCode != 200) {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      throw Exception('Delete User Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String fullName,
    required String role,
    String? specialization,
    String? avatarUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'fullName': fullName,
          'role': role,
          'specialization': specialization,
          'avatarUrl': avatarUrl ?? 'https://i.pravatar.cc/150?img=${email.length % 70}',
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 201) return jsonDecode(response.body);
      throw Exception('Failed to create user');
    } catch (e) {
      throw Exception('Create User Error: ${e.toString()}');
    }
  }

  // --- COURSES (Course Service) ---

  static Future<List<dynamic>> getCourses({String? categoryId, String? query, int? level, String? specialty}) async {
    try {
      String url = '$baseUrl/courses?';
      if (categoryId != null) url += 'categoryId=$categoryId&';
      if (query != null) url += 'query=${Uri.encodeComponent(query)}&';
      if (level != null) url += 'level=$level&';
      if (specialty != null) url += 'specialty=$specialty&';
      
      final response = await http.get(Uri.parse(url)).timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      throw Exception('Course Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>?> getCourseById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/courses/$id')).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateCourse({
    required String courseId,
    String? title,
    String? description,
    double? price,
    String? categoryId,
    int? level,
    String? specialty,
    String? instructorId,
    String? instructorName,
    String? instructorAvatarUrl,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/courses/$courseId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (price != null) 'price': price,
          if (categoryId != null) 'categoryId': categoryId,
          if (level != null) 'level': level,
          if (specialty != null) 'specialty': specialty,
          if (instructorId != null) 'instructorId': instructorId,
          if (instructorName != null) 'instructorName': instructorName,
          if (instructorAvatarUrl != null) 'instructorAvatarUrl': instructorAvatarUrl,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Update failed';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Update Error: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getTrendingCourses({int? level, String? specialty}) async {
    try {
      String url = '$baseUrl/courses/trending?';
      if (level != null) url += 'level=$level&';
      if (specialty != null) url += 'specialty=$specialty&';
      
      final response = await http.get(Uri.parse(url)).timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> recordCourseView(String courseId) async {
    try {
      await http.patch(Uri.parse('$baseUrl/courses/$courseId/view')).timeout(timeoutDuration);
    } catch (e) { /* silent */ }
  }

  static Future<Map<String, dynamic>> createCourse({
    required String title,
    required String description,
    required double price,
    required String instructorId,
    String? imageUrl,
    String? categoryId,
    String? instructorName,
    String? instructorAvatarUrl,
    int? level,
    String? specialty,
    String? semester,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/courses'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title, 'description': description, 'price': price,
          'instructorId': instructorId, 'imageUrl': imageUrl, 'categoryId': categoryId,
          'instructorName': instructorName, 'instructorAvatarUrl': instructorAvatarUrl,
          'level': level ?? 1,
          'specialty': specialty,
          'semester': semester,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 201) return jsonDecode(response.body);
      throw Exception('Failed to create course');
    } catch (e) { throw Exception('Creation Error: ${e.toString()}'); }
  }

  static Future<void> deleteCourse(String courseId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/courses/$courseId'),
      ).timeout(timeoutDuration);
      if (response.statusCode != 200) {
        throw Exception('Failed to delete course');
      }
    } catch (e) {
      throw Exception('Delete Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> addCourseMaterial({
    required String courseId,
    required String title,
    required String url,
    required String type,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/courses/$courseId/materials'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title, 'url': url, 'type': type
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to add course material');
    } catch (e) { throw Exception('Material Error: ${e.toString()}'); }
  }

  static Future<Map<String, dynamic>> deleteCourseMaterial({
    required String courseId,
    required int materialIndex,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/courses/$courseId/materials/$materialIndex'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to delete course material');
    } catch (e) { throw Exception('Delete Material Error: ${e.toString()}'); }
  }

  static Future<List<dynamic>> getTutorCourses(String tutorId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/courses/tutor/$tutorId/courses'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> addCourseReview({
    required String courseId,
    required String userId,
    required String userName,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/courses/$courseId/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'userName': userName,
          'rating': rating,
          'comment': comment,
        }),
      ).timeout(timeoutDuration);
      
      if (response.statusCode == 201) return jsonDecode(response.body);
      throw Exception('Failed to add review');
    } catch (e) {
      throw Exception('Review Error: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getCourseReviews(String courseId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/courses/$courseId/reviews'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  // --- CATEGORIES (Category Service) ---

  static Future<List<dynamic>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  // --- ENROLLMENTS (Enrollment Service) ---

  static Future<Map<String, dynamic>> enrollCourse({
    required String courseId,
    required String studentId,
    String? instructorId,
    String? studentName,
    String? courseTitle,
    String? instructorName,
    String? instructorAvatar,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enrollments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'courseId': courseId,
          'studentId': studentId,
          if (instructorId != null) 'instructorId': instructorId,
          if (studentName != null) 'studentName': studentName,
          if (courseTitle != null) 'courseTitle': courseTitle,
          if (instructorName != null) 'instructorName': instructorName,
          if (instructorAvatar != null) 'instructorAvatar': instructorAvatar,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 201) return jsonDecode(response.body);
      final error = jsonDecode(response.body)['error'] ?? 'Enrollment failed';
      throw Exception(error);
    } catch (e) { throw Exception('Enrollment Error: ${e.toString()}'); }
  }

  static Future<List<dynamic>> getEnrolledStudents(String tutorId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/enrollments/tutor/$tutorId/students'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> getStudentEnrollments(String studentId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/enrollments/student/$studentId'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  // --- SHORTS (Shorts Service) ---

  static Future<List<dynamic>> getShorts({int? level, String? specialty}) async {
    try {
      final session = SessionService();
      String url = '$baseUrl/shorts?';
      if (session.userId != null) {
        url += 'userId=${session.userId}&';
      }
      if (level != null) {
        url += 'level=$level&';
      }
      if (specialty != null) {
        url += 'specialty=$specialty&';
      }
      final response = await http.get(Uri.parse(url))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> createShort({
    required String tutorId, 
    required String videoUrl, 
    String? tutorName, 
    String? courseName,
    String? description,
    String? tutorAvatarUrl,
    int? level,
    String? specialty,
    String? categoryId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shorts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({ 
          'tutorId': tutorId, 
          'title': description ?? 'New Tip', 
          'description': description ?? 'New Tip',
          'videoUrl': videoUrl, 
          'tutorName': tutorName ?? 'SkillProf Tutor', 
          'courseName': courseName ?? 'SkillProf Tips',
          'tutorAvatarUrl': tutorAvatarUrl ?? '',
          'level': level ?? 1,
          'specialty': specialty,
          'categoryId': categoryId,
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 201) return jsonDecode(response.body);
      throw Exception('Failed to create short');
    } catch (e) { throw Exception('Shorts Error: ${e.toString()}'); }
  }

  static Future<void> deleteShort(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/shorts/$id'),
      ).timeout(timeoutDuration);
      if (response.statusCode != 200) {
        throw Exception('Failed to delete short');
      }
    } catch (e) {
      throw Exception('Delete Short Error: ${e.toString()}');
    }
  }



  static Future<Map<String, dynamic>> toggleLike({
    required String userId,
    required String targetId,
    required String targetType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/likes/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'targetId': targetId,
          'targetType': targetType,
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to toggle like');
    } catch (e) {
      throw Exception('Like Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> addComment({
    required String userId,
    required String userName,
    required String targetId,
    required String targetType,
    required String text,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'userName': userName,
          'targetId': targetId,
          'targetType': targetType,
          'text': text,
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to add comment: ${response.statusCode}');
    } catch (e) {
      throw Exception('AddComment Error: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getComments(String targetId, String targetType) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comments?targetId=$targetId&targetType=$targetType'),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> recordShare({
    required String userId,
    required String targetId,
    required String targetType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shares'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'targetId': targetId,
          'targetType': targetType,
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 201) return jsonDecode(response.body);
      throw Exception('Failed to record share');
    } catch (e) {
      throw Exception('Share Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String senderId, required String receiverId,
    required String content, 
    String? senderName,
    String? senderAvatarUrl,
    String? senderRole,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messaging'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId, 
          'receiverId': receiverId,
          'content': content, 
          'senderName': senderName,
          'senderAvatarUrl': senderAvatarUrl,
          'senderRole': senderRole,
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 201) return jsonDecode(response.body);
      throw Exception('Failed to send message');
    } catch (e) { throw Exception('Message Error: ${e.toString()}'); }
  }

  static Future<List<dynamic>> getMessages(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/messaging/$userId'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> getConversations(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/messaging/conversations/$userId'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> getChatHistory(String userId, String partnerId, {int limit = 50, int offset = 0}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/messaging/history/$userId/$partnerId?limit=$limit&offset=$offset'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'messages': [], 'total': 0};
    } catch (e) { return {'messages': [], 'total': 0}; }
  }

  static Future<void> markChatAsRead(String userId, String partnerId) async {
    try {
      await http.patch(Uri.parse('$baseUrl/messaging/read/$userId/$partnerId')).timeout(timeoutDuration);
    } catch (e) { /* silent */ }
  }

  // --- NOTIFICATIONS (Notification Service) ---

  static Future<List<dynamic>> getNotifications(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifications/$userId'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<void> markNotificationAsRead(String id) async {
    try {
      await http.put(Uri.parse('$baseUrl/notifications/$id/read')).timeout(timeoutDuration);
    } catch (e) { /* silent */ }
  }

  // --- STATS & ADMIN (Placeholder Services) ---

  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stats/admin')).timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'activeStudents': 0};
    } catch (e) { return {'activeStudents': 0}; }
  }

  static Future<Map<String, dynamic>> getTutorStats(String tutorId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stats/tutor/$tutorId')).timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'totalEarnings': 0, 'activeStudents': 0, 'newEnrollments': 0};
    } catch (e) { return {'totalEarnings': 0, 'activeStudents': 0, 'newEnrollments': 0}; }
  }

  // --- UPLOADS (Multipart) ---

  static Future<String> uploadCourseImage(String filePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/courses/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final response = await request.send().timeout(const Duration(minutes: 2));
      final respStr = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        return jsonDecode(respStr)['url'];
      }
      throw Exception('Upload failed: $respStr');
    } catch (e) { throw Exception('Image Upload Error: ${e.toString()}'); }
  }

  static Future<String> uploadCourseFile(String filePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/courses/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final response = await request.send().timeout(const Duration(minutes: 10)); // Longer for materials
      final respStr = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        return jsonDecode(respStr)['url'];
      }
      throw Exception('Upload failed: $respStr');
    } catch (e) { throw Exception('File Upload Error: ${e.toString()}'); }
  }

  static Future<String> uploadVideo(String filePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/shorts/upload'));
      request.files.add(await http.MultipartFile.fromPath('video', filePath));
      
      // Large files need longer timeout
      final response = await request.send().timeout(const Duration(minutes: 5));
      final respStr = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        return jsonDecode(respStr)['url'];
      }
      throw Exception('Upload failed: $respStr');
    } catch (e) { throw Exception('Video Upload Error: ${e.toString()}'); }
  }

  // --- CATEGORY ---
  static Future<Map<String, dynamic>> createCategory(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'description': ''}),
      ).timeout(timeoutDuration);
      if (response.statusCode == 201) return jsonDecode(response.body);
      throw Exception('Failed to create category');
    } catch (e) { 
      throw Exception('Category Error: ${e.toString()}');
    }
  }

  // --- PASSWORD RESET ---
  static Future<void> forgotPassword(String email) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(timeoutDuration);
    } catch (e) { throw Exception('Failed to send reset email'); }
  }

  static Future<void> resetPassword(String email, String password) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(timeoutDuration);
    } catch (e) { throw Exception('Failed to reset password'); }
  }

  // --- NOTIFICATIONS ---
  static Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/notifications/read-all/$userId'),
      ).timeout(timeoutDuration);
    } catch (e) { /* silent */ }
  }

  // --- LEVELS (Level Service) ---
  static Future<List<dynamic>> getLevels() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/levels')).timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> getUserLevel(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/levels/user/$userId')).timeout(timeoutDuration);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'levelId': 1};
    } catch (e) { return {'levelId': 1}; }
  }

  static Future<void> moveUserLevel(String userId, int levelId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/levels/move'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'levelId': levelId}),
      ).timeout(timeoutDuration);
    } catch (e) { /* silent */ }
  }

  // --- FOLLOW SYSTEM ---
  static Future<Map<String, dynamic>> followTutor({
    required String followerId,
    required String tutorId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'followerId': followerId, 'tutorId': tutorId}),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to follow: ${response.body}');
    } catch (e) {
      throw Exception('Follow error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> unfollowTutor({
    required String followerId,
    required String tutorId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/unfollow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'followerId': followerId, 'tutorId': tutorId}),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to unfollow: ${response.body}');
    } catch (e) {
      throw Exception('Unfollow error: ${e.toString()}');
    }
  }

  static Future<bool> checkFollowStatus({
    required String followerId,
    required String tutorId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/follow/check?followerId=$followerId&tutorId=$tutorId'),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['isFollowing'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // --- APP VERSION CONTROL ---
  static Future<Map<String, dynamic>> getLatestAppVersion() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/app-version'),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Version check failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Version check error: ${e.toString()}');
    }
  }

  // --- VERIFICATION & EXAMS (Verification Service) ---
  static Future<Map<String, dynamic>> getVerificationStatus(String tutorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verification/status/$tutorId'),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'verified': false, 'status': 'none'};
    } catch (e) {
      return {'verified': false, 'status': 'none', 'error': e.toString()};
    }
  }

  static Future<List<dynamic>> generateExam({
    required String tutorId,
    required String specialization,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verification/exam/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tutorId': tutorId,
          'specialization': specialization,
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to generate exam: ${response.statusCode}');
    } catch (e) {
      throw Exception('Exam Generation Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> submitExam({
    required String tutorId,
    required String specialization,
    required Map<String, String> answers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verification/exam/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tutorId': tutorId,
          'specialization': specialization,
          'answers': answers,
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to submit exam: ${response.statusCode}');
    } catch (e) {
      throw Exception('Exam Submission Error: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getAllVerifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verification/admin/all'),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- PAYMENTS (Payment Service) ---
  static Future<Map<String, dynamic>> createPayment({
    required String userId,
    required String courseId,
    required double amount,
    required String method,
    required String phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'courseId': courseId,
          'amount': amount,
          'method': method,
          'phoneNumber': phoneNumber,
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Payment checkout initiation failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Payment Checkout Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> authorizePayment({
    required String paymentId,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/authorize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'paymentId': paymentId,
          'pin': pin,
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Payment authorization failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Payment Authorization Error: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getUserPayments(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/user/$userId'),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- BLOGS (Blog Service) ---
  static Future<List<dynamic>> getBlogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/blogs')).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('GetBlogs Error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getBlogById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/blogs/$id')).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('GetBlogById Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> createBlog({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    String? imageUrl,
    String? category,
    String? readTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/blogs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'content': content,
          'authorId': authorId,
          'authorName': authorName,
          'authorAvatarUrl': authorAvatarUrl,
          'imageUrl': imageUrl,
          'category': category,
          'readTime': readTime,
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to create blog: ${response.statusCode}');
    } catch (e) {
      throw Exception('CreateBlog Error: ${e.toString()}');
    }
  }

  static Future<String> uploadBlogImage(String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/blogs/upload'));
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
      var response = await request.send().timeout(timeoutDuration);
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        return json['url'];
      }
      throw Exception('Upload image failed');
    } catch (e) {
      throw Exception('UploadBlogImage Error: ${e.toString()}');
    }
  }


  static Future<bool> deleteComment(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/comments/$id'),
      ).timeout(timeoutDuration);
      return response.statusCode == 200;
    } catch (e) {
      print('DeleteComment Error: $e');
      return false;
    }
  }
}


