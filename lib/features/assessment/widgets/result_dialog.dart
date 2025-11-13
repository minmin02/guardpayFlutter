import 'package:flutter/material.dart';

// 레벨 정보 구조체 (변경 없음)
class LevelData {
  final String title;
  final List<bool> stars; // [첫번째 별 채움 여부, 두번째 별 채움 여부, 세번째 별 채움 여부]
  final Color titleColor;

  LevelData({
    required this.title,
    required this.stars,
    required this.titleColor,
  });
}

class ResultDialog extends StatelessWidget {
  final String level; // High, Middle, Low 중 하나
  final VoidCallback onConfirm;

  const ResultDialog({
    super.key,
    required this.level,
    required this.onConfirm,
  });

  // 레벨에 따른 데이터 반환 (변경 없음)
  LevelData _getLevelData() {
    switch (level) {
      case '안전 송금 마스터':
        return LevelData(
          title: '안전 송금 마스터',
          stars: [true, true, true],
          titleColor: Colors.black,
        );
      case '금융 방패단':
        return LevelData(
          title: '금융 방패단',
          stars: [true, false, true],
          titleColor: Colors.black,
        );
      case '초보 금융가':
        return LevelData(
          title: '초보 금융가',
          stars: [false, false, true],
          titleColor: Colors.black,
        );
      default:
        return LevelData(
          title: '주의 필요',
          stars: [false, false, false],
          titleColor: Colors.grey,
        );
    }
  }

  // 별 아이콘 빌드 메서드 (변경 없음)
  Widget _buildStar(bool isFilled, double size) {
    return Icon(
      isFilled ? Icons.star : Icons.star_border,
      color: isFilled ? Colors.amber : Colors.grey.shade400,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _getLevelData();

    return AlertDialog(
      // AlertDialog 자체의 모양과 그림자(Elevation)를 조정하여 겹침 문제 완화
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // 둥근 모양을 더 크게
      elevation: 0,
      contentPadding: EdgeInsets.zero,

      content: Container( // ✅ content 속성의 값 시작
        width: MediaQuery.of(context).size.width * 0.73,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          height: 220.0, // ✅ 팝업 내용의 고정된 높이 (이 값을 변경해야 팝업 높이 고정)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 별 아이콘 영역
              const SizedBox(height: 20), // ✅ 상단 여백 (이 값을 조절하여 별 위치 조정)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 첫 번째 별
                  _buildStar(data.stars[0], 55),

                  const SizedBox(width: 8),

                  // 두 번째 별 (가운데)
                  _buildStar(data.stars[1], 65),

                  const SizedBox(width: 8),

                  // 세 번째 별
                  _buildStar(data.stars[2], 45),
                ],
              ),

              const SizedBox(height: 15), // ✅ 별과 텍스트 사이 여백 (이 값을 조절하여 위치 조정)

              // 2. 레벨 텍스트
              Text(
                data.title,
                textAlign: TextAlign.center, // 중앙 정렬 추가
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: data.titleColor,
                ),
              ),

              const Spacer(), // ✅ 남은 공간을 밀어내어 버튼을 하단에 고정

              // 4. 메인으로 버튼 영역 (GestureDetector로 감싸고, 내부 Container 제거)
              GestureDetector(
                onTap: onConfirm,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100, // 버튼 영역 배경색
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '메인으로',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ), // ✅ content 속성의 값 종료
    ); // ✅ AlertDialog 위젯 종료
  }
}