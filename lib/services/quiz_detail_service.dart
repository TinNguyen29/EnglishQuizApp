import 'dart:convert';
import 'package:http/http.dart' as http;

class QuizDetailService {
  static const String baseUrl = 'http://192.168.1.104:3000/api/quiz_details';

  static Future<bool> submitQuizDetail({
    required String email,
    required String level,
    required int score,
    required int totalQuestions,
    required int durationSeconds,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      // Chuyển đổi answers sang định dạng phù hợp
      final formattedAnswers = answers.map((answer) {
        return {
          'questionId': answer['questionId'],
          'selectedAnswer': answer['selectedAnswer'],
          'isCorrect': answer['isCorrect'],
        };
      }).toList();

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'level': level,
          'score': score,
          'totalQuestions': totalQuestions,
          'durationSeconds': durationSeconds,
          'answers': formattedAnswers,
        }),
      );

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