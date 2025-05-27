import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
import 'package:englishquizapp/constants/server_config.dart';
import 'package:englishquizapp/services/auth_service.dart';

class QuizService {
  static const String endpoint = '/questions';

  /// Lấy danh sách câu hỏi theo level
  static Future<List<Map<String, dynamic>>> fetchQuestions(String level) async {
    if (!['easy', 'normal', 'hard'].contains(level.toLowerCase())) {
      return Future.error('Mức độ không hợp lệ. Chọn easy, normal hoặc hard.');
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final Uri url = Uri.parse('$baseUrl/api$endpoint?level=$level');
    final token = await AuthService.getToken();

    if (token == null) {
      return Future.error('Vui lòng đăng nhập để lấy câu hỏi.');
    }

    try {
      final response = await retry(
            () => http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(Duration(seconds: 10)),
        maxAttempts: 3,
        delayFactor: Duration(seconds: 1),
      );

      print('Fetch Questions URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        return Future.error('Không được phép: Vui lòng đăng nhập lại.');
      }

      if (response.statusCode == 404) {
        return Future.error('Không tìm thấy endpoint. Vui lòng kiểm tra URL.');
      }

      if (response.headers['content-type']?.contains('application/json') != true) {
        return Future.error('Phản hồi không phải JSON.');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else {
          throw Exception('Dữ liệu trả về không phải là một danh sách');
        }
      } else {
        throw Exception('Lỗi tải dữ liệu: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Lỗi kết nối (fetch questions): $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Tạo câu hỏi mới
  static Future<void> createQuestion(Map<String, dynamic> data) async {
    if (data['content'] == null ||
        data['options'] == null ||
        data['correct_answer'] == null ||
        data['level'] == null) {
      throw Exception('Dữ liệu câu hỏi không hợp lệ: Thiếu các trường bắt buộc.');
    }
    if (!['easy', 'normal', 'hard'].contains(data['level'].toLowerCase())) {
      throw Exception('Mức độ không hợp lệ');
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final Uri url = Uri.parse('$baseUrl/api$endpoint');
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập với tài khoản admin để tạo câu hỏi.');
    }

    try {
      print('Dữ liệu gửi lên backend:');
      print(jsonEncode(data));

      final response = await retry(
            () => http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(data),
        ).timeout(Duration(seconds: 10)),
        maxAttempts: 3,
        delayFactor: Duration(seconds: 1),
      );

      print('Create Question URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Không được phép: Vui lòng đăng nhập với tài khoản admin.');
      }

      if (response.statusCode == 403) {
        throw Exception('Chỉ admin mới được tạo câu hỏi.');
      }

      if (response.headers['content-type']?.contains('application/json') != true) {
        throw Exception('Phản hồi không phải JSON.');
      }

      if (response.statusCode != 201) {
        throw Exception('Tạo câu hỏi thất bại: ${response.statusCode} - ${response.body}');
      }
      print('✅ Tạo câu hỏi thành công!');
    } catch (e) {
      print('Lỗi kết nối (create question): $e');
      throw Exception('Lỗi kết nối khi tạo câu hỏi: $e');
    }
  }

  /// Cập nhật câu hỏi
  static Future<void> updateQuestion(String id, Map<String, dynamic> data) async {
    if (id.isEmpty) {
      throw Exception('ID câu hỏi không hợp lệ');
    }
    if (data['content'] == null ||
        data['options'] == null ||
        data['correct_answer'] == null ||
        data['level'] == null) {
      throw Exception('Dữ liệu câu hỏi không hợp lệ: Thiếu các trường bắt buộc.');
    }
    if (!['easy', 'normal', 'hard'].contains(data['level'].toLowerCase())) {
      throw Exception('Mức độ không hợp lệ');
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final Uri url = Uri.parse('$baseUrl/api$endpoint/$id');
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập với tài khoản admin để cập nhật câu hỏi.');
    }

    try {
      final response = await retry(
            () => http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(data),
        ).timeout(Duration(seconds: 10)),
        maxAttempts: 3,
        delayFactor: Duration(seconds: 1),
      );

      print('Update Question URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Không được phép: Vui lòng đăng nhập với tài khoản admin.');
      }

      if (response.statusCode == 403) {
        throw Exception('Chỉ admin mới được cập nhật câu hỏi.');
      }

      if (response.statusCode == 404) {
        throw Exception('Không tìm thấy câu hỏi.');
      }

      if (response.headers['content-type']?.contains('application/json') != true) {
        throw Exception('Phản hồi không phải JSON.');
      }

      if (response.statusCode != 200) {
        throw Exception('Cập nhật câu hỏi thất bại: ${response.statusCode} - ${response.body}');
      }
      print('✅ Cập nhật câu hỏi thành công!');
    } catch (e) {
      print('Lỗi kết nối (update question): $e');
      throw Exception('Lỗi kết nối khi cập nhật câu hỏi: $e');
    }
  }

  /// Xóa câu hỏi
  static Future<void> deleteQuestion(String id) async {
    if (id.isEmpty) {
      throw Exception('ID câu hỏi không hợp lệ');
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final Uri url = Uri.parse('$baseUrl/api$endpoint/$id');
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập với tài khoản admin để xóa câu hỏi.');
    }

    try {
      final response = await retry(
            () => http.delete(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(Duration(seconds: 10)),
        maxAttempts: 3,
        delayFactor: Duration(seconds: 1),
      );

      print('Delete Question URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Không được phép: Vui lòng đăng nhập với tài khoản admin.');
      }

      if (response.statusCode == 403) {
        throw Exception('Chỉ admin mới được xóa câu hỏi.');
      }

      if (response.statusCode == 404) {
        throw Exception('Không tìm thấy câu hỏi.');
      }

      if (response.headers['content-type']?.contains('application/json') != true) {
        throw Exception('Phản hồi không phải JSON.');
      }

      if (response.statusCode != 200) {
        throw Exception('Xóa câu hỏi thất bại: ${response.statusCode} - ${response.body}');
      }
      print('✅ Xóa câu hỏi thành công!');
    } catch (e) {
      print('Lỗi kết nối (delete question): $e');
      throw Exception('Lỗi kết nối khi xóa câu hỏi: $e');
    }
  }

  /// Lấy lịch sử làm bài của người dùng theo email
  static Future<List<Map<String, dynamic>>> getUserTests(String email) async {
    if (email.isEmpty) {
      throw Exception('Email không được để trống.');
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final Uri url = Uri.parse('$baseUrl/api/quiz-details?email=$email');
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập để xem lịch sử.');
    }

    try {
      final response = await retry(
            () => http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(Duration(seconds: 10)),
        maxAttempts: 3,
        delayFactor: Duration(seconds: 1),
      );

      print('Get Quiz History URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Không được phép: Vui lòng đăng nhập lại.');
      }

      if (response.statusCode == 404) {
        return []; // không có dữ liệu lịch sử nào
      }

      if (response.headers['content-type']?.contains('application/json') != true) {
        throw Exception('Phản hồi không phải JSON.');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Không thể tải lịch sử: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Lỗi kết nối (getUserTests): $e');
      throw Exception('Lỗi kết nối khi tải lịch sử: $e');
    }
  }

}
