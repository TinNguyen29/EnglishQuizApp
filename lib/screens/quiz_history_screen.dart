import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import 'review_screen.dart';
import 'quiz_screen.dart'; // Import QuizScreen for redo functionality

class QuizHistoryScreen extends StatefulWidget {
  final String email;

  const QuizHistoryScreen({super.key, required this.email});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _allQuizHistory = []; // Store all fetched history
  List<Map<String, dynamic>> _filteredQuizHistory = []; // Store filtered history for display
  bool isLoading = true;
  String errorMessage = "";

  late TabController _tabController;
  final List<String> modes = ['all', 'easy', 'normal', 'hard']; // Added 'all' mode
  String selectedMode = 'all'; // Default to 'all' mode

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: modes.length, vsync: this);
    _loadQuizHistory(); // Load all history initially

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) { // Only react when tab selection is final
        String mode = modes[_tabController.index];
        setState(() {
          selectedMode = mode;
          _applyFilterAndSort(); // Apply filter and sort when mode changes
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      // Fetch all quizzes for the user
      final data = await QuizService.getUserTests(widget.email);
      setState(() {
        _allQuizHistory = data;
        _applyFilterAndSort(); // Apply filter and sort after fetching
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

  void _applyFilterAndSort() {
    List<Map<String, dynamic>> tempHistory = List.from(_allQuizHistory);

    // Filter by mode
    if (selectedMode != 'all') {
      tempHistory = tempHistory.where((quiz) =>
      (quiz['level']?.toLowerCase() == selectedMode)).toList();
    }

    // Sort by date (most recent first)
    tempHistory.sort((a, b) {
      final dateA = DateTime.parse(a['createdAt']);
      final dateB = DateTime.parse(b['createdAt']);
      return dateB.compareTo(dateA); // Descending order
    });
    for (var quiz in tempHistory) {
      print('📅 Quiz: ${quiz['createdAt']}');
    }
    _filteredQuizHistory = tempHistory;
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

  void _redoQuiz(String quizId, String level) {
    // Assuming QuizScreen can take quizId and level to load a specific quiz
    // Fix 1: Add required timeLimitSeconds parameter
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          quizId: quizId, // Pass quizId to load specific quiz
          level: level, // Pass level (mode)
          timeLimitSeconds: 600, // <-- Added a default value for timeLimitSeconds (10 minutes)
          // You might need to pass other parameters like category, etc., depending on your QuizScreen constructor
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
    if (totalQuestions == 0) return Colors.grey.shade600; // Avoid division by zero
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
    final quizId = quiz['_id']?.toString(); // Get quizId for redo button

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

            // Nút xem chi tiết và Làm lại bài quiz
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align items to ends
              children: [
                // Nút Làm lại bài quiz
                if (quizId != null && level != null) // Only show if quizId and level are available
                  ElevatedButton.icon(
                    onPressed: () => _redoQuiz(quizId, level),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Làm lại bài quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: levelColor.withOpacity(0.2),
                      foregroundColor: levelColor, // Fix 2: Changed to levelColor
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),

                // Nút xem chi tiết
                InkWell(
                  onTap: () => viewQuizDetail(quiz),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
          if (_allQuizHistory.isNotEmpty) // Refresh button for all history
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.purple.shade600),
              onPressed: _loadQuizHistory,
            ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar với thiết kế custom cho các mode
          Container(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: modes.map((mode) {
                  return Tab(
                    child: FittedBox( // ✅ xử lý tự co lại nếu tràn
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getLevelIcon(mode == 'all' ? 'easy' : mode),
                            size: 16,
                            color: selectedMode == mode ? _getLevelColor(mode) : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mode == 'all' ? 'Tất cả' : _getLevelName(mode),
                            overflow: TextOverflow.ellipsis, // ✅ tránh bị tràn chữ
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Nội dung
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      onPressed: _loadQuizHistory,
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
                  : _filteredQuizHistory.isEmpty // Use filtered history here
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
                onRefresh: _loadQuizHistory,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header thống kê (hiển thị tổng số bài đã làm trong _filteredQuizHistory)
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
                                  '${_filteredQuizHistory.length} bài quiz', // Use filtered history count
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
                        itemCount: _filteredQuizHistory.length,
                        itemBuilder: (context, index) {
                          final quiz = _filteredQuizHistory[index];
                          // Hiển thị mới nhất trước
                          final reversedIndex = _filteredQuizHistory.length - 1 - index;
                          final reversedQuiz = _filteredQuizHistory[reversedIndex];
                          return _buildQuizHistoryCard(reversedQuiz, reversedIndex);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
