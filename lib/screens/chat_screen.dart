// import 'package:app/models/chat_message.dart';
// import 'package:app/services/api_service.dart';
// import 'package:flutter/material.dart';
//
// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});
//
//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final ApiService _apiService = ApiService();
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//
//   List<ChatMessage> _messages = [];
//   bool _isAwaitingResponse = false; // <-- Thay _isLoading bằng biến này
//   late Future<List<ChatMessage>> _historyFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _historyFuture = _apiService.getChatHistory();
//   }
//
//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   // === SỬA HÀM GỬI TIN NHẮN ĐỂ DÙNG STREAM ===
//   Future<void> _sendMessage() async {
//     final messageText = _messageController.text.trim();
//     if (messageText.isEmpty) return;
//
//     _messageController.clear();
//
//     // 1. Thêm tin nhắn của User
//     setState(() {
//       _messages.add(ChatMessage(text: messageText, isUser: true));
//       _isAwaitingResponse = true; // Bắt đầu chờ
//     });
//     _scrollToBottom();
//
//     // 2. Thêm bong bóng "rỗng" của Bot ngay lập tức
//     setState(() {
//       _messages.add(ChatMessage(text: "", isUser: false));
//     });
//     _scrollToBottom();
//
//     // 3. Gọi API và lắng nghe Stream
//     try {
//       final stream = _apiService.sendMessageToGemini(messageText);
//
//       // Lắng nghe từng mẩu (chunk)
//       await for (final chunk in stream) {
//         setState(() {
//           // Nối text vào tin nhắn cuối cùng (tin nhắn rỗng của Bot)
//           _messages.last.text += chunk;
//         });
//         _scrollToBottom();
//       }
//
//     } catch (e) {
//       // Nếu Stream bị lỗi
//       setState(() {
//         _messages.last.text = 'Lỗi: Không thể kết nối. Vui lòng thử lại.';
//       });
//     } finally {
//       // 4. Dừng chờ (cho phép gửi tin mới)
//       setState(() {
//         _isAwaitingResponse = false;
//       });
//       _scrollToBottom();
//     }
//   }
//   // Hàm tự cuộn
//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Trợ lý AI (Da liễu)'),
//       ),
//       body: Column(
//         children: [
//           // 1. Khu vực hiển thị Chat
//           Expanded(
//             child: FutureBuilder<List<ChatMessage>>(
//               future: _historyFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Lỗi tải lịch sử chat: ${snapshot.error}'));
//                 }
//
//                 if (_messages.isEmpty && snapshot.hasData) {
//                   _messages = snapshot.data!;
//                   if (_messages.isEmpty) {
//                     _messages.add(ChatMessage(
//                       text: 'Xin chào! Bạn muốn hỏi gì về bệnh da liễu hôm nay? (Lưu ý: Chỉ mang tính tham khảo)',
//                       isUser: false,
//                     ));
//                   }
//                   // Tải xong lịch sử thì cuộn xuống dưới cùng
//                   _scrollToBottom();
//                 }
//
//                 // === LOGIC HIỂN THỊ "TYPING..." ===
//                 return ListView.builder(
//                   controller: _scrollController,
//                   padding: const EdgeInsets.all(16.0),
//                   itemCount: _messages.length, // Chỉ hiển thị các tin nhắn
//                   itemBuilder: (context, index) {
//                     final message = _messages[index];
//                     return _buildChatBubble(message);
//                   },
//                 );
//                 // ===================================
//               },
//             ),
//           ),
//
//           // 2. Khu vực nhập liệu
//           _buildTextInputArea(),
//         ],
//       ),
//     );
//   }
//
//   // Widget cho 1 bong bóng chat
//   Widget _buildChatBubble(ChatMessage message) {
//     final theme = Theme.of(context);
//     final isUser = message.isUser;
//
//     return Row(
//       mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//       children: [
//         Container(
//           constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
//           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//           margin: const EdgeInsets.symmetric(vertical: 4),
//           decoration: BoxDecoration(
//             color: isUser
//                 ? theme.primaryColor
//                 : theme.cardColor,
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Text(
//             message.text,
//             style: TextStyle(
//               color: isUser ? Colors.white : theme.textTheme.bodyLarge?.color,
//             ),
//           ),
//           // ================================
//         ),
//       ],
//     );
//   }
//
//   // Widget cho khu vực nhập text
//   Widget _buildTextInputArea() {
//     return Container(
//       padding: const EdgeInsets.all(8.0),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, -5),
//           )
//         ],
//       ),
//         child: SafeArea(
//           child: Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: _messageController,
//                   decoration: const InputDecoration(
//                     hintText: 'Nhập tin nhắn...',
//                     border: InputBorder.none,
//                     filled: false,
//                   ),
//                   onSubmitted: (value) => _sendMessage(),
//                 ),
//               ),
//               IconButton(
//                 icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
//                 // SỬA: Dùng _isAwaitingResponse
//                 onPressed: _isAwaitingResponse ? null : _sendMessage,
//               ),
//             ],
//           ),
//     ),
//     );
//   }
// }







import 'package:app/models/chat_message.dart';
import 'package:app/services/api_service.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isAwaitingResponse = false;
  late Future<List<ChatMessage>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _apiService.getChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(text: messageText, isUser: true));
      _isAwaitingResponse = true;
    });
    _scrollToBottom();

    setState(() {
      _messages.add(ChatMessage(text: "", isUser: false));
    });
    _scrollToBottom();

    try {
      final stream = _apiService.sendMessageToGemini(messageText);

      await for (final chunk in stream) {
        setState(() {
          _messages.last.text += chunk;
        });
        _scrollToBottom();
      }

    } catch (e) {
      setState(() {
        _messages.last.text = 'Lỗi: Không thể kết nối. Vui lòng thử lại.';
      });
    } finally {
      setState(() {
        _isAwaitingResponse = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trợ lý AI (Da liễu)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'Tư vấn sức khỏe da',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: FutureBuilder<List<ChatMessage>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0066CC).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: const Color(0xFFE53935).withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Lỗi tải lịch sử chat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_messages.isEmpty && snapshot.hasData) {
                  _messages = snapshot.data!;
                  if (_messages.isEmpty) {
                    _messages.add(ChatMessage(
                      text: 'Xin chào! Bạn muốn hỏi gì về bệnh da liễu hôm nay? (Lưu ý: Chỉ mang tính tham khảo)',
                      isUser: false,
                    ));
                  }
                  _scrollToBottom();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildChatBubble(message, index);
                  },
                );
              },
            ),
          ),

          // Typing indicator
          if (_isAwaitingResponse && _messages.isNotEmpty && _messages.last.text.isEmpty)
            _buildTypingIndicator(),

          // Text input area
          _buildTextInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message, int index) {
    final isUser = message.isUser;
    final isLastMessage = index == _messages.length - 1;
    final isTyping = isLastMessage && !isUser && message.text.isEmpty && _isAwaitingResponse;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot avatar
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 10, top: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0066CC).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
          ],

          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                  colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 18 : 6),
                  topRight: Radius.circular(isUser ? 6 : 18),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? const Color(0xFF0066CC).withOpacity(0.2)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: isUser ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: isTyping
                  ? const SizedBox.shrink()
                  : Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF1A1A1A),
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),

          // User avatar
          if (isUser) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 10, top: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              ),
              child: const Icon(Icons.person, color: Color(0xFF666666), size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(left: 62, bottom: 12, right: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 6),
                _buildDot(1),
                const SizedBox(width: 6),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = ((value + delay) % 1.0);
        final opacity = (animValue < 0.5) ? animValue * 2 : (1 - animValue) * 2;

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0066CC).withOpacity(0.3 + (opacity * 0.7)),
          ),
        );
      },
      onEnd: () {
        if (mounted && _isAwaitingResponse) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildTextInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                      height: 1.4,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      hintStyle: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) => _sendMessage(),
                    enabled: !_isAwaitingResponse,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _isAwaitingResponse
                      ? const LinearGradient(
                    colors: [Color(0xFFCCCCCC), Color(0xFFAAAAAA)],
                  )
                      : const LinearGradient(
                    colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: _isAwaitingResponse
                      ? []
                      : [
                    BoxShadow(
                      color: const Color(0xFF0066CC).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isAwaitingResponse ? null : _sendMessage,
                    borderRadius: BorderRadius.circular(24),
                    child: Center(
                      child: _isAwaitingResponse
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}