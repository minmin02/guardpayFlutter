import 'package:flutter/material.dart';
// HTTP 요청을 위해 http 패키지를 불러옵니다.
import 'package:http/http.dart' as http;
// 데이터를 JSON으로 변환하기 위해 필요합니다.
import 'dart:convert';

// React의 함수형 컴포넌트가 Flutter의 StatefulWidget으로 변경됩니다.
// 화면의 내용이 바뀌어야 할 때 (예: 글자 입력) StatefulWidget을 사용합니다.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

// 위젯의 '상태'를 관리하는 클래스입니다. React의 useState 훅의 역할을 합니다.
class _SignupScreenState extends State<SignupScreen> {
  // 1. 폼 데이터 상태 관리
  // React의 formData 객체 대신, 각 입력 필드를 TextEditingController로 관리합니다.
  final _emailController = TextEditingController();
  final _authCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();

  // 체크박스와 이메일 확인 상태는 boolean으로 관리합니다.
  bool _termsAgreed = false;
  bool _isEmailConfirmed = false;

  // 2. 입력값 변경 시 상태 업데이트
  // Controller를 사용하면 따로 핸들러가 필요 없지만, 체크박스를 위해 만듭니다.
  void _toggleTerms(bool? value) {
    // setState는 React의 setFormData와 같습니다. 화면을 다시 그리도록 명령합니다.
    setState(() {
      _termsAgreed = value ?? false;
    });
  }

  // 3. 이메일 '확인' 버튼 함수
  void _handleEmailConfirm() {
    final email = _emailController.text;
    final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      // alert() 대신 ScaffoldMessenger와 SnackBar를 사용해 메시지를 보여줍니다.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 이메일 주소를 입력해주세요.')),
      );
      return;
    }

    print('이메일 확인 완료: $email');
    setState(() {
      _isEmailConfirmed = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이메일이 확인되었습니다.')),
    );
  }

  // 4. '가입하기' 버튼 함수 (handleSubmit)
  Future<void> _handleSubmit() async {
    // 유효성 검사
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 항목(*)을 모두 입력해주세요.')),
      );
      return;
    }
    if (_passwordController.text != _passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }
    if (!_termsAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약관에 동의해주세요.')),
      );
      return;
    }

    // 🚨 중요: API 주소는 React Native와 동일하게 10.0.2.2를 사용합니다.
    const apiUrl = 'http://10.0.2.2:8080/api/users/signup';

    // 서버에 보낼 데이터 (JavaScript의 객체 -> Dart의 Map)
    final signupData = {
      'email': _emailController.text,
      'password': _passwordController.text,
      'nickname': _nicknameController.text,
    };

    try {
      // axios.post -> http.post
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(signupData), // 데이터를 JSON 문자열로 인코딩
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('가입 성공 응답: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입이 완료되었습니다!')),
        );
        // TODO: 로그인 화면으로 이동하는 로직 추가
      } else {
        print('가입 실패: ${response.body}');
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '가입에 실패했습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (error) {
      print('가입 요청 실패: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 통신할 수 없습니다.')),
      );
    }
  }

  // React의 return (...) 부분은 Flutter의 build 메소드에 해당합니다.
  // JSX 대신 위젯(Widget)을 조립하여 UI를 만듭니다.
  @override
  Widget build(BuildContext context) {
    // Scaffold는 화면의 기본 구조(상단 바, 본문 등)를 제공합니다.
    return Scaffold(
      // 키보드가 올라올 때 화면이 가려지지 않도록 스크롤 가능하게 만듭니다.
      body: SingleChildScrollView(
        // 화면 전체에 여백을 줍니다.
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: Column(
          // 자식 위젯들을 세로로 정렬합니다.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'GuardPay',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6AA84F),
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30), // 여백

            // 이메일 입력
            const Text('이메일 *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: '이메일',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),

            // 비밀번호 입력
            const Text('비밀번호 *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                hintText: '비밀번호',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              obscureText: true, // 비밀번호 가리기
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordConfirmController,
              decoration: const InputDecoration(
                hintText: '비밀번호 재입력',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 15),

            // 닉네임 입력
            const Text('닉네임 *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                hintText: '닉네임',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 25),

            // 약관 동의
            Row(
              children: [
                Checkbox(
                  value: _termsAgreed,
                  onChanged: _toggleTerms,
                ),
                const Text('약관 전체 동의'),
              ],
            ),
            const SizedBox(height: 20),

            // 가입하기 버튼
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6AA84F),
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('가입하기'),
            ),
          ],
        ),
      ),
    );
  }
}
