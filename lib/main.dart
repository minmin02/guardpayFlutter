import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config/theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/home_screen.dart';

void main() async {
  // 1. Flutter 엔진과 위젯 바인딩 초기화 (비동기 작업 이전에 필수)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 환경 변수(.env) 로드 (AuthService 등에서 사용하기 전에 필수)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env 파일 로드 실패 시 콘솔에 출력 (디버깅용)
    log("Error loading .env file: $e");
  }

  // 3. Kakao SDK 초기화 (네이티브 앱 키 사용)
  KakaoSdk.init(nativeAppKey: '6cdfe8239c6cf5fdbaf793f4fc9581e3');

  // 4. 저장된 액세스 토큰 확인
  final storage = FlutterSecureStorage();
  final accessToken = await storage.read(key: 'accessToken');

  // 5. 토큰 유무에 따라 초기 화면 결정 후 앱 실행
  runApp(MyApp(initialRoute: accessToken != null ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GuardPay App',
      theme: appTheme(),
      initialRoute: initialRoute, // 초기 라우트 설정
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/reset': (context) => const ResetPasswordScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
