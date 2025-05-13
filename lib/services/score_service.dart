import 'dart:convert';
import 'package:http/http.dart' as http;

class ScoreService {
  static const String baseUrl = 'http://10.106.19.89:3000/api/score'; // Đổi IP nếu backend khác

  // ✅ Gọi API: Lưu điểm
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

      if (response.statusCode == 201) {
        print("✅ Điểm đã được lưu thành công!");
      } else {
        throw Exception('❌ Lỗi khi lưu điểm: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("❌ Lỗi khi gửi yêu cầu lưu điểm: $e");
      throw Exception("Lỗi khi gửi yêu cầu lưu điểm: $e");
    }
  }

  // ✅ Gọi API: Lưu chi tiết quiz
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

  // ✅ Gọi API: Lấy bảng xếp hạng
  static Future<List<Map<String, dynamic>>> getRanking() async {
    final url = Uri.parse('$baseUrl/ranking');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Không thể lấy bảng xếp hạng: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi kết nối khi lấy ranking: $e');
      rethrow;
    }
  }
}
