import 'dart:async';
import 'package:flutter/material.dart';
import 'package:retry/retry.dart';
import 'package:uuid/uuid.dart';
import '../services/auth_service.dart';
import '../services/quiz_service.dart';
import '../services/score_service.dart';
import 'review_screen.dart';

class QuizScreen extends StatefulWidget {
  final String level;
  final int timeLimitSeconds;

  const QuizScreen({
    Key? key,
    required this.level,
    required this.timeLimitSeconds,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> questions = [];
  Map<int, int> userAnswers = {};
  Timer? timer;
  int remainingSeconds = 0;
  int currentIndex = 0;
  bool isSubmitting = false;

  String? email;
  String? userId;

  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    email = await AuthService.getEmail();
    userId = await AuthService.getUserId();

    if (email == null || userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thể xác thực người dùng. Vui lòng đăng nhập lại.")),
        );
        Navigator.pop(context);
      }
      return;
    }

    try {
      final fetchedQuestions = await QuizService.fetchQuestions(widget.level);
      for (var q in fetchedQuestions) {
        if (q['_id'] == null || q['options'] == null || (q['questionText'] ?? q['content']) == null) {
          throw Exception("Dữ liệu câu hỏi không hợp lệ.");
        }
      }
      questions = fetchedQuestions;
      remainingSeconds = widget.timeLimitSeconds;
      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tải câu hỏi: $e")));
        Navigator.pop(context);
      }
    }
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        timer.cancel();
        _submitQuiz(auto: true);
      }
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _submitQuiz({bool auto = false}) async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);
    timer?.cancel();

    if (userAnswers.length < questions.length) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bạn cần trả lời tất cả câu hỏi.")),
        );
      }
      setState(() => isSubmitting = false);
      return;
    }

    int score = 0;
    List<Map<String, dynamic>> answerDetails = [];

    for (int i = 0; i < questions.length; i++) {
      final selected = userAnswers[i];
      final correct = questions[i]['correctAnswer'] ?? questions[i]['correct_answer'];
      final isCorrect = selected == correct;
      if (isCorrect) score++;

      answerDetails.add({
        "questionId": questions[i]['_id'],
        "selectedAnswer": selected != null ? questions[i]['options'][selected] : null,
        "timeTaken": 0,
        "isCorrect": isCorrect,
      });
    }

    final totalPoints = score;
    final quizId = const Uuid().v4();
    final totalTime = widget.timeLimitSeconds - remainingSeconds;

    try {
      await retry(
            () => ScoreService.saveScore(
          userId: userId!,
          score: totalPoints,
          mode: widget.level.toLowerCase(),
          duration: totalTime,
        ),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );

      await retry(
            () => ScoreService.saveQuizDetails(
          userId: userId!,
          quizId: quizId,
          level: widget.level,
          answers: answerDetails,
        ),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewScreen(
              questions: questions,
              userAnswers: userAnswers,
              score: score,
              totalTime: totalTime,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi nộp bài: $e")));
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (questions.isEmpty) {
          return const Scaffold(body: Center(child: Text("Không có câu hỏi.")));
        }

        final q = questions[currentIndex];
        final questionText = q['questionText'] ?? q['content'];
        final imageUrl = q['image_url'] ?? '';
        final options = List<String>.from(q['options']);

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
                  label: Text(_formatTime(remainingSeconds), style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white,
                  labelStyle: const TextStyle(color: Colors.deepPurple),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(questions.length, (index) {
                      final isAnswered = userAnswers.containsKey(index);
                      final isCurrent = index == currentIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => currentIndex = index),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: isCurrent ? Colors.orange : isAnswered ? Colors.green : Colors.grey,
                            child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Câu ${currentIndex + 1}/${questions.length}: $questionText",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        if (imageUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Image.network(imageUrl, height: 150, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...options.asMap().entries.map((entry) {
                  final i = entry.key;
                  final text = entry.value;
                  final isSelected = userAnswers[currentIndex] == i;
                  return Card(
                    color: isSelected ? Colors.deepPurple.shade100 : Colors.white,
                    child: ListTile(
                      title: Text(text),
                      onTap: () => setState(() => userAnswers[currentIndex] = i),
                    ),
                  );
                }),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSubmitting || currentIndex == 0 ? null : () => setState(() => currentIndex--),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, minimumSize: const Size(double.infinity, 50)),
                        child: const Text("Quay lại"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () {
                          if (currentIndex < questions.length - 1) {
                            setState(() => currentIndex++);
                          } else {
                            _submitQuiz();
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, minimumSize: const Size(double.infinity, 50)),
                        child: Text(currentIndex < questions.length - 1 ? "Tiếp theo" : "Nộp bài"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
