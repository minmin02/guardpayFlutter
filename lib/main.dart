import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

// --- 필요한 파일들을 모두 import 합니다 ---
import 'config/theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';

void main() {
  // ✅ 앱이 시작되기 전에 카카오 SDKS 초기화합니다.
  KakaoSdk.init(
    nativeAppKey: '6cdfe8239c6cf5fdbaf793f4fc9581e3',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GuardPay App',
      // ✅ config/theme.dart에서 정의한 테마를 사용합니다.
      theme: appTheme(),
      // ✅ 앱의 첫 화면을 로그인 화면으로 설정합니다.
      initialRoute: '/login',
      // ✅ 여러 화면을 관리하고 쉽게 이동하기 위해 routes 방식을 사용합니다.
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/reset': (context) => const ResetPasswordScreen(),
      },
    );
  }
}
