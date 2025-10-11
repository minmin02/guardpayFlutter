import 'package:flutter/material.dart';

// 앱의 모든 인증 화면에서 재사용할 수 있는 범용 입력 필드 위젯입니다.
class AuthInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword; // 비밀번호 가시성 토글이 필요한지 여부
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool readOnly;
  final bool enabled;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.enabled = true,
  });

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  // 비밀번호 필드일 경우 가리기 상태를 관리합니다.
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      // isPassword 속성에 따라 가리기 여부 및 가시성 토글 버튼 제공
      obscureText: _obscureText,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      decoration: InputDecoration(
        hintText: widget.hintText,
        // 비밀번호 필드일 경우에만 가시성 토글 버튼 제공
        suffixIcon: widget.isPassword
            ? IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: _toggleVisibility,
        )
            : null,
      ),
    );
  }
}
