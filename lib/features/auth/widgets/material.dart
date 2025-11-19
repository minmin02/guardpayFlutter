import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int selectedIndex;

  const BottomNav({
    super.key,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz),
          label: '퀴즈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.video_library),
          label: '영상',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assessment),
          label: '평가',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: '지도',
        ),
      ],
      onTap: (index) {
        if (index == selectedIndex) return;

        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/quizCategory');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/video');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/assessment');
            break;
          case 4:
          // 현재 지도 화면
            break;
        }
      },
    );
  }
}