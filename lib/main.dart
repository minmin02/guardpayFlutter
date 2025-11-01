import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config/theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: '6cdfe8239c6cf5fdbaf793f4fc9581e3');

  // ✅ 토큰 체크 후 적절한 첫 화면 결정
  final storage = FlutterSecureStorage();
  final accessToken = await storage.read(key: 'accessToken');

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
      initialRoute: initialRoute, // ✅ 토큰 존재 여부에 따라 첫 화면 변경
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/reset': (context) => const ResetPasswordScreen(),
        '/home': (context) => const HomeScreen(), // ✅ 홈 라우트 추가
      },
    );
  }
}
