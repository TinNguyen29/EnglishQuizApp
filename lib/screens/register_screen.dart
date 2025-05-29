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

  Widget _buildInput({
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? toggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText ?? false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45),
          prefixIcon: Icon(prefixIcon, color: Colors.black54),
          suffixIcon: toggleVisibility != null
              ? IconButton(
            icon: Icon(
              (obscureText ?? false) ? Icons.visibility_off : Icons.visibility,
              color: Colors.black54,
            ),
            onPressed: toggleVisibility,
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Logo/Icon section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add,
                  size: 60,
                  color: Colors.teal,
                ),
              ),

              const SizedBox(height: 32),

              // Welcome text
              const Text(
                'Tạo tài khoản mới',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Điền thông tin để bắt đầu hành trình học tập',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Register form card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInput(
                      hint: 'Nhập họ và tên',
                      controller: usernameCtrl,
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),

                    _buildInput(
                      hint: 'Nhập email của bạn',
                      controller: emailCtrl,
                      prefixIcon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 20),

                    _buildInput(
                      hint: 'Nhập mật khẩu',
                      controller: passCtrl,
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscureText,
                      toggleVisibility: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildInput(
                      hint: 'Xác nhận mật khẩu',
                      controller: confirmCtrl,
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscureConfirmText,
                      toggleVisibility: () {
                        setState(() {
                          _obscureConfirmText = !_obscureConfirmText;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Message display
                    if (message.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: message == 'Đăng ký thành công'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: message == 'Đăng ký thành công'
                                ? Colors.green.withOpacity(0.3)
                                : Colors.redAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              message == 'Đăng ký thành công'
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              color: message == 'Đăng ký thành công'
                                  ? Colors.green
                                  : Colors.redAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                message,
                                style: TextStyle(
                                  color: message == 'Đăng ký thành công'
                                      ? Colors.green
                                      : Colors.redAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Register button
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isLoading
                            ? null
                            : [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLoading
                              ? Colors.teal.withOpacity(0.7)
                              : Colors.teal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'Tạo tài khoản',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Back to login
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Đã có tài khoản? Đăng nhập'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}