import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
import 'package:englishquizapp/constants/server_config.dart';
import 'package:englishquizapp/services/auth_service.dart';

class QuizDetailService {
  static const String endpoint = '/quiz-details';

  static Future<bool> submitQuizDetail({
    required String userId,
    required String quizId,
    required String level,
    required List<Map<String, dynamic>> answers,
  }) async {
    if (userId.isEmpty || quizId.isEmpty) {
      return Future.error('userId và quizId không được để trống.');
    }
    if (!['easy', 'normal', 'hard'].contains(level.toLowerCase())) {
      return Future.error('Mức độ không hợp lệ. Chọn easy, normal hoặc hard.');
    }
    if (answers.isEmpty) {
      return Future.error('Danh sách câu trả lời không được để trống.');
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final Uri url = Uri.parse('$baseUrl/api$endpoint');
    final token = await AuthService.getToken();

    if (token == null) {
      return Future.error('Vui lòng đăng nhập để gửi chi tiết bài làm.');
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

      print('Quiz Detail URL: $url');
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

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Lưu chi tiết bài làm thành công: ${responseData['message']}');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ Lỗi khi lưu chi tiết bài làm: ${errorData['message']}');
        return false;
      }
    } catch (e) {
      print('❌ Lỗi kết nối khi lưu chi tiết bài làm: $e');
      return false;
    }
  }
}