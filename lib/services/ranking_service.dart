import 'dart:convert';
import 'package:http/http.dart' as http;

class RankingService {
  static const String _baseUrl = 'http://192.168.1.104:3000';

  static Future<List<Map<String, dynamic>>> fetchRankings() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/score/all'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => {
          'rank': item['rank'],
          'username': item['username'],
          'email': item['email'],        // <- THÊM nếu cần email
          'score': item['score'],
          'level': item['level'],
        }).toList();
      } else {
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi gọi API ranking: $e');
      throw Exception('Không thể kết nối đến server.');
    }
  }
}
