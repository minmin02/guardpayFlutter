import 'package:flutter/material.dart';
import 'package:guardpayfront/features/auth/screens/chat_screen.dart';
import 'package:guardpayfront/features/auth/screens/home_screen.dart';
import 'package:guardpayfront/features/auth/services/api_service.dart';

class BottomNav extends StatelessWidget {
  final int selectedIndex;
  const BottomNav({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final ApiService api = ApiService();

    void _navigateTo(int index) {
      if (index == selectedIndex) return; // 같은 탭이면 아무 것도 안 함
      switch (index) {
        case 0: // 홈
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
          );
          break;
        case 1: // AI
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(api: api)),
                (route) => false,
          );
          break;
        case 2:
        // TODO: 쇼핑 화면
          break;
        case 3:
        // TODO: 송금 화면
          break;
        case 4:
        // TODO: 지도 화면
          break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomIcon(
            imagePath: 'assets/images/home_icon.png',
            isActive: selectedIndex == 0,
            onTap: () => _navigateTo(0),
          ),
          _BottomIcon(
            imagePath: 'assets/images/AI_icon.png',
            isActive: selectedIndex == 1,
            onTap: () => _navigateTo(1),
          ),
          _BottomIcon(
            imagePath: 'assets/images/shop_icon.png',
            isActive: selectedIndex == 2,
            onTap: () => _navigateTo(2),
          ),
          _BottomIcon(
            imagePath: 'assets/images/money_icon.png',
            isActive: selectedIndex == 3,
            onTap: () => _navigateTo(3),
          ),
          _BottomIcon(
            imagePath: 'assets/images/map_icon.png',
            isActive: selectedIndex == 4,
            onTap: () => _navigateTo(4),
          ),
        ],
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  final String imagePath;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomIcon({
    required this.imagePath,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        imagePath,
        width: 45,
        height: 45,
        color: isActive ? null : Colors.black54,
      ),
    );
  }
}
