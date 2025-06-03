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
  final String? quizId; // Thêm tham số quizId vào đây, làm cho nó tùy chọn (nullable)

  const QuizScreen({
    Key? key,
    required this.level,
    required this.timeLimitSeconds,
    this.quizId, // Khai báo tham số quizId trong constructor
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
      List<Map<String, dynamic>> fetchedQuestions;
      if (widget.quizId != null) {
        fetchedQuestions = await QuizService.fetchQuestions(widget.level);
      } else {
        fetchedQuestions = await QuizService.fetchQuestions(widget.level);
      }


      for (var q in fetchedQuestions) {
        if (q['_id'] == null || q['options'] == null || (q['questionText'] ?? q['content']) == null) {
          throw Exception("Dữ liệu câu hỏi không hợp lệ.");
        }
      }
      questions = fetchedQuestions;
      remainingSeconds = widget.timeLimitSeconds; // Sử dụng timeLimitSeconds từ widget
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

  Color _getLevelColor() {
    switch (widget.level.toLowerCase()) {
      case 'easy':
        return Colors.greenAccent.shade700;
      case 'normal':
        return Colors.orange.shade700;
      case 'hard':
        return Colors.redAccent;
      default:
        return Colors.blue;
    }
  }

  String _getLevelTitle() {
    switch (widget.level.toLowerCase()) {
      case 'easy':
        return 'Trình độ Dễ';
      case 'normal':
        return 'Trình độ Trung bình';
      case 'hard':
        return 'Trình độ Khó';
      default:
        return widget.level.toUpperCase();
    }
  }

  Future<void> _submitQuiz({bool auto = false}) async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);
    timer?.cancel();

    if (!auto && userAnswers.length < questions.length) {
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

      final isCorrect = (selected != null && correct != null && selected == correct);
      if (isCorrect) score++;

      answerDetails.add({
        "questionId": questions[i]['_id'],
        "selectedAnswer": selected,
        "timeTaken": 0,
        "isCorrect": isCorrect, // đảm bảo luôn là true/false
      });
    }

    final totalPoints = score;
    final quizId = widget.quizId ?? const Uuid().v4();
    final totalTime = widget.timeLimitSeconds - remainingSeconds;

    try {
      // Lưu điểm số
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

      // Lưu chi tiết bài quiz
      await retry(
            () => ScoreService.saveQuizDetails(
          userId: userId!,
          quizId: quizId,
          level: widget.level,
          answers: answerDetails,
          score: totalPoints,
          duration: totalTime,
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
          return const Scaffold(
            backgroundColor: Color(0xFFF7F9FC),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (questions.isEmpty) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F9FC),
            body: Center(child: Text("Không có câu hỏi.")),
          );
        }

        final q = questions[currentIndex];
        final questionText = q['questionText'] ?? q['content'];
        final imageUrl = q['image_url'] ?? '';
        final options = List<String>.from(q['options']);
        final hasAnswered = userAnswers.containsKey(currentIndex);
        final levelColor = _getLevelColor();

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header với thông tin quiz
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getLevelTitle(),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: levelColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Câu ${currentIndex + 1}/${questions.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      // Timer và menu
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: levelColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: levelColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer, color: levelColor, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _formatTime(remainingSeconds),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: levelColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<int>(
                            icon: Icon(Icons.list, color: levelColor),
                            onSelected: (index) {
                              setState(() => currentIndex = index);
                            },
                            itemBuilder: (_) => List.generate(questions.length, (index) {
                              final isAnswered = userAnswers.containsKey(index);
                              return PopupMenuItem<int>(
                                value: index,
                                child: Row(
                                  children: [
                                    Icon(
                                      isAnswered ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: isAnswered ? Colors.green : Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Câu ${index + 1}'),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Progress bar
                  Container(
                    width: double.infinity,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (currentIndex + 1) / questions.length,
                      child: Container(
                        decoration: BoxDecoration(
                          color: levelColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Câu hỏi
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: levelColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: levelColor.withOpacity(0.15),
                              radius: 16,
                              child: Text(
                                '${currentIndex + 1}',
                                style: TextStyle(
                                  color: levelColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Câu hỏi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          questionText,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        if (imageUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Đáp án
                  const Text(
                    'Chọn đáp án:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...options.asMap().entries.map((entry) {
                    final i = entry.key;
                    final text = entry.value;
                    final isSelected = userAnswers.containsKey(currentIndex) && userAnswers[currentIndex] == i;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => setState(() => userAnswers[currentIndex] = i),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? levelColor.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? levelColor : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? levelColor.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? levelColor : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? levelColor : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isSelected ? levelColor : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // Nút điều hướng
                  Row(
                    children: [
                      if (currentIndex > 0)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : () => setState(() => currentIndex--),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.black87,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back_ios, size: 16),
                                SizedBox(width: 8),
                                Text("Quay lại", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      if (currentIndex > 0) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubmitting || !hasAnswered
                              ? null
                              : () {
                            if (currentIndex < questions.length - 1) {
                              setState(() => currentIndex++);
                            } else {
                              _submitQuiz();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: levelColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                currentIndex < questions.length - 1 ? "Tiếp theo" : "Nộp bài",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                currentIndex < questions.length - 1
                                    ? Icons.arrow_forward_ios
                                    : Icons.send,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
