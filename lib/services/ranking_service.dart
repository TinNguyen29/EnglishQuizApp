import 'dart:convert';
import 'package:http/http.dart' as http;

class RankingService {
  static const String _baseUrl = 'http://10.106.19.89:3000/api/score' ;

  static Future<List<Map<String, dynamic>>> fetchRankings(String mode) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/ranking/$mode'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return {
            'rank': index + 1,
            'username': item['username'],
            'email': item['email'],
            'score': item['maxScore'],  // CHỖ NÀY phải trùng với dữ liệu từ server
            'level': item['level'] ?? 'N/A' // fallback nếu không có
          };
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
