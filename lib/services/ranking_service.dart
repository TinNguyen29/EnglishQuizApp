import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
import 'package:englishquizapp/constants/server_config.dart';
import 'package:englishquizapp/services/auth_service.dart';

class RankingService {
  static const String endpoint = '/score';

  static Future<List<Map<String, dynamic>>> fetchRankings(String mode) async {
    if (!['easy', 'normal', 'hard'].contains(mode.toLowerCase())) {
      return Future.error('Mức độ không hợp lệ. Chọn easy, normal hoặc hard.');
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final Uri url = Uri.parse('$baseUrl/api$endpoint/ranking/$mode');
    final token = await AuthService.getToken();

    if (token == null) {
      return Future.error('Vui lòng đăng nhập để xem bảng xếp hạng.');
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
        return Future.error('Không được phép: Vui lòng đăng nhập lại.');
      }

      if (response.statusCode == 404) {
        return Future.error('Không tìm thấy endpoint. Vui lòng kiểm tra URL.');
      }

      if (response.headers['content-type']?.contains('application/json') != true) {
        return Future.error('Phản hồi không phải JSON.');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return {
            'rank': index + 1,
            'username': item['username'],
            'email': item['email'],
            'score': item['maxScore'],
            'level': mode,
          };
        }).toList();
      } else {
        throw Exception('Lỗi server: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Lỗi gọi API ranking: $e');
      throw Exception('Không thể kết nối đến server: $e');
    }
  }
}