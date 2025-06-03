class UserRanking {
  final String id;
  final String username;
  final String email;
  final int maxScore;
  final int bestDuration;

  UserRanking({
    required this.id,
    required this.username,
    required this.email,
    required this.maxScore,
    required this.bestDuration,
  });

  factory UserRanking.fromJson(Map<String, dynamic> json) {
    return UserRanking(
      id: json['_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      // Sử dụng toán tử ?? để gán giá trị mặc định 0 nếu backend vẫn trả về null
      // (Mặc dù chúng ta đã thêm $ifNull ở backend, đây là một lớp bảo vệ an toàn)
      maxScore: (json['maxScore'] as int?) ?? 0,
      bestDuration: (json['bestDuration'] as int?) ?? 0,
    );
  }
}
