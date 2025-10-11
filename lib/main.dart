import 'package:flutter/material.dart';
// 1. 우리가 만든 회원가입 화면 파일을 불러옵니다.
import 'features/auth/screens/signup_screen.dart';
// 테마 설정을 config 폴더에서 불러옵니다.
import 'config/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 이제 main.dart에서는 테마 정의 없이 appTheme() 함수를 호출합니다.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GuardPay App',
      // config/theme.dart에서 정의한 테마를 사용합니다.
      theme: appTheme(),
      // 2. 앱이 시작될 때 보여줄 첫 화면으로 SignupScreen을 지정합니다.
      home: const SignupScreen(),
    );
  }
}
