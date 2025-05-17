import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import 'ranking_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final String email;
  final String username;

  const HomeScreen({
    super.key,
    required this.email,
    required this.username,
  });

  void logout(BuildContext context) async {
    await AuthService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void startQuiz(BuildContext context, String level, int timeLimitSeconds) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          level: level,
          timeLimitSeconds: timeLimitSeconds,
        ),
        settings: RouteSettings(arguments: email), // Truyền email qua settings
      ),
    );
  }

  void viewRankings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RankingScreen(
          email: email,
          username: username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Xin chào,',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 13, color: Colors.black45),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () => logout(context),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Text(
                'Bắt đầu kiểm tra kiến thức!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Quizzes
              _buildQuizCard(
                context,
                title: 'Trình độ Dễ',
                description: 'Các câu hỏi cơ bản để khởi động.',
                icon: Icons.lightbulb_outline,
                color: Colors.greenAccent.shade700,
                level: 'easy',
                timeLimitSeconds: 120,
              ),
              const SizedBox(height: 16),
              _buildQuizCard(
                context,
                title: 'Trình độ Trung bình',
                description: 'Thử sức với độ khó vừa phải.',
                icon: Icons.auto_graph,
                color: Colors.orange.shade700,
                level: 'normal',
                timeLimitSeconds: 180,
              ),
              const SizedBox(height: 16),
              _buildQuizCard(
                context,
                title: 'Trình độ Khó',
                description: 'Thử thách dành cho các cao thủ!',
                icon: Icons.local_fire_department,
                color: Colors.redAccent,
                level: 'hard',
                timeLimitSeconds: 240,
              ),

              const SizedBox(height: 32),
              const Text(
                'Xếp hạng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => viewRankings(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.leaderboard, size: 28, color: Colors.blue),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Xem bảng xếp hạng người chơi',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard(
      BuildContext context, {
        required String title,
        required String description,
        required IconData icon,
        required Color color,
        required String level,
        required int timeLimitSeconds,
      }) {
    return InkWell(
      onTap: () => startQuiz(context, level, timeLimitSeconds),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 28,
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      )),
                  const SizedBox(height: 4),
                  Text(description,
                      style: const TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}
