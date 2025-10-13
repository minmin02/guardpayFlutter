import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    const apiUrl = 'http://10.0.2.2:8080/api/auth/login';
    final loginData = {
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 성공!')),
        );
        // TODO: 홈 화면 이동
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? '로그인 실패')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 통신할 수 없습니다.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 110),
              const Text(
                'GuardPay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6AA84F),
                  fontSize: 55,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 80),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: '이메일',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 13.0, horizontal: 15.0),
                ),
              ),

              const SizedBox(height: 13),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: '비밀번호',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 13.0, horizontal: 15.0),
                ),
              ),

              const SizedBox(height: 13),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6AA84F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('로그인'),
              ),

              const SizedBox(height: 13),
              // 회원가입 이동 버튼
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6AA84F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('회원가입'),
              ),

              const SizedBox(height: 7),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/reset');
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                    fontSize: 14
                  )
                ),
                child: const Text('이메일/비밀번호 찾기 >'),
              ),

              // 소셜 로그인 버튼 추가
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 카카오 로그인 버튼
                  GestureDetector(
                    onTap: () {
                      // TODO: 카카오 로그인 로직 구현
                    },
                    child: Image.asset(
                      'assets/images/kakao_logo.png',
                      width: 70,
                      height: 70,
                    ),
                  ),

                  const SizedBox(width: 22),
                  // 구글 로그인 버튼
                  GestureDetector(
                    onTap: () {
                      // TODO: 구글 로그인 로직 구현
                    },
                    child: Image.asset(
                      'assets/images/google_logo.png',
                      width: 70,
                      height: 70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
