import 'package:dio/dio.dart'; // Import Dio
import 'package:englishquizapp/constants/server_config.dart';
import 'package:englishquizapp/services/auth_service.dart';

class QuizService {
  static final Dio _dio = Dio(); // Khởi tạo Dio client
  static const String _quizEndpoint = '/questions';
  static const String _quizDetailsEndpoint = '/quiz-details'; // Endpoint cho lịch sử quiz và chi tiết quiz

  // Hàm để lấy câu hỏi mới theo level
  static Future<List<Map<String, dynamic>>> fetchQuestions(String level) async {
    final baseUrl = await ServerConfig.getBaseUrl();
    final String url = '$baseUrl/api$_quizEndpoint/random?level=$level';
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập để tải câu hỏi.');
    }

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        // Dio tự động parse JSON, response.data đã là List<dynamic>
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Lỗi tải câu hỏi: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('Lỗi kết nối khi tải câu hỏi: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định khi tải câu hỏi: $e');
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
    final String url = '$baseUrl/api$_quizEndpoint'; // Sử dụng _quizEndpoint
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập với tài khoản admin để tạo câu hỏi.');
    }

    try {
      print('Dữ liệu gửi lên backend:');
      print(data); // Dio tự động encode data

      final response = await _dio.post( // Sử dụng _dio.post
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
        data: data, // body trong Dio là data
      );

      print('Create Question URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.data}');

      if (response.statusCode == 401) {
        throw Exception('Không được phép: Vui lòng đăng nhập với tài khoản admin.');
      }

      if (response.statusCode == 403) {
        throw Exception('Chỉ admin mới được tạo câu hỏi.');
      }

      if (response.statusCode != 201) {
        throw Exception('Tạo câu hỏi thất bại: ${response.statusCode} - ${response.data}');
      }
      print('✅ Tạo câu hỏi thành công!');
    } on DioException catch (e) {
      print('Lỗi kết nối (create question): ${e.message}');
      throw Exception('Lỗi kết nối khi tạo câu hỏi: ${e.message}');
    } catch (e) {
      print('Lỗi không xác định khi tạo câu hỏi: $e');
      throw Exception('Lỗi không xác định khi tạo câu hỏi: $e');
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
    final String url = '$baseUrl/api$_quizEndpoint/$id'; // Sử dụng _quizEndpoint
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập với tài khoản admin để cập nhật câu hỏi.');
    }

    try {
      final response = await _dio.put( // Sử dụng _dio.put
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
        data: data, // body trong Dio là data
      );

      print('Update Question URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.data}');

      if (response.statusCode == 401) {
        throw Exception('Không được phép: Vui lòng đăng nhập với tài khoản admin.');
      }

      if (response.statusCode == 403) {
        throw Exception('Chỉ admin mới được cập nhật câu hỏi.');
      }

      if (response.statusCode == 404) {
        throw Exception('Không tìm thấy câu hỏi.');
      }

      if (response.statusCode != 200) {
        throw Exception('Cập nhật câu hỏi thất bại: ${response.statusCode} - ${response.data}');
      }
      print('✅ Cập nhật câu hỏi thành công!');
    } on DioException catch (e) {
      print('Lỗi kết nối (update question): ${e.message}');
      throw Exception('Lỗi kết nối khi cập nhật câu hỏi: ${e.message}');
    } catch (e) {
      print('Lỗi không xác định khi cập nhật câu hỏi: $e');
      throw Exception('Lỗi không xác định khi cập nhật câu hỏi: $e');
    }
  }

  /// Xóa câu hỏi
  static Future<void> deleteQuestion(String id) async {
    if (id.isEmpty) {
      throw Exception('ID câu hỏi không hợp lệ');
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final String url = '$baseUrl/api$_quizEndpoint/$id'; // Sử dụng _quizEndpoint
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập với tài khoản admin để xóa câu hỏi.');
    }

    try {
      final response = await _dio.delete( // Sử dụng _dio.delete
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      print('Delete Question URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.data}');

      if (response.statusCode == 401) {
        throw Exception('Không được phép: Vui lòng đăng nhập với tài khoản admin.');
      }

      if (response.statusCode == 403) {
        throw Exception('Chỉ admin mới được xóa câu hỏi.');
      }

      if (response.statusCode == 404) {
        throw Exception('Không tìm thấy câu hỏi.');
      }

      if (response.statusCode != 200) {
        throw Exception('Xóa câu hỏi thất bại: ${response.statusCode} - ${response.data}');
      }
      print('✅ Xóa câu hỏi thành công!');
    } on DioException catch (e) {
      print('Lỗi kết nối (delete question): ${e.message}');
      throw Exception('Lỗi kết nối khi xóa câu hỏi: $e');
    } catch (e) {
      print('Lỗi không xác định khi xóa câu hỏi: $e');
      throw Exception('Lỗi không xác định khi xóa câu hỏi: $e');
    }
  }

  /// Lấy lịch sử làm bài của người dùng theo email
  static Future<List<Map<String, dynamic>>> getUserTests(String email) async {
    if (email.isEmpty) {
      throw Exception('Email không được để trống.');
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    // Sử dụng _quizDetailsEndpoint đã định nghĩa
    final String url = '$baseUrl/api$_quizDetailsEndpoint?email=$email';
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập để xem lịch sử.');
    }

    try {
      final response = await _dio.get( // Sử dụng _dio.get
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      print('Get Quiz History URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.data}'); // response.data đã là JSON parse

      if (response.statusCode == 200) {
        // Đảm bảo response.data là một List
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else {
          throw Exception('Phản hồi lịch sử quiz không phải là danh sách.');
        }
      } else {
        throw Exception('Không thể tải lịch sử: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      print('❌ Lỗi kết nối (getUserTests): ${e.message}');
      if (e.response != null) {
        print('Phản hồi lỗi từ server: ${e.response?.data}');
      }
      throw Exception('Lỗi kết nối khi tải lịch sử: ${e.message}');
    } catch (e) {
      print('❌ Lỗi không xác định khi tải lịch sử: $e');
      throw Exception('Lỗi không xác định khi tải lịch sử: $e');
    }
  }

  // Hàm để lấy chi tiết một bài quiz cụ thể (cho chức năng làm lại bài)
  static Future<Map<String, dynamic>> getQuizDetailsById(String quizId) async {
    final baseUrl = await ServerConfig.getBaseUrl();
    final String url = '$baseUrl/api$_quizDetailsEndpoint/$quizId'; // Ví dụ: /api/quiz-details/:quizId
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập để xem chi tiết quiz.');
    }

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return response.data;
        } else {
          throw Exception('Phản hồi chi tiết quiz không hợp lệ.');
        }
      } else {
        throw Exception('Lỗi tải chi tiết quiz: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('Lỗi kết nối khi tải chi tiết quiz: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định khi tải chi tiết quiz: $e');
    }
  }
}
