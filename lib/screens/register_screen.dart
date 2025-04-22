import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  String message = "";
  bool isLoading = false;
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  void register() async {
    final username = usernameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = passCtrl.text;
    final confirmPassword = confirmCtrl.text;

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        message = "Vui lòng điền đầy đủ thông tin.";
      });
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      setState(() {
        message = "Email không hợp lệ.";
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        message = "Mật khẩu xác nhận không khớp.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = "";
    });

    final res = await AuthService.register(username, email, password);

    setState(() {
      isLoading = false;
      message = res['message'] ?? 'Lỗi không xác định';
    });

    if (res['message'] == 'Đăng ký thành công') {
      usernameCtrl.clear();
      emailCtrl.clear();
      passCtrl.clear();
      confirmCtrl.clear();
      Navigator.pop(context);
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.teal[800]),
        suffixIcon: toggleVisibility != null
            ? IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: toggleVisibility,
        )
            : null,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[100],
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal.shade800),
          borderRadius: BorderRadius.circular(30),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal.shade900, width: 2),
          borderRadius: BorderRadius.circular(30),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.app_registration, size: 72, color: Colors.teal[800]),
              const SizedBox(height: 16),
              Text(
                'Tạo tài khoản',
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.teal[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              buildTextField(
                controller: usernameCtrl,
                hintText: 'Họ và tên',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              buildTextField(
                controller: emailCtrl,
                hintText: 'Email',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),

              buildTextField(
                controller: passCtrl,
                hintText: 'Mật khẩu',
                icon: Icons.lock_outline,
                obscure: _obscureText,
                toggleVisibility: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
              const SizedBox(height: 16),

              buildTextField(
                controller: confirmCtrl,
                hintText: 'Xác nhận mật khẩu',
                icon: Icons.lock_outline,
                obscure: _obscureConfirmText,
                toggleVisibility: () {
                  setState(() {
                    _obscureConfirmText = !_obscureConfirmText;
                  });
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Đăng ký',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (message.isNotEmpty)
                Text(
                  message,
                  style: TextStyle(
                    color: message == 'Đăng ký thành công'
                        ? Colors.green
                        : Colors.redAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Đã có tài khoản? Đăng nhập",
                  style: TextStyle(color: Colors.teal[800]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
