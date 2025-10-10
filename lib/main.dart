// Flutter 앱의 시작점입니다.
import 'package:flutter/material.dart';
// 1. 우리가 만든 회원가입 화면 파일을 불러옵니다.
import 'features/auth/screens/signup_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GuardPay App',
      theme: ThemeData(
        // 앱의 전반적인 색상 톤을 설정합니다.
        primarySwatch: Colors.green,
        // 배경색을 React Native 버전과 유사하게 설정합니다.
        scaffoldBackgroundColor: const Color(0xFFF9F5EC),
        // 입력창(TextField)의 기본 디자인을 설정합니다.
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      // 2. 앱이 시작될 때 보여줄 첫 화면으로 SignupScreen을 지정합니다.
      home: const SignupScreen(),
    );
  }
}

