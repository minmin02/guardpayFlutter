import 'package:flutter/material.dart';

// 앱 전체에서 사용할 기본 색상 정의
const Color primaryColor = Color(0xFF6AA84F); // GuardPay Green
const Color lightGrayBorder = Color(0xFFD0D0D0); // 연한 회색 테두리
const Color lightBackground = Color(0xFFF9F5EC); // 베이지 배경색

// 앱의 전체 테마를 정의하는 함수
ThemeData appTheme() {
  return ThemeData(
    // 앱의 전반적인 색상 톤을 설정합니다.
      primaryColor: primaryColor,
      // 배경색을 베이지색으로 설정합니다.
      scaffoldBackgroundColor: lightBackground,

      // 입력창(TextField)의 기본 디자인을 설정합니다.
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        // 힌트 텍스트 색상 설정
        hintStyle: TextStyle(color: Color(0xFFBDBDBD)),

        // 기본 테두리 스타일: 둥근 모서리(8.0)와 연한 회색 테두리
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          borderSide: BorderSide(color: lightGrayBorder),
        ),
        // 활성화된 상태의 테두리
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          borderSide: BorderSide(color: lightGrayBorder),
        ),
        // 포커스 상태의 테두리 (주요 색상으로 강조)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
        // 비활성화 상태의 테두리 (인증 완료 시 사용)
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          borderSide: BorderSide(color: lightGrayBorder, width: 1.0),
        ),
        // 입력 필드 내부 패딩
        contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      ),

      // Checkbox의 색상 설정
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.white;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      )
  );
}
