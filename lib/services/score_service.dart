import 'dart:convert';
// import 'package:http/http.dart' as http; // Không cần thiết nếu chuyển sang Dio hoàn toàn
import 'package:dio/dio.dart'; // Import Dio
import 'package:retry/retry.dart';
import 'package:englishquizapp/constants/server_config.dart';
import 'package:englishquizapp/services/auth_service.dart';
import 'package:englishquizapp/models/user_ranking.dart'; // Import model mới

class ScoreService {
  // Khởi tạo Dio client
  static final Dio _dio = Dio();

  static Future<String> getBaseUrl() async => await ServerConfig.getBaseUrl();

  /// Lưu điểm
  static Future<void> saveScore({
    required String userId,
    required int score,
    required String mode,
    required int duration,
  }) async {
    final baseUrl = await getBaseUrl();
    final String url = '$baseUrl/api/score';
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập để lưu điểm.');
    }

    try {
      final response = await retry(
            () => _dio.post( // Sử dụng _dio.post
          url,
          options: Options( // Cấu hình headers và timeout cho Dio
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            sendTimeout: const Duration(seconds: 10), // Timeout cho gửi request
            receiveTimeout: const Duration(seconds: 10), // Timeout cho nhận response
          ),
          data: { // body trong Dio là data
            'userId': userId,
            'score': score,
            'mode': mode,
            'duration': duration,
          },
        ),
        maxAttempts: 3,
      );

      print('📤 Save Score body: ${jsonEncode({
        'userId': userId,
        'score': score,
        'mode': mode,
        'duration': duration,
      })}');

      print('Save Score response: ${response.data}'); // response.data cho Dio
      if (response.statusCode != 201) {
        throw Exception('❌ Lỗi khi lưu điểm: ${response.data}');
      }
    } on DioException catch (e) { // Bắt DioException
      print('❌ Lỗi khi gửi yêu cầu lưu điểm: ${e.message}');
      throw Exception('Lỗi khi gửi yêu cầu lưu điểm: ${e.message}');
    } catch (e) {
      print('❌ Lỗi không xác định khi gửi yêu cầu lưu điểm: $e');
      throw Exception('Lỗi không xác định khi gửi yêu cầu lưu điểm: $e');
    }
  }

  /// Lưu chi tiết quiz
  static Future<void> saveQuizDetails({
    required String userId,
    required String quizId,
    required String level,
    required List<Map<String, dynamic>> answers,
    required int score,
    required int duration, // Thêm trường duration
  }) async {
    if (userId.isEmpty || quizId.isEmpty) {
      throw Exception('userId và quizId không được để trống.');
    }
    if (!['easy', 'normal', 'hard'].contains(level.toLowerCase())) {
      throw Exception('Mức độ không hợp lệ');
    }
    if (answers.isEmpty) {
      throw Exception('Danh sách câu trả lời không được để trống.');
    }

    final baseUrl = await getBaseUrl();
    final String url = '$baseUrl/api/quiz-details';
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập để lưu chi tiết bài làm.');
    }

    try {
      final formattedAnswers = answers.map((answer) {
        if (answer['questionId'] == null || answer['isCorrect'] == null) {
          throw Exception('Câu trả lời không hợp lệ: Thiếu questionId hoặc isCorrect.');
        }
        return {
          'questionId': answer['questionId'],
          'selectedAnswer': answer['selectedAnswer'],
          'timeTaken': answer['timeTaken'] ?? 0,
          'isCorrect': answer['isCorrect'],
        };
      }).toList();

      final response = await retry(
            () => _dio.post(
          url,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
          data: {
            'userId': userId,
            'quizId': quizId,
            'level': level,
            'answers': formattedAnswers,
            'score': score,
            'duration': duration,
          },
        ),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );

      print('✅ Save Quiz Details response: ${response.data}');
      if (response.statusCode != 201) {
        throw Exception('❌ Lỗi khi lưu chi tiết quiz: ${response.data}');
      }
    } on DioException catch (e) {
      print('❌ Lỗi kết nối khi lưu chi tiết quiz: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Lỗi không xác định khi lưu chi tiết quiz: $e');
      rethrow;
    }
  }

  /// Lấy bảng xếp hạng
  static Future<List<UserRanking>> getRanking(String mode) async {
    if (!['easy', 'normal', 'hard'].contains(mode.toLowerCase())) {
      throw Exception('Mức độ không hợp lệ');
    }

    final baseUrl = await getBaseUrl();
    final String url = '$baseUrl/api/score/ranking/$mode';
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập để xem bảng xếp hạng.');
    }

    try {
      final response = await retry(
            () => _dio.get( // Sử dụng _dio.get
          url,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );

      print('Ranking URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response data: ${response.data}'); // response.data cho Dio
      // Đã xóa dòng gây lỗi: print('Response data bytes: ${response.dataBytes}');

      if (response.statusCode == 401) {
        throw Exception('Không được phép: Vui lòng đăng nhập lại.');
      }

      if (response.statusCode == 404) {
        throw Exception('Không tìm thấy endpoint. Vui lòng kiểm tra URL.');
      }

      if (response.statusCode == 200) {
        // Dio tự động parse JSON, response.data đã là List<dynamic> hoặc Map<String, dynamic>
        // Không cần jsonDecode(response.body) nữa
        final List<dynamic> data = response.data;

        // Kiểm tra nếu data là null hoặc không phải List
        if (data == null || data is! List) {
          throw Exception('Phản hồi dữ liệu không hợp lệ: Không phải danh sách.');
        }

        return data.map((json) => UserRanking.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Không thể lấy bảng xếp hạng: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) { // Bắt DioException
      print('❌ Lỗi kết nối khi lấy ranking: ${e.message}');
      // Có thể kiểm tra e.response?.data để xem phản hồi lỗi từ server
      if (e.response != null) {
        print('Phản hồi lỗi từ server: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      print('❌ Lỗi không xác định khi lấy ranking: $e');
      rethrow;
    }
  }
}
