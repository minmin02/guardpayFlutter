class Quiz {
  final int id;
  final String question;
  final Map<String, String> options;
  final String answer; // 정답 키 (예: 'B')
  final int categoryId;
  final String level; // 난이도 (예: 'EASY', 'MEDIUM', 'HARD')
  final int point;
  final String? userSelectedAnswer;

  Quiz({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    required this.categoryId,
    required this.level,
    required this.point,
    this.userSelectedAnswer,
  });

  Quiz copyWith({
    String? userSelectedAnswer,
  }) {
    return Quiz(
      id: this.id,
      question: this.question,
      options: this.options,
      answer: this.answer,
      categoryId: this.categoryId,
      level: this.level,
      point: this.point,
      userSelectedAnswer: userSelectedAnswer ?? this.userSelectedAnswer,
    );
  }



  factory Quiz.fromJson(Map<String, dynamic> json) {
    // API의 options는 Map<String, dynamic>이지만, 값은 String입니다.
    final Map<String, dynamic> rawOptions = json['options'] ?? {};
    final Map<String, String> parsedOptions = rawOptions.map(
          (key, value) => MapEntry(key, value as String),
    );

    return Quiz(
      id: json['questionId'] as int? ?? 0,
      question: json['questionText'] as String? ?? 'No Question',
      options: parsedOptions,
      // ⬇ 새 API 명세에 없는 필드들은 기본값으로 채웁니다.
      answer: '',
      categoryId: 0,
      level: 'UNKNOWN',
      point: 0,
    );
  }
} 