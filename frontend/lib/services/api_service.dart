import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user_role.dart';

class ApiService {
  // Use host IP for physical device connection over Wi-Fi
  static const String hostIp = '192.168.1.154'; 
  static const String authBaseUrl = 'http://$hostIp:3001/api';
  static const String courseBaseUrl = 'http://$hostIp:3002/api';
  static const Duration timeoutDuration = Duration(seconds: 15);
  
  // Real Image Upload Method
  static Future<String> uploadAvatar(String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$authBaseUrl/auth/avatar'));
      request.files.add(await http.MultipartFile.fromPath('avatar', filePath));
      
      var response = await request.send().timeout(timeoutDuration);
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        // Important: Return the full URL for network display
        return 'http://$hostIp:3001${json['url']}';
      }
      throw Exception('Upload failed');
    } catch (e) {
      throw Exception('Upload Error: ${e.toString()}');
    }
  }

  // Real Video Upload Method
  static Future<String> uploadVideo(String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$courseBaseUrl/shorts/upload'));
      request.files.add(await http.MultipartFile.fromPath('video', filePath));
      
      var response = await request.send().timeout(const Duration(seconds: 60)); // Long timeout for video
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        // Important: Return the full URL for the frontend to play
        return 'http://$hostIp:3002${json['url']}';
      }
      throw Exception('Video upload failed');
    } catch (e) {
      throw Exception('Video Upload Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? specialization,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/auth/register'),
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

  // Course & Category Methods
  static Future<List<dynamic>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$courseBaseUrl/categories'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createCategory(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$courseBaseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      ).timeout(timeoutDuration);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to create category');
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
        Uri.parse('$authBaseUrl/auth/login'),
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
      final response = await http.post(
        Uri.parse('$authBaseUrl/auth/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'role': role,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Google Login failed';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Google Auth Error: ${e.toString()}');
    }
  }

  // Course Service Methods
  static Future<List<dynamic>> getCourses({String? categoryId, String? query}) async {
    try {
      String url = '$courseBaseUrl/courses?';
      if (categoryId != null) url += 'categoryId=$categoryId&';
      if (query != null) url += 'query=${Uri.encodeComponent(query)}&';
      
      final response = await http.get(Uri.parse(url)).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      throw Exception('Course Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getUser(String id) async {
    try {
      final response = await http.get(Uri.parse('$authBaseUrl/auth/$id')).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('User fetch failed');
    } catch (e) {
      throw Exception('Fetch Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> enrollCourse({required String courseId, required String studentId}) async {
    try {
      final response = await http.post(
        Uri.parse('$courseBaseUrl/courses/enroll'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'courseId': courseId,
          'studentId': studentId,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Enrollment failed';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Enrollment Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> createCourse({
    required String title,
    required String description,
    required double price,
    required String instructorId,
    String? imageUrl,
    String? categoryId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$courseBaseUrl/courses'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'price': price,
          'instructorId': instructorId,
          'imageUrl': imageUrl,
          'categoryId': categoryId,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create course');
      }
    } catch (e) {
      throw Exception('Creation Error: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getEnrolledStudents(String tutorId) async {
    try {
      final response = await http.get(Uri.parse('$courseBaseUrl/courses/tutor/$tutorId/students'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await http.get(Uri.parse('$courseBaseUrl/courses/stats'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch admin stats');
    } catch (e) {
      throw Exception('Stats Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getTutorStats(String tutorId) async {
    try {
      final response = await http.get(Uri.parse('$courseBaseUrl/courses/stats?tutorId=$tutorId'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch stats');
    } catch (e) {
      throw Exception('Stats Error: ${e.toString()}');
    }
  }

  // Forgot Password Methods
  static Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(timeoutDuration);

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('Forgot Password Error: ${e.toString()}');
    }
  }

  static Future<void> resetPassword(String email, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'newPassword': newPassword,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Reset failed');
      }
    } catch (e) {
      throw Exception('Reset Password Error: ${e.toString()}');
    }
  }

  // New Batch & Shorts Methods
  static Future<List<dynamic>> getUsersBatch(List<String> ids) async {
    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/auth/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ids': ids}),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getShorts() async {
    try {
      final response = await http.get(Uri.parse('$courseBaseUrl/shorts'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createShort({
    required String tutorId,
    required String tutorName,
    required String courseName,
    required String description,
    required String videoUrl,
    String? tutorAvatarUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$courseBaseUrl/shorts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tutorId': tutorId,
          'tutorName': tutorName,
          'courseName': courseName,
          'description': description,
          'videoUrl': videoUrl,
          'tutorAvatarUrl': tutorAvatarUrl,
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to upload short');
    } catch (e) {
       throw Exception('Short Upload Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    required String id,
    required String fullName,
    String? specialization,
    String? avatarUrl,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$authBaseUrl/auth/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'specialization': specialization,
          'avatarUrl': avatarUrl,
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

  static Future<List<dynamic>> getTutorCourses(String tutorId) async {
    try {
      final response = await http.get(Uri.parse('$courseBaseUrl/courses/tutor/$tutorId/courses'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getNotifications(String userId) async {
    try {
      final response = await http.get(Uri.parse('$courseBaseUrl/courses/notifications/$userId'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> markNotificationAsRead(String id) async {
    try {
      await http.put(Uri.parse('$courseBaseUrl/courses/notifications/$id/read'))
          .timeout(timeoutDuration);
    } catch (e) { /* silent */ }
  }

  static Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await http.put(Uri.parse('$courseBaseUrl/courses/notifications/user/$userId/read-all'))
          .timeout(timeoutDuration);
    } catch (e) { /* silent */ }
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? senderName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$courseBaseUrl/courses/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId,
          'receiverId': receiverId,
          'content': content,
          'senderName': senderName,
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to send message');
    } catch (e) {
      throw Exception('Message Error: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getMessages(String userId) async {
    try {
      final response = await http.get(Uri.parse('$courseBaseUrl/courses/messages/$userId'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> markMessageAsRead(String id) async {
    try {
      await http.put(Uri.parse('$courseBaseUrl/courses/messages/$id/read'))
          .timeout(timeoutDuration);
    } catch (e) { /* silent */ }
  }
}
