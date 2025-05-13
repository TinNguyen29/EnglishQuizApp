import 'dart:convert';
import 'package:http/http.dart' as http;

class QuizService {
  static const String baseUrl = 'http://10.106.19.89:3000/api/questions';

  /// Lấy danh sách câu hỏi theo level (easy, normal, hard)
  static Future<List<Map<String, dynamic>>> fetchQuestions(String level) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?level=$level'));

      // Kiểm tra nếu API trả về mã thành công (200 OK)
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Kiểm tra xem dữ liệu trả về có phải là mảng hợp lệ hay không
        if (data is List) {
          return data.cast<Map<String, dynamic>>(); // Chuyển dữ liệu thành List<Map<String, dynamic>>
        } else {
          throw Exception('Dữ liệu trả về không phải là một danh sách');
        }
      } else {
        throw Exception('Lỗi tải dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      // Nếu có lỗi kết nối, sẽ ném lỗi với thông báo cụ thể
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Tạo câu hỏi mới
  static Future<void> createQuestion(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode != 201) {
        throw Exception('Tạo câu hỏi thất bại: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối khi tạo câu hỏi: $e');
    }
  }

  /// Cập nhật câu hỏi
  static Future<void> updateQuestion(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode != 200) {
        throw Exception('Cập nhật câu hỏi thất bại: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối khi cập nhật câu hỏi: $e');
    }
  }

  /// Xóa câu hỏi
  static Future<void> deleteQuestion(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));

      if (response.statusCode != 200) {
        throw Exception('Xóa câu hỏi thất bại: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối khi xóa câu hỏi: $e');
    }
  }
}
