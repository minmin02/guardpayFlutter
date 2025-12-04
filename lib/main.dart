import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guardpayfront/features/bank/screens/account_selection_screen.dart';
import 'package:guardpayfront/features/bank/screens/mock_transfer_screen.dart';
import 'package:guardpayfront/features/quiz/screens/quiz_screen.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';  // ✅ 중복 제거
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// AuthService 임포트
import 'features/auth/services/auth_service.dart';
import 'config/theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/home_screen.dart';
import 'features/assessment/screens/assessment_screen.dart';
import 'features/quiz/screens/quiz_category_screen.dart';
import 'features/quiz/screens/quiz_screen.dart';
import 'features/auth/screens/mypage_screen.dart';

// 영상 관련 import
import 'package:guardpayfront/features/video/screens/video_category_screen.dart';
import 'package:guardpayfront/features/video/screens/video_list_screen.dart';
import 'package:guardpayfront/features/video/screens/video_player_screen.dart';

void main() async {
  // 1. Flutter 엔진과 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 환경 변수(.env) 로드
  try {
    await dotenv.load(fileName: ".env");
    log("✅ .env 파일 로드 성공");
  } catch (e) {
    log("🚨 Error loading .env file: $e");
  }

  // 3. ✅ Kakao SDK 초기화 (.env에서 가져오기)
  final kakaoNativeAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];

  if (kakaoNativeAppKey != null && kakaoNativeAppKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);
    log("✅ Kakao SDK 초기화 성공: $kakaoNativeAppKey");
  } else {
    log("🚨 KAKAO_NATIVE_APP_KEY가 .env 파일에 없습니다!");
  }

  // 4. 저장된 액세스 토큰과 리프레시 토큰 확인
  final storage = const FlutterSecureStorage();
  final accessToken = await storage.read(key: 'accessToken');
  final refreshToken = await storage.read(key: 'refreshToken');

  // 5. 토큰 유효성 검사 및 갱신 시도
  String initialRoute = '/login'; // 기본값은 로그인 화면

  if (accessToken != null && refreshToken != null) {
    try {
      final authService = AuthService();

      // Refresh Token을 이용해 Access Token을 갱신하고 저장
      final bool isTokenRefreshed = await authService.checkAndRefreshTokens(refreshToken);

      if (isTokenRefreshed) {
        // 갱신 성공: 홈으로 이동
        log('✅ [Auth Check] 토큰 갱신 성공. 홈 화면으로 이동.');
        initialRoute = '/home';
      } else {
        // 갱신 실패: 로그아웃 처리
        await storage.deleteAll();
        log('🚨 [Auth Check] Refresh Token 만료. 로그인 페이지로 이동.');
        initialRoute = '/login';
      }
    } catch (e) {
      // 서버 통신 오류 등: 로그아웃 처리
      await storage.deleteAll();
      log('🚨 [Auth Check] 토큰 갱신 중 예외 발생 ($e). 로그인 페이지로 이동.');
      initialRoute = '/login';
    }
  } else {
    log('ℹ️ [Auth Check] 저장된 토큰 없음. 로그인 페이지로 이동.');
  }

  // 6. 앱 실행
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
      // theme: appTheme(),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/reset': (context) => const ResetPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/assessment': (context) => const AssessmentScreen(),
        '/quizCategory': (context) => const QuizCategoryScreen(),
        '/quiz': (context) => const QuizScreen(),
        '/accountSelection': (context) => const AccountSelectionScreen(),
        '/mypage': (context) => const MypageScreen(),

        // 예방 영상 관련 라우트
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
          final String title = args['title'];

          return VideoPlayerScreen(
            videoId: videoId,
            title: title,
          );
        },
      },
    );
  }
}