import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import 'review_screen.dart';

class QuizHistoryScreen extends StatefulWidget {
  final String email;

  const QuizHistoryScreen({super.key, required this.email});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  List<Map<String, dynamic>> quizHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQuizHistory();
  }

  Future<void> fetchQuizHistory() async {
    try {
      final data = await QuizService.getUserTests(widget.email);
      setState(() {
        quizHistory = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Lỗi khi tải lịch sử quiz: $e');
    }
  }

  void viewQuizDetail(Map<String, dynamic> quizData) {
    final questions = List<Map<String, dynamic>>.from(quizData['questions']);
    final answers = Map<String, dynamic>.from(quizData['answers']);

    // Convert keys from String to int for userAnswers
    final userAnswers = <int, int>{};
    answers.forEach((key, value) {
      userAnswers[int.parse(key)] = value as int;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          questions: questions,
          userAnswers: userAnswers,
          score: quizData['score'],
          totalTime: quizData['duration'],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử làm bài'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : quizHistory.isEmpty
          ? const Center(
        child: Text(
          'Bạn chưa làm bài quiz nào.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      )
          : ListView.builder(
        itemCount: quizHistory.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final quiz = quizHistory[index];
          final date = DateTime.parse(quiz['createdAt']);
          final formattedDate =
              '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

          return InkWell(
            onTap: () => viewQuizDetail(quiz),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày làm bài: $formattedDate',
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Điểm số: ${quiz['score']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Thời gian: ${quiz['duration']} giây',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
