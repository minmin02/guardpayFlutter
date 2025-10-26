import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = const FlutterSecureStorage();
  String? accessToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await storage.read(key: 'accessToken');
    print('🟢 AccessToken from storage: $token'); // ✅ 콘솔에 찍히는 부분
    setState(() {
      accessToken = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('홈 화면')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('로그인 성공!'),
            const SizedBox(height: 12),
            Text(
              accessToken != null
                  ? '토큰이 정상적으로 저장되었습니다 ✅'
                  : '토큰이 없습니다 ❌',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await storage.deleteAll();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
