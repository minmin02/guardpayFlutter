class Quiz {
  final int id;
  final String question;
  final List<Option> options;
  final String answer; // 정답 키
  final int categoryId;
  final String level; // 난이도
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
    final List<dynamic> rawOptions = json['options'] ?? [];
    final List<Option> parsedOptions = rawOptions
        .map((optionJson) => Option.fromJson(optionJson as Map<String, dynamic>))
        .toList();

    return Quiz(
      id: json['questionId'] as int? ?? 0,
      question: json['questionText'] as String? ?? 'No Question',
      options: parsedOptions,
      answer: '',
      categoryId: 0,
      level: 'UNKNOWN',
      point: 0,
    );
  }
}

class Option {
  final int optionId;
  final String text;

  Option({required this.optionId, required this.text});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      optionId: json['optionId'] as int,
      text: json['text'] as String,
    );
  }
}