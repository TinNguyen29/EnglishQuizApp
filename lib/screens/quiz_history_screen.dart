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
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchQuizHistory();
  }

  Future<void> fetchQuizHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final data = await QuizService.getUserTests(widget.email);
      setState(() {
        quizHistory = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Không thể tải lịch sử quiz. Vui lòng thử lại sau.";
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

  Color _getLevelColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'easy':
        return Colors.greenAccent.shade700;
      case 'normal':
        return Colors.orange.shade700;
      case 'hard':
        return Colors.redAccent;
      default:
        return Colors.purple.shade600;
    }
  }

  IconData _getLevelIcon(String? level) {
    switch (level?.toLowerCase()) {
      case 'easy':
        return Icons.lightbulb_outline;
      case 'normal':
        return Icons.auto_graph;
      case 'hard':
        return Icons.local_fire_department;
      default:
        return Icons.quiz_outlined;
    }
  }

  String _getLevelName(String? level) {
    switch (level?.toLowerCase()) {
      case 'easy':
        return 'Dễ';
      case 'normal':
        return 'Trung bình';
      case 'hard':
        return 'Khó';
      default:
        return level ?? 'Không xác định';
    }
  }

  Color _getScoreColor(int score, int totalQuestions) {
    double percentage = score / totalQuestions;
    if (percentage >= 0.8) return Colors.green.shade600;
    if (percentage >= 0.6) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  Widget _buildQuizHistoryCard(Map<String, dynamic> quiz, int index) {
    final date = DateTime.parse(quiz['createdAt']);
    final formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final formattedTime = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final level = quiz['level']?.toString();
    final score = quiz['score'] ?? 0;
    final totalQuestions = (quiz['questions'] as List?)?.length ?? 10;
    final duration = quiz['duration'] ?? 0;

    final levelColor = _getLevelColor(level);
    final scoreColor = _getScoreColor(score, totalQuestions);

    return InkWell(
      onTap: () => viewQuizDetail(quiz),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Header với level và thời gian
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getLevelIcon(level),
                        size: 16,
                        color: levelColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getLevelName(level),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Thời gian làm bài
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Kết quả bài thi
            Row(
              children: [
                // Điểm số
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.star,
                          color: scoreColor,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$score/$totalQuestions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        const Text(
                          'Điểm',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Thời gian hoàn thành
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.timer,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${duration}s',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        const Text(
                          'Thời gian',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Tỷ lệ đúng
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.percent,
                          color: Colors.purple.shade600,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${((score / totalQuestions) * 100).round()}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade600,
                          ),
                        ),
                        const Text(
                          'Chính xác',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Nút xem chi tiết
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Xem chi tiết',
                  style: TextStyle(
                    fontSize: 14,
                    color: levelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: levelColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lịch sử làm bài',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (quizHistory.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.purple.shade600),
              onPressed: fetchQuizHistory,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Đang tải lịch sử...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        )
            : errorMessage.isNotEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchQuizHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        )
            : quizHistory.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Bạn chưa làm bài quiz nào',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy bắt đầu làm bài quiz đầu tiên của bạn!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Về trang chủ'),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: fetchQuizHistory,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header thống kê
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Colors.purple.shade600,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng số bài đã làm',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '${quizHistory.length} bài quiz',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Danh sách lịch sử
              Expanded(
                child: ListView.builder(
                  itemCount: quizHistory.length,
                  itemBuilder: (context, index) {
                    final quiz = quizHistory[index];
                    return _buildQuizHistoryCard(quiz, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}