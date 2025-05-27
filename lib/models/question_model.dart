class Question {
  final String id;
  final String content;
  final List<String> options;
  final int correctAnswer;
  final String level;
  final String? imageUrl;

  Question({
    required this.id,
    required this.content,
    required this.options,
    required this.correctAnswer,
    required this.level,
    this.imageUrl,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] ?? '',
      content: json['content'] ?? json['questionText'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correct_answer'] ?? 0,
      level: json['level'] ?? 'easy',
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'options': options,
      'correct_answer': correctAnswer,
      'level': level,
      'image_url': imageUrl,
    };
  }
}
