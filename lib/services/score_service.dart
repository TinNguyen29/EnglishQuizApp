import 'dart:convert';
import 'package:http/http.dart' as http;

class ScoreService {
  static const String baseUrl = 'http://192.168.1.104:3000/api/score'; // Đổi IP nếu cần

  // Lưu điểm người dùng vào server
  static Future<void> saveScore({
    required String email,
    required int score,
    required String level,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'score': score,
          'level': level,
        }),
      );

      // Kiểm tra mã trạng thái của phản hồi
      if (response.statusCode == 201) {
        print("Điểm đã được lưu thành công!");
      } else {
        throw Exception('Lỗi khi lưu điểm: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Xử lý lỗi nếu có sự cố với việc kết nối hoặc yêu cầu
      print("Lỗi khi gửi yêu cầu lưu điểm: $e");
      throw Exception("Lỗi khi gửi yêu cầu lưu điểm: $e");
    }
  }
  static Future<void> saveQuizDetails({
    required String email,
    required String level,
    required int score,
    required int totalQuestions,
    required List<Map<String, dynamic>> answers,
  }) async {
    final url = Uri.parse('$baseUrl/quiz-details');
    final now = DateTime.now().toIso8601String();

    final body = {
      "email": email,
      "level": level,
      "score": score,
      "totalQuestions": totalQuestions,
      "submittedAt": now,
      "answers": answers,
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('❌ Lỗi khi lưu chi tiết quiz: ${response.body}');
    }
  }


}
