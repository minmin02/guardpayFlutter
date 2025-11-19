import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guardpayfront/features/quiz/screens/quiz_screen.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ⬇️ AuthService 임포트 (경로를 프로젝트에 맞게 수정하세요)
import 'features/auth/services/auth_service.dart'; //
// ⬇️ kakao_map_plugin 제거하고 webview_flutter 사용
// import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'config/theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/home_screen.dart';
import 'features/assessment/screens/assessment_screen.dart';
import 'features/quiz/screens/quiz_category_screen.dart';
import 'features/quiz/screens/quiz_screen.dart';

import 'features/auth/screens/mypage_screen.dart';
// ✅ 영상 관련 import 추가
import 'package:guardpayfront/features/video/screens/video_category_screen.dart';
import 'package:guardpayfront/features/video/screens/video_list_screen.dart';
import 'package:guardpayfront/features/video/screens/video_player_screen.dart';

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

  // 4. 저장된 액세스 토큰과 리프레시 토큰 확인
  final storage = const FlutterSecureStorage();
  final accessToken = await storage.read(key: 'accessToken');
  final refreshToken = await storage.read(key: 'refreshToken');

  // ⬇️ [수정된 로직] 토큰 유효성 검사 및 갱신 시도
  String initialRoute = '/login'; // 기본값은 로그인 화면

  if (accessToken != null && refreshToken != null) {
    try {
      final authService = AuthService();

      // Refresh Token을 이용해 Access Token을 갱신하고 저장하는 로직 호출
      final bool isTokenRefreshed = await authService.checkAndRefreshTokens(refreshToken);

      if (isTokenRefreshed) {
        // 갱신 성공: 새 토큰 발급 완료, 홈으로 이동
        log('✅ [Auth Check] 토큰 갱신 성공. 홈 화면으로 이동.');
        initialRoute = '/home';
      } else {
        // 갱신 실패 (Refresh Token도 만료): 로그아웃 처리
        await storage.deleteAll(); // 저장된 토큰 모두 삭제
        log('🚨 [Auth Check] Refresh Token 만료 또는 유효하지 않음. 로그인 페이지로 이동.');
        initialRoute = '/login';
      }
    } catch (e) {
      // 서버 통신 오류 등 예외 발생 시: 로그아웃 처리 후 로그인 페이지로
      await storage.deleteAll();
      log('🚨 [Auth Check] 토큰 갱신 중 예외 발생 ($e). 로그인 페이지로 이동.');
      initialRoute = '/login';
    }
  }


  // 5. 토큰 유무에 따라 초기 화면 결정 후 앱 실행
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GuardPay App',

      // theme: appTheme(), // appTheme()이 정의되어 있다고 가정
      initialRoute: initialRoute, // 초기 라우트 설정
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/reset': (context) => const ResetPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/assessment': (context) => const AssessmentScreen(),
        '/quizCategory': (context) => const QuizCategoryScreen(),
        '/quiz': (context) => const QuizScreen(),
        '/mypage': (context) => const MypageScreen(),
        // ✅ 예방 영상 관련 라우트 (오류 수정 완료)
        '/video': (context) => VideoCategoryScreen(),
        '/videoList': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          final int categoryId = args['categoryId'];
          final String categoryName = args['categoryName'];

          return VideoListScreen(
            categoryId: categoryId,
            categoryName: categoryName,
          );
        },

        '/videoPlayer': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          final int videoId = args['videoId'];
          final String title = args['title']; // ✅ title 받기

          return VideoPlayerScreen(
            videoId: videoId,
            title: title, // ✅ title 전달
          );
        },
      },
    );
  }
}