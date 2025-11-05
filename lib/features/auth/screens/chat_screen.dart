import 'package:flutter/material.dart';
import '../services/api_service.dart'; // ⬅️ 방금 만드신 API 서비스 임포트
// 필요한 다른 모델/위젯 임포트
import 'package:guardpayfront/core/services/storage.dart';

class ChatScreen extends StatefulWidget {

  final ApiService api;                                   // ✅ 주입받을 필드
  const ChatScreen({super.key, required this.api});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 1. 상태 관리를 위한 변수 선언

  final TextEditingController _textController = TextEditingController(); // 입력창 컨트롤러
  final List<Map<String, String>> _messages = []; // 대화 내용을 저장할 리스트 (사용자/AI 구분)
  bool _isLoading = false; // AI 응답 대기 상태

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // 2. 메시지 전송 로직
  void _handleSubmitted(String text) async {
    if (text.isEmpty || _isLoading) return;

    _textController.clear();

    // 사용자 메시지를 목록에 추가
    setState(() {
      _messages.insert(0, {'sender': 'user', 'text': text});
      _isLoading = true;
    });

    try {

      print('>>> [UI] call sendChatMessage("$text")');

      // 3. API 서비스 호출 (여기서 서버/Gemini와 통신)
      final aiResponse = await widget.api.sendChatMessage(text);
      print('>>> [UI] sendChatMessage returned: ${aiResponse.substring(0, aiResponse.length > 60 ? 60 : aiResponse.length)}');

      // AI 응답을 목록에 추가
      setState(() {
        _messages.insert(0, {'sender': 'ai', 'text': aiResponse});
      });
    } catch (e) {
      print('>>> [UI] exception: $e');

      // 오류 메시지 표시
      setState(() {
        _messages.insert(0, {'sender': 'ai', 'text': '죄송합니다. 오류가 발생했습니다: $e'});
      });
    } finally {

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 4. 입력창 위젯
  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted, // 엔터 키를 누를 때 실행
              decoration: const InputDecoration.collapsed(hintText: '궁금한 금융 질문을 입력하세요'),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
              icon: const Icon(Icons.send),
              onPressed: _isLoading
                  ? null // 로딩 중이면 버튼 비활성화
                  : () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('금융 AI 챗봇'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          // 5. 로딩 인디케이터 (AI 응답 대기 시)
          if (_isLoading)
            const LinearProgressIndicator(),

          // 6. 대화 목록 (ListView)
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true, // 최신 메시지가 아래로 오도록 설정
              itemBuilder: (_, int index) => _buildChatMessage(_messages[index]),
              itemCount: _messages.length,
            ),
          ),

          const Divider(height: 1.0),

          // 7. 입력창
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  // 8. 개별 메시지 버블 위젯
  Widget _buildChatMessage(Map<String, String> message) {
    final bool isUser = message['sender'] == 'user';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 메시지일 때만 아바타 (아이콘) 표시
          if (!isUser)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(child: Text('AI')),
            ),

          // 메시지 버블
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isUser ? Colors.blueAccent : Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              message['text']!,
              style: TextStyle(color: isUser ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }



}