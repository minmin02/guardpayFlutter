// 1. 카테고리 목록 (GET /categories)
class QuizCategory {
  final int categoryId;
  final String name;

  QuizCategory({required this.categoryId, required this.name});

  factory QuizCategory.fromJson(Map<String, dynamic> json) {
    return QuizCategory(
      categoryId: json['categoryId'],
      name: json['name'],
    );
  }
}

// 2. 퀴즈 목록 (GET /{categoryId}/list)
class QuizSummary {
  final int quizId;
  final String question;
  final int level;
  final int point;

  QuizSummary({
    required this.quizId,
    required this.question,
    required this.level,
    required this.point,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) {
    return QuizSummary(
      quizId: json['quizId'],
      question: json['question'],
      level: json['level'],
      point: json['point'],
    );
  }
}

// 3. 퀴즈 상세 (GET /{quizId})
class QuizDetail {
  final int quizId;
  final String question;
  final List<QuizOption> options;
  final int point;

  QuizDetail({
    required this.quizId,
    required this.question,
    required this.options,
    required this.point,
  });

  factory QuizDetail.fromJson(Map<String, dynamic> json) {
    List<dynamic> optionsList = json['options'];
    List<QuizOption> parsedOptions = optionsList.map((opt) => QuizOption.fromJson(opt)).toList();

    return QuizDetail(
      quizId: json['quizId'],
      question: json['question'],
      options: parsedOptions,
      point: json['point'],
    );
  }
}

// 3a. 퀴즈 옵션 (QuizDetail에 포함됨)
class QuizOption {
  final int optionId;
  final String optionText;

  QuizOption({required this.optionId, required this.optionText});

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      optionId: json['optionId'],
      optionText: json['optionText'],
    );
  }
}

// 4. 정답 제출 결과 (POST /{quizId}/submit)
class SubmitResult {
  final bool isCorrect;
  final int gainExp;

  SubmitResult({required this.isCorrect, required this.gainExp});

  factory SubmitResult.fromJson(Map<String, dynamic> json) {
    return SubmitResult(
      isCorrect: json['isCorrect'],
      gainExp: json['gainExp'],
    );
  }
}

// 5. 진행률 (GET /progress)
class QuizProgress {
  final int categoryId;
  final String categoryName;
  final double progress;

  QuizProgress({
    required this.categoryId,
    required this.categoryName,
    required this.progress,
  });

  factory QuizProgress.fromJson(Map<String, dynamic> json) {
    return QuizProgress(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      progress: (json['progress'] as num).toDouble(),
    );
  }
}