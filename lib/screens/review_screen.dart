import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final Map<int, int> userAnswers;
  final int score;
  final int totalTime;

  const ReviewScreen({
    Key? key,
    required this.questions,
    required this.userAnswers,
    required this.score,
    required this.totalTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Điểm: $score/${questions.length}'),
            Text('Thời gian: ${Duration(seconds: totalTime).inMinutes}:${(totalTime % 60).toString().padLeft(2, '0')}'),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final text = q['questionText'] ?? q['content'];
                  final options = List<String>.from(q['options']);
                  final correct = q['correctAnswer'] ?? q['correct_answer'];
                  final selected = userAnswers[index]!;
                  final isCorrect = selected == correct;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Câu ${index + 1}: $text'),
                          const SizedBox(height: 8),
                          ...options.asMap().entries.map((e) {
                            final i = e.key;
                            final optText = e.value;
                            Color color = Colors.white;
                            if (i == selected) color = isCorrect ? Colors.green.shade100 : Colors.red.shade100;
                            if (!isCorrect && i == correct) color = Colors.green.shade50;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: color,
                              child: ListTile(
                                title: Text(optText),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
