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



// [quiz_model.dart] 파일 내의 Quiz 클래스 수정
  factory Quiz.fromJson(Map<String, dynamic> json) {
    // 1. API 응답의 options는 List<dynamic> (옵션 객체들의 배열)입니다.
    final List<dynamic> rawOptions = json['options'] ?? [];
    final Map<String, String> parsedOptions = {};

    // 2. List를 순회하며 Map<String, String> 형태로 변환
    // 옵션 ID(int)를 키(String)로, 텍스트(String)를 값으로 사용합니다.
    for (var option in rawOptions) {
      if (option is Map<String, dynamic>) {
        // 키로 사용할 옵션 ID를 문자열로 변환합니다. (예: 4001 -> "4001")
        final String key = (option['optionId'] as int?)?.toString() ?? 'unknown';
        final String text = option['text'] as String? ?? 'No Text';

        // 키가 'unknown'이 아니면서 텍스트가 있을 경우에만 추가합니다.
        if (key != 'unknown') {
          parsedOptions[key] = text;
        }
      }
    }

    return Quiz(
      id: json['questionId'] as int? ?? 0,
      question: json['questionText'] as String? ?? 'No Question',
      options: parsedOptions, // 👈 수정된 Map 사용
      // ⬇ 새 API 명세에 없는 필드들은 기본값으로 채웁니다.
      answer: '',
      categoryId: 0,
      level: 'UNKNOWN',
      point: 0,
    );
  }


} 