import 'package:flutter/material.dart';

// AuthInputField를 임포트하여 재사용합니다.
import 'auth_input_field.dart';

// 이메일 입력, 인증 코드 요청, 인증 코드 입력, 확인 버튼을 묶어 관리하는 복합 위젯
class EmailAuthSection extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController codeController;
  final bool isCodeRequested;
  final bool isCodeVerified;
  final VoidCallback onCodeRequest;
  final VoidCallback onCodeVerify;

  const EmailAuthSection({
    super.key,
    required this.emailController,
    required this.codeController,
    required this.isCodeRequested,
    required this.isCodeVerified,
    required this.onCodeRequest,
    required this.onCodeVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. 이메일 입력 필드
        const Text('이메일 *', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: AuthInputField( // AuthInputField 재사용
                controller: emailController,
                hintText: '이메일',
                keyboardType: TextInputType.emailAddress,
                readOnly: isCodeRequested, // 코드가 요청되면 이메일 수정 불가
                enabled: !isCodeVerified, // 인증 완료되면 비활성화
                validator: (value) {
                  final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
                  if (value == null || value.isEmpty || !emailRegex.hasMatch(value)) {
                    return '올바른 이메일 주소를 입력해주세요.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            // 2. 인증 코드 요청 버튼
            SizedBox(
              height: 56, // 텍스트 필드와 높이 맞추기
              child: ElevatedButton(
                onPressed: isCodeRequested ? null : onCodeRequest, // 요청 후 비활성화
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCodeRequested
                      ? Colors.grey
                      : const Color(0xFF6AA84F).withOpacity(0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  '인증코드 받기',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),

        // 3. 인증 코드가 요청된 경우에만 코드 입력 필드 표시
        if (isCodeRequested) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AuthInputField( // AuthInputField 재사용
                  controller: codeController,
                  hintText: '인증코드',
                  keyboardType: TextInputType.number,
                  readOnly: isCodeVerified, // 인증 완료되면 수정 불가
                ),
              ),
              const SizedBox(width: 8),
              // 4. 확인 버튼
              SizedBox(
                height: 56, // 텍스트 필드와 높이 맞추기
                child: ElevatedButton(
                  onPressed: isCodeVerified ? null : onCodeVerify, // 확인 후 비활성화
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCodeVerified
                        ? Colors.grey
                        : const Color(0xFF6AA84F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    isCodeVerified ? '완료' : '확인',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
