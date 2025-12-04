import 'package:flutter/material.dart';

class TransferSuccessScreen extends StatelessWidget {
  // [추가] 완료된 계좌 ID를 받기 위한 변수 (화면에는 안 보임, 뒤로가기용)
  final int? completedBeneficiaryId;

  const TransferSuccessScreen({
    super.key,
    this.completedBeneficiaryId, // 생성자 추가
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5E8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF49A65E),
                      size: 100,
                    ),
                    SizedBox(height: 30),
                    Text(
                      "송금이 완료되었습니다!",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "100p가 지급됩니다.",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              // [수정] 버튼 영역 (Expanded 밖으로 빼서 하단에 고정)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // [핵심 수정] 버튼을 누르면 '완료된 ID'를 가지고 이전 화면으로 돌아감
                    Navigator.pop(context, completedBeneficiaryId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF49A65E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "확인",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // 버튼 아래 약간의 여백
            ],
          ),
        ),
      ),
    );
  }
}