import 'dart:async';
import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../services/score_service.dart';

class QuizScreen extends StatefulWidget {
  final String level;
  final int timeLimitSeconds;

  const QuizScreen({
    super.key,
    required this.level,
    required this.timeLimitSeconds,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Future<List<Map<String, dynamic>>> _questionsFuture;
  List<Map<String, dynamic>> questions = [];
  Map<int, int> userAnswers = {};
  Timer? timer;
  int remainingSeconds = 0;
  int currentIndex = 0;
  String? email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      email = args;
    } else if (args is Map && args.containsKey('email')) {
      email = args['email'];
    }

    remainingSeconds = widget.timeLimitSeconds;
    _questionsFuture = QuizService.fetchQuestions(widget.level);
    _startTimer();
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        timer?.cancel();
        _submitQuiz(auto: true);
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Future<void> _submitQuiz({bool auto = false}) async {
    timer?.cancel();
    int score = 0;
    List<Map<String, dynamic>> answerDetails = [];

    for (int i = 0; i < questions.length; i++) {
      int? selectedIndex = userAnswers[i];
      int correctIndex = questions[i]['correctAnswer'];
      bool isCorrect = selectedIndex == correctIndex;

      if (isCorrect) score++;

      answerDetails.add({
        "questionId": questions[i]['_id'],
        "questionText": questions[i]['questionText'],
        "selectedIndex": selectedIndex,
        "correctIndex": correctIndex,
        "selectedAnswer": selectedIndex != null ? questions[i]['options'][selectedIndex] : null,
        "correctAnswer": questions[i]['options'][correctIndex],
        "isCorrect": isCorrect,
      });
    }

    final totalPoints = score * 1;

    if (email != null) {
      try {
        await ScoreService.saveScore(
          email: email!,
          score: totalPoints,
          level: widget.level,
        );
        await ScoreService.saveQuizDetails(
          email: email!,
          level: widget.level,
          score: totalPoints,
          totalQuestions: questions.length,
          answers: answerDetails,
        );
      } catch (e) {
        print("❌ Lỗi khi lưu dữ liệu quiz: $e");
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("🎉 Kết quả bài làm"),
        content: Text(
          "✅ Số câu đúng: $score/${questions.length}\n"
              "✅ Mỗi câu đúng: 1 điểm\n"
              "⭐ Tổng điểm: $totalPoints điểm${auto ? "\n⏱ Hết thời gian!" : ""}",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text("Trình độ: ${widget.level.toUpperCase()}"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Chip(
              label: Text(
                _formatTime(remainingSeconds),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              labelStyle: const TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Không có câu hỏi nào."));
          }

          questions = snapshot.data!;
          final question = questions[currentIndex];
          final options = List<String>.from(question['options'] ?? []);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Câu ${currentIndex + 1}/${questions.length}: ${question['questionText']}",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final text = entry.value;
                  final isSelected = userAnswers[currentIndex] == index;

                  return Card(
                    color: isSelected ? Colors.deepPurple.shade100 : Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: RadioListTile<int>(
                      value: index,
                      groupValue: userAnswers[currentIndex],
                      onChanged: (value) {
                        setState(() {
                          userAnswers[currentIndex] = value!;
                        });
                      },
                      title: Text(text),
                      activeColor: Colors.deepPurple,
                    ),
                  );
                }).toList(),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: currentIndex > 0 ? () => setState(() => currentIndex--) : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Quay lại"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade400,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: userAnswers[currentIndex] != null
                          ? () {
                        if (currentIndex < questions.length - 1) {
                          setState(() => currentIndex++);
                        } else {
                          _submitQuiz();
                        }
                      }
                          : null,
                      icon: Icon(currentIndex < questions.length - 1
                          ? Icons.arrow_forward
                          : Icons.check),
                      label: Text(currentIndex < questions.length - 1 ? "Tiếp theo" : "Nộp bài"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
