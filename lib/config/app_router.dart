import 'package:flutter/material.dart';
import 'package:guardpayfront/features/auth/screens/login_screen.dart';
import 'package:guardpayfront/features/auth/screens/signup_screen.dart';
import 'package:guardpayfront/features/auth/screens/reset_password_screen.dart';
import 'package:guardpayfront/features/auth/screens/home_screen.dart';
import 'package:guardpayfront/features/video/screens/video_category_screen.dart';
import 'package:guardpayfront/features/video/screens/video_list_screen.dart';
import 'package:guardpayfront/features/video/screens/video_player_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/login':
      return MaterialPageRoute(builder: (_) => const LoginScreen());

    case '/signup':
      return MaterialPageRoute(builder: (_) => const SignupScreen());

    case '/reset':
      return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());

    case '/home':
      return MaterialPageRoute(builder: (_) => const HomeScreen());

    case '/video':
      return MaterialPageRoute(builder: (_) => VideoCategoryScreen());

    case '/videoList':
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => VideoListScreen(
          categoryId: args['categoryId'],   // ✅ 추가
          categoryName: args['categoryName'], // ✅ 추가
        ),
      );

    case '/videoPlayer':
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          videoId: args['videoId'],  // ✅ 추가
          title: args['title'],      // ✅ 추가
        ),
      );

    default:
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('페이지를 찾을 수 없습니다.')),
        ),
      );
  }
}
