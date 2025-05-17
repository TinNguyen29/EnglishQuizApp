import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart'; // Nếu có màn hình Home sau khi đăng nhập
import 'screens/admin_dashboard.dart'; // Nếu có màn hình Admin Dashboard

void main() {
  runApp(const EnglishQuizApp());
}

class EnglishQuizApp extends StatelessWidget {
  const EnglishQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.teal, // Thay đổi màu chính thành teal
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal, // Đặt màu cho AppBar
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // Màn hình bắt đầu là login
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ResetPasswordScreen(),
        '/home': (context) => const HomeScreen(email: '', username: '',),
        '/admin-dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}
