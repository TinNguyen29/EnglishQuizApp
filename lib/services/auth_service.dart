import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:englishquizapp/constants/server_config.dart';


class AuthService {
  /// Đăng ký tài khoản mới
  static Future<Map<String, dynamic>> register(String username, String email, String password) async {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return {'success': false, 'message': 'Email không hợp lệ'};
    }
    if (username.isEmpty || username.length < 3) {
      return {'success': false, 'message': 'Tên người dùng phải dài ít nhất 3 ký tự'};
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final Uri url = Uri.parse('$baseUrl/api/register');

    try {
      final response = await retry(
            () => http
            .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
          }),
        )
            .timeout(const Duration(seconds: 10)),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );

      print('Register URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 404) {
        return {'success': false, 'message': 'Không tìm thấy endpoint. Vui lòng kiểm tra URL.'};
      }

      if (response.headers['content-type']?.contains('application/json') != true) {
        return {'success': false, 'message': 'Phản hồi không phải JSON'};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đăng ký thành công',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng ký thất bại',
        };
      }
    } catch (e) {
      print('Lỗi kết nối (register): $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  /// Đăng nhập tài khoản
  static Future<Map<String, dynamic>> login(String email, String password) async {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return {'success': false, 'message': 'Email không hợp lệ'};
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final Uri url = Uri.parse('$baseUrl/api/login');

    try {
      final response = await retry(
            () => http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        ).timeout(const Duration(seconds: 10)),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );

      print('Login URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 404) {
        return {'success': false, 'message': 'Không tìm thấy endpoint. Vui lòng kiểm tra URL.'};
      }

      if (response.statusCode == 401) {
        return {'success': false, 'message': 'Thông tin đăng nhập không đúng'};
      }

      if (response.headers['content-type']?.contains('application/json') != true) {
        return {'success': false, 'message': 'Phản hồi không phải JSON'};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data.containsKey('token') && data.containsKey('user')) {
        final user = data['user'];
        final token = data['token'];

        // Kiểm tra và đảm bảo không có giá trị null trong user
        if (user['id'] == null || user['id'].isEmpty) {
          print('Lỗi: user.id thiếu hoặc không hợp lệ: ${user['id']}');
          return {
            'success': false,
            'message': 'Dữ liệu người dùng không hợp lệ: Thiếu hoặc không có userId',
          };
        }

        if (user['email'] == null || user['email'].isEmpty) {
          print('Lỗi: Thiếu email trong user: $user');
          return {
            'success': false,
            'message': 'Dữ liệu người dùng không hợp lệ: Thiếu email',
          };
        }

        if (user['username'] == null || user['username'].isEmpty) {
          print('Lỗi: Thiếu username trong user: $user');
          return {
            'success': false,
            'message': 'Dữ liệu người dùng không hợp lệ: Thiếu username',
          };
        }

        if (user['role'] == null || user['role'].isEmpty) {
          print('Lỗi: Thiếu role trong user: $user');
          return {
            'success': false,
            'message': 'Dữ liệu người dùng không hợp lệ: Thiếu role',
          };
        }

        try {
          // Lưu token và userId vào SharedPreferences
          await ServerConfig.saveToken(token);
          await ServerConfig.saveUserId(user['id']);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', user['email']);
          await prefs.setString('username', user['username']);
          await prefs.setString('role', user['role']);
        } catch (e) {
          print('Lỗi khi lưu thông tin người dùng: $e');
          return {
            'success': false,
            'message': 'Lỗi khi lưu thông tin người dùng: $e',
          };
        }

        print('Đăng nhập thành công: $user');

        return {
          'success': true,
          'message': 'Đăng nhập thành công',
          'token': token,
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng nhập thất bại',
        };
      }
    } catch (e) {
      print('Lỗi kết nối (login): $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }


  /// Đặt lại mật khẩu
  static Future<Map<String, dynamic>> resetPassword(String email, String newPassword) async {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return {'success': false, 'message': 'Email không hợp lệ'};
    }
    if (newPassword.length < 8) {
      return {'success': false, 'message': 'Mật khẩu mới phải dài ít nhất 8 ký tự'};
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final Uri url = Uri.parse('$baseUrl/api/reset-password');

    try {
      final response = await retry(
            () => http
            .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'newPassword': newPassword,
          }),
        )
            .timeout(const Duration(seconds: 10)),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );

      print('Reset Password URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 404) {
        return {'success': false, 'message': 'Không tìm thấy endpoint. Vui lòng kiểm tra URL.'};
      }

      if (response.headers['content-type']?.contains('application/json') != true) {
        return {'success': false, 'message': 'Phản hồi không phải JSON'};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đặt lại mật khẩu thành công',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đặt lại mật khẩu thất bại',
        };
      }
    } catch (e) {
      print('Lỗi kết nối (reset password): $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  /// Đăng xuất
  static Future<void> logout() async {
    await ServerConfig.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Lưu thông tin người dùng vào SharedPreferences
  static Future<void> saveUserInfo(String username, String email, String role, String token, [String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setString('role', role);
    await ServerConfig.saveToken(token);
    if (userId != null) {
      await ServerConfig.saveUserId(userId);
    }
  }

  /// Lấy token đã lưu
  static Future<String?> getToken() async {
    return await ServerConfig.getToken();
  }

  /// Kiểm tra đã đăng nhập chưa
  static Future<bool> isLoggedIn() async {
    return await ServerConfig.isLoggedIn();
  }

  /// Lấy thông tin người dùng từ local
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<String?> getUserId() async {
    return await ServerConfig.getUserId();
  }
}