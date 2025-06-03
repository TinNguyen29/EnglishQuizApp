import 'dart:convert';
// import 'package:http/http.dart' as http; // Xóa dòng này
import 'package:dio/dio.dart'; // Thêm dòng này
import 'package:retry/retry.dart';
import 'package:englishquizapp/constants/server_config.dart';
import 'package:englishquizapp/services/auth_service.dart';
import 'package:englishquizapp/models/user_ranking.dart'; // Import UserRanking model

class RankingService {
  static final Dio _dio = Dio(); // Khởi tạo Dio client
  static const String endpoint = '/score';

  // Thay đổi kiểu trả về thành Future<List<UserRanking>>
  static Future<List<UserRanking>> fetchRankings(String mode) async {
    if (!['easy', 'normal', 'hard'].contains(mode.toLowerCase())) {
      return Future.error('Mức độ không hợp lệ. Chọn easy, normal hoặc hard.');
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final String url = '$baseUrl/api$endpoint/ranking/$mode';
    final token = await AuthService.getToken();

    if (token == null) {
      return Future.error('Vui lòng đăng nhập để xem bảng xếp hạng.');
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
      print('Response data: ${response.data}'); // Dio trả về data đã parse

      if (response.statusCode == 401) {
        return Future.error('Không được phép: Vui lòng đăng nhập lại.');
      }

      if (response.statusCode == 404) {
        return Future.error('Không tìm thấy endpoint. Vui lòng kiểm tra URL.');
      }

      if (response.statusCode == 200) {
        // Dio đã tự động parse JSON, response.data sẽ là List<dynamic>
        final List<dynamic> data = response.data;

        // Chuyển đổi List<dynamic> thành List<UserRanking>
        return data.map((jsonItem) => UserRanking.fromJson(jsonItem as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Lỗi server: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      print('❌ Lỗi gọi API ranking: ${e.message}');
      if (e.response != null) {
        print('Phản hồi lỗi từ server: ${e.response?.data}');
      }
      throw Exception('Không thể kết nối đến server: ${e.message}');
    } catch (e) {
      print('❌ Lỗi không xác định khi gọi API ranking: $e');
      throw Exception('Lỗi không xác định khi gọi API ranking: $e');
    }
  }
}
