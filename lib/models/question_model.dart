class Question {
  final String id;
  final String content;
  final List<String> options;
  final int correctAnswer;
  final String level;

  Question({
    required this.id,
    required this.content,
    required this.options,
    required this.correctAnswer,
    required this.level,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] ?? '',
      content: json['content'] ?? json['questionText'] ?? '', // <-- hỗ trợ cả 2 tên
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
      level: json['level'] ?? 'easy',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'options': options,
      'correctAnswer': correctAnswer,
      'level': level,
    };
  }
}
