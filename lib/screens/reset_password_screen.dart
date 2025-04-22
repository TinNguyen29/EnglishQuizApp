import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController newPassCtrl = TextEditingController();
  final TextEditingController confirmPassCtrl = TextEditingController();

  String message = "";
  bool isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  void resetPassword() async {
    final email = emailCtrl.text.trim();
    final newPassword = newPassCtrl.text;
    final confirmPassword = confirmPassCtrl.text;

    if (email.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        message = "Vui lòng nhập đầy đủ thông tin.";
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        message = "Mật khẩu xác nhận không khớp.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = "";
    });

    final res = await AuthService.resetPassword(email, newPassword);

    setState(() {
      isLoading = false;
      message = res['message'] ?? 'Yêu cầu không thành công.';
    });

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đặt lại mật khẩu thành công")),
      );
      Navigator.pop(context);
    }
  }

  Widget buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: toggleVisibility,
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
              const Icon(Icons.lock_reset, size: 72, color: Colors.teal),
              const SizedBox(height: 12),
              const Text(
                "Đặt lại mật khẩu",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 32),

              buildInput(
                controller: emailCtrl,
                hint: 'Email',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),

              buildInput(
                controller: newPassCtrl,
                hint: 'Mật khẩu mới',
                icon: Icons.lock_outline,
                isPassword: true,
                obscure: _obscureNew,
                toggleVisibility: () {
                  setState(() {
                    _obscureNew = !_obscureNew;
                  });
                },
              ),
              const SizedBox(height: 16),

              buildInput(
                controller: confirmPassCtrl,
                hint: 'Xác nhận mật khẩu',
                icon: Icons.lock_outline,
                isPassword: true,
                obscure: _obscureConfirm,
                toggleVisibility: () {
                  setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  });
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Đặt lại mật khẩu",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (message.isNotEmpty)
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              const SizedBox(height: 24),

              // Nút quay lại trang đăng nhập
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Quay lại đăng nhập",
                  style: TextStyle(color: Colors.teal, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
