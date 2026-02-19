import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Position? _pos;
  String? _conversationId;

  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'text': "Hello! 🙏 I'm SafeHer AI, your Tamil Nadu safety companion.\n\nI can help you with:\n• 🚨 Emergency guidance\n• 📍 Nearest police & hospitals\n• 🛡️ Safety tips\n• 🏨 Safe hotel recommendations\n\nHow can I help keep you safe today?"
    }
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    final pos = await _locationService.getCurrentLocation();
    if (mounted) setState(() => _pos = pos);
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isLoading) return;
    final userMsg = _controller.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'text': userMsg});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final response = await _apiService.sendMessage(
      userId: 'flutter_user_001',
      message: userMsg,
      conversationId: _conversationId,
      location: _pos != null ? {'lat': _pos!.latitude, 'lng': _pos!.longitude} : null,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _conversationId = response['conversation_id'];
        _messages.add({
          'role': 'assistant',
          'text': response['success'] == true
              ? (response['response'] ?? "I'm having trouble responding. Call 112 for emergencies.")
              : "Connection issue. For emergencies: Call 100 (Police) or 112.",
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C3DE0), Color(0xFF3B1FAD)],
            ),
          ),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.amber,
              radius: 18,
              child: Text("AI", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SafeHer AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Powered by Gemini • TN Edition", style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(colors: [Color(0xFF6C3DE0), Color(0xFF9B5DE5)])
              : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          msg['text'] as String,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C3DE0))),
            SizedBox(width: 10),
            Text("SafeHer AI is thinking...", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Ask me anything about safety...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48, height: 48,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6C3DE0), Color(0xFF9B5DE5)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
