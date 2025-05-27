import 'dart:async';
import 'package:flutter/material.dart';
import 'package:retry/retry.dart';
import 'package:uuid/uuid.dart'; // Thêm package uuid
import '../services/quiz_service.dart';
import '../services/score_service.dart';
import '../services/auth_service.dart';

class QuizScreen extends StatefulWidget {
  final String level;
  final int timeLimitSeconds;

  const QuizScreen({
    Key? key,
    required this.level,
    required this.timeLimitSeconds,
  }) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Future<List<Map<String, dynamic>>> _questionsFuture;
  List<Map<String, dynamic>> questions = [];
  Map<int, int> userAnswers = {};
  Timer? timer;
  int remainingSeconds = 0;
  int currentIndex = 0;
  String? email;
  String? userId;
  bool isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Lấy email và userId từ AuthService
    AuthService.getEmail().then((emailValue) {
      AuthService.getUserId().then((userIdValue) {
        setState(() {
          email = emailValue;
          userId = userIdValue;
        });
      });
    });

    remainingSeconds = widget.timeLimitSeconds;
    _questionsFuture = _fetchQuestionsWithValidation();
    _startTimer();
  }

  Future<List<Map<String, dynamic>>> _fetchQuestionsWithValidation() async {
    final questions = await QuizService.fetchQuestions(widget.level);
    for (var q in questions) {
      if (q['_id'] == null || q['questionText'] == null || q['options'] == null || q['correctAnswer'] == null) {
        throw Exception('Định dạng câu hỏi không hợp lệ: $q');
      }
    }
    return questions;
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
    if (isSubmitting) return;

    setState(() {
      isSubmitting = true;
    });

    timer?.cancel();

    // ✅ Kiểm tra người dùng đã trả lời hết chưa
    if (userAnswers.length < questions.length) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng trả lời tất cả các câu hỏi trước khi nộp.')),
        );
      }
      setState(() => isSubmitting = false);
      return;
    }

    int score = 0;
    List<Map<String, dynamic>> answerDetails = [];

    // ✅ Tính điểm và tạo answerDetails
    for (int i = 0; i < questions.length; i++) {
      int? selectedIndex = userAnswers[i];
      int correctIndex = questions[i]['correctAnswer'];
      bool isCorrect = selectedIndex == correctIndex;

      if (isCorrect) score++;

      if (selectedIndex != null) {
        answerDetails.add({
          "questionId": questions[i]['_id'],
          "selectedAnswer": questions[i]['options'][selectedIndex],
          "timeTaken": 0,
          "isCorrect": isCorrect,
        });
      }
    }

    final totalPoints = score * 1;

    // ✅ In log để kiểm tra answerDetails
    print('📝 DANH SÁCH TRẢ LỜI GỬI LÊN SERVER:');
    for (var a in answerDetails) {
      print('📌 QuestionId: ${a['questionId']} | Answer: ${a['selectedAnswer']} | Đúng?: ${a['isCorrect']}');
    }

    // ✅ Kiểm tra thông tin người dùng
    if (userId == null || userId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng đăng nhập để gửi bài làm.')),
        );
      }
      setState(() {
        isSubmitting = false;
      });
      return;
    }

    if (!['easy', 'normal', 'hard'].contains(widget.level.toLowerCase())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mức độ không hợp lệ: ${widget.level}')),
        );
      }
      setState(() {
        isSubmitting = false;
      });
      return;
    }

    if (answerDetails.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chưa có câu trả lời nào được chọn.')),
        );
      }
      setState(() {
        isSubmitting = false;
      });
      return;
    }

    // ✅ Tạo quizId
    final quizId = Uuid().v4();

    try {
      // ✅ Gửi điểm
      if (email != null) {
        await retry(
              () => ScoreService.saveScore(
            email: email!,
            score: totalPoints,
            level: widget.level,
            mode: widget.level.toLowerCase(),
          ),
          maxAttempts: 3,
          delayFactor: Duration(seconds: 1),
          onRetry: (e) => print('Thử lại lưu điểm: $e'),
        );
      }

      // ✅ Gửi chi tiết quiz
      await retry(
            () => ScoreService.saveQuizDetails(
          userId: userId!,
          quizId: quizId,
          level: widget.level,
          answers: answerDetails,
        ),
        maxAttempts: 3,
        delayFactor: Duration(seconds: 1),
        onRetry: (e) => print('Thử lại lưu chi tiết quiz: $e'),
      );

      // ✅ Hiển thị kết quả
      if (mounted) {
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
    } catch (e) {
      print("❌ Lỗi khi lưu dữ liệu quiz: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu bài làm: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
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
                // ✅ Thanh trạng thái câu hỏi
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(questions.length, (index) {
                      final isAnswered = userAnswers.containsKey(index);
                      final isCurrent = index == currentIndex;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              currentIndex = index;
                            });
                          },
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: isCurrent
                                ? Colors.orange
                                : isAnswered
                                ? Colors.green
                                : Colors.grey,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Câu hỏi
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

                // ✅ Các lựa chọn
                ...options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final text = entry.value;
                  final isSelected = userAnswers[currentIndex] == index;

                  return Card(
                    color: isSelected ? Colors.deepPurple.shade100 : Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(text),
                      onTap: () {
                        setState(() {
                          userAnswers[currentIndex] = index;
                        });
                      },
                    ),
                  );
                }).toList(),

                const Spacer(),

                // ✅ Nút Quay lại & Tiếp theo/Nộp bài
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSubmitting || currentIndex == 0 ? null : () {
                          setState(() {
                            currentIndex--;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text("Quay lại"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : () {
                          if (currentIndex < questions.length - 1) {
                            setState(() {
                              currentIndex++;
                            });
                          } else {
                            _submitQuiz();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(currentIndex < questions.length - 1 ? "Tiếp theo" : "Nộp bài"),
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
