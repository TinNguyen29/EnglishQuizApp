import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final Map<int, int> userAnswers;
  final int score;
  final int totalTime;
  final String? level; // Thêm level để xác định màu

  const ReviewScreen({
    Key? key,
    required this.questions,
    required this.userAnswers,
    required this.score,
    required this.totalTime,
    this.level,
  }) : super(key: key);

  Color _getScoreColor() {
    final percentage = (score / questions.length) * 100;
    if (percentage >= 80) return Colors.greenAccent.shade700;
    if (percentage >= 60) return Colors.orange.shade700;
    return Colors.redAccent;
  }

  String _getScoreMessage() {
    final percentage = (score / questions.length) * 100;
    if (percentage >= 80) return 'Xuất sắc!';
    if (percentage >= 60) return 'Khá tốt!';
    return 'Cần cố gắng thêm!';
  }

  IconData _getScoreIcon() {
    final percentage = (score / questions.length) * 100;
    if (percentage >= 80) return Icons.star;
    if (percentage >= 60) return Icons.thumb_up;
    return Icons.refresh;
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor();
    final percentage = ((score / questions.length) * 100).round();

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
                      Text(
                        'Kết quả làm bài',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getScoreMessage(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.black54),
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Thống kê tổng quan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: scoreColor.withOpacity(0.1),
                      radius: 40,
                      child: Icon(
                        _getScoreIcon(),
                        color: scoreColor,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$score/${questions.length}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      '$percentage% chính xác',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Progress bar
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: score / questions.length,
                        child: Container(
                          decoration: BoxDecoration(
                            color: scoreColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Thống kê chi tiết
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Câu đúng',
                      value: '$score',
                      icon: Icons.check_circle,
                      color: Colors.greenAccent.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Câu sai',
                      value: '${questions.length - score}',
                      icon: Icons.cancel,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Thời gian',
                      value: _formatTime(totalTime),
                      icon: Icons.timer,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Tổng câu',
                      value: '${questions.length}',
                      icon: Icons.quiz,
                      color: Colors.purple.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Chi tiết câu hỏi
              const Text(
                'Chi tiết từng câu hỏi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Danh sách câu hỏi
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final text = q['questionText'] ?? q['content'];
                  final imageUrl = q['image_url'] ?? '';
                  final options = List<String>.from(q['options']);
                  final correct = q['correctAnswer'] ?? q['correct_answer'];
                  final selected = userAnswers[index]!;
                  final isCorrect = selected == correct;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.greenAccent.shade700.withOpacity(0.3)
                            : Colors.redAccent.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isCorrect
                              ? Colors.greenAccent.shade700
                              : Colors.redAccent).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header câu hỏi
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isCorrect
                                  ? Colors.greenAccent.shade700.withOpacity(0.1)
                                  : Colors.redAccent.withOpacity(0.1),
                              radius: 16,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isCorrect
                                      ? Colors.greenAccent.shade700
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Câu ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? Colors.greenAccent.shade700.withOpacity(0.1)
                                    : Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isCorrect ? Icons.check : Icons.close,
                                    color: isCorrect
                                        ? Colors.greenAccent.shade700
                                        : Colors.redAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isCorrect ? 'Đúng' : 'Sai',
                                    style: TextStyle(
                                      color: isCorrect
                                          ? Colors.greenAccent.shade700
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Nội dung câu hỏi
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),

                        // Hình ảnh nếu có
                        if (imageUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Các lựa chọn
                        ...options.asMap().entries.map((e) {
                          final i = e.key;
                          final optText = e.value;

                          Color bgColor = Colors.grey.shade50;
                          Color borderColor = Colors.grey.shade300;
                          Color textColor = Colors.black87;
                          IconData iconData = Icons.radio_button_unchecked;
                          Color iconColor = Colors.grey.shade400;

                          if (i == correct) {
                            // Đáp án đúng
                            bgColor = Colors.greenAccent.shade700.withOpacity(0.1);
                            borderColor = Colors.greenAccent.shade700;
                            iconData = Icons.check_circle;
                            iconColor = Colors.greenAccent.shade700;
                            textColor = Colors.greenAccent.shade700;
                          } else if (i == selected) {
                            // Đáp án người dùng chọn (sai)
                            bgColor = Colors.redAccent.withOpacity(0.1);
                            borderColor = Colors.redAccent;
                            iconData = Icons.cancel;
                            iconColor = Colors.redAccent;
                            textColor = Colors.redAccent;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Icon(iconData, color: iconColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    optText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor,
                                      fontWeight: (i == correct || i == selected)
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (i == correct)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.shade700,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Đúng',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Nút hành động
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
                          Icon(Icons.home, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Về trang chủ",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scoreColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Làm lại",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}