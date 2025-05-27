import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
import 'package:englishquizapp/constants/server_config.dart';
import 'package:englishquizapp/services/auth_service.dart';

class ScoreService {
  static Future<String> getBaseUrl() async => await ServerConfig.getBaseUrl();

  /// Lưu điểm
  static Future<void> saveScore({
    required String userId,
    required int score,
    required String mode,
    required int duration,
  }) async {
    final baseUrl = await getBaseUrl();
    final Uri url = Uri.parse('$baseUrl/api/score');
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập để lưu điểm.');
    }

    try {
      final response = await retry(
            () => http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'userId': userId,
            'score': score,
            'mode': mode,
            'duration': duration,
          }),
        ).timeout(const Duration(seconds: 10)),
        maxAttempts: 3,
      );

      print('📤 Save Score body: ${jsonEncode({
        'userId': userId,
        'score': score,
        'mode': mode,
        'duration': duration,
      })}');

      print('Save Score response: ${response.body}');
      if (response.statusCode != 201) {
        throw Exception('❌ Lỗi khi lưu điểm: ${response.body}');
      }
    } catch (e) {
      print('❌ Lỗi khi gửi yêu cầu lưu điểm: $e');
      throw Exception('Lỗi khi gửi yêu cầu lưu điểm: $e');
    }
  }

  /// Lưu chi tiết quiz
  static Future<void> saveQuizDetails({
    required String userId,
    required String quizId,
    required String level,
    required List<Map<String, dynamic>> answers,
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
    final Uri url = Uri.parse('$baseUrl/api/quiz-details');
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập để lưu chi tiết bài làm.');
    }

    try {
      final formattedAnswers = answers.map((answer) {
        if (answer['questionId'] == null || answer['selectedAnswer'] == null) {
          throw Exception('Câu trả lời không hợp lệ: Thiếu questionId hoặc selectedAnswer.');
        }
        return {
          'questionId': answer['questionId'],
          'answer': answer['selectedAnswer'],
          'timeTaken': answer['timeTaken'] ?? 0,
        };
      }).toList();

      final response = await retry(
            () => http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'userId': userId,
            'quizId': quizId,
            'level': level,
            'answers': formattedAnswers,
          }),
        ).timeout(Duration(seconds: 10)),
        maxAttempts: 3,
        delayFactor: Duration(seconds: 1),
      );

      print('Save Quiz Details URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Không được phép: Vui lòng đăng nhập lại.');
      }

      if (response.statusCode == 404) {
        throw Exception('Không tìm thấy endpoint. Vui lòng kiểm tra URL.');
      }

      if (response.headers['content-type']?.contains('application/json') != true) {
        throw Exception('Phản hồi không phải JSON.');
      }

      if (response.statusCode != 201) {
        throw Exception('❌ Lỗi khi lưu chi tiết quiz: ${response.body}');
      }
      print('✅ Lưu chi tiết bài làm thành công!');
    } catch (e) {
      print('❌ Lỗi kết nối khi lưu chi tiết quiz: $e');
      rethrow;
    }
  }

  /// Lấy bảng xếp hạng
  static Future<List<Map<String, dynamic>>> getRanking(String mode) async {
    if (!['easy', 'normal', 'hard'].contains(mode.toLowerCase())) {
      throw Exception('Mức độ không hợp lệ');
    }

    final baseUrl = await getBaseUrl();
    final Uri url = Uri.parse('$baseUrl/api/score/ranking/$mode');
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập để xem bảng xếp hạng.');
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

      print('Ranking URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Không được phép: Vui lòng đăng nhập lại.');
      }

      if (response.statusCode == 404) {
        throw Exception('Không tìm thấy endpoint. Vui lòng kiểm tra URL.');
      }

      if (response.headers['content-type']?.contains('application/json') != true) {
        throw Exception('Phản hồi không phải JSON.');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Không thể lấy bảng xếp hạng: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Lỗi kết nối khi lấy ranking: $e');
      rethrow;
    }
  }
}