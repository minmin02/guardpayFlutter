import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:guardpayfront/core/services/storage.dart';
import 'package:guardpayfront/features/auth/widgets/bottom_nav.dart'; // ✅ 통일된 하단바

class ChatScreen extends StatefulWidget {
  final ApiService api;
  const ChatScreen({super.key, required this.api});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) async {
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.insert(0, {'sender': 'user', 'text': text});
      _isLoading = true;
    });

    try {
      final aiResponse = await widget.api.sendChatMessage(text);
      setState(() {
        _messages.insert(0, {'sender': 'ai', 'text': aiResponse});
      });
    } catch (e) {
      setState(() {
        _messages.insert(0, {
          'sender': 'ai',
          'text': '죄송합니다. 오류가 발생했습니다: $e'
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration(
                hintText: 'GuardAI에게 물어보세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF3F3F3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF7FB77E),
            child: IconButton(
              icon: const Icon(Icons.arrow_upward, color: Colors.white),
              onPressed: _isLoading
                  ? null
                  : () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(Map<String, String> message) {
    final bool isUser = message['sender'] == 'user';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              backgroundColor: Color(0xFF7FB77E),
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFFF8F8F8)
                    : const Color(0xFFFFFBF5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message['text']!,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 16),
              child: Column(
                children: const [
                  Text(
                    'GuardAI',
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7FB77E),
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const LinearProgressIndicator(color: Color(0xFF7FB77E)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                reverse: true,
                itemBuilder: (_, i) => _buildChatMessage(_messages[i]),
                itemCount: _messages.length,
              ),
            ),
            _buildTextComposer(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(selectedIndex: 1), // ✅ 통일된 하단바
    );
  }
}
