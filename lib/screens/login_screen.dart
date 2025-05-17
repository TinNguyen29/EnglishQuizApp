import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_dashboard.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool isLoading = false;
  String errorMessage = '';
  bool _obscureText = true;

  Future<void> login() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Vui lòng nhập đầy đủ thông tin.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final res = await AuthService.login(email, password);

    setState(() {
      isLoading = false;
    });

    if (res['success'] == true) {
      final user = res['user'];
      final username = user['username'];
      final email = user['email'];
      final role = user['role']?.toString().trim().toLowerCase();

      print('👉 ROLE nhận được từ backend: "$role"');

      if (username != null && email != null) {
        if (role == 'admin') {
          print('👉 Điều hướng đến AdminDashboard');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else {
          print('👉 Điều hướng đến HomeScreen (user thường)');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                email: email,
                username: username,
              ),
            ),
          );
        }
      } else {
        setState(() {
          errorMessage = 'Thông tin người dùng không hợp lệ.';
        });
      }
    } else {
      setState(() {
        errorMessage = res['message'] ?? 'Đăng nhập thất bại';
      });
    }
  }

  Widget _buildInput({
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(isPassword ? Icons.lock : Icons.email),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Đăng nhập',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vui lòng nhập email và mật khẩu để tiếp tục',
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildInput(hint: 'Email', controller: emailCtrl),
              const SizedBox(height: 16),
              _buildInput(hint: 'Mật khẩu', controller: passCtrl, isPassword: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đăng nhập',
                      style:
                      TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              if (errorMessage.isNotEmpty)
                Text(errorMessage, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                    child: const Text('Quên mật khẩu?'),
                  ),
                  const Text(" | "),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text('Đăng ký'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
