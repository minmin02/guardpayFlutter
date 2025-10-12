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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'GuardPay',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6AA84F),
                fontSize: 50,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: '이메일',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: '비밀번호',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6AA84F),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('로그인'),
            ),
            const SizedBox(height: 10),

            // 회원가입 이동 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6AA84F),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('회원가입'),
            ),
            const SizedBox(height: 10),

            TextButton(
              onPressed: () {
                // TODO: 비밀번호 찾기 페이지 연결
              },
              child: const Text('이메일/비밀번호 찾기 >'),
            ),
          ],
        ),
      ),
    );
  }
}
