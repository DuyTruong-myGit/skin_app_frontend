class ChatMessage {
  String text;
  final bool isUser; // True nếu là người dùng, false nếu là Gemini
  final bool isLoading; // (Tùy chọn) Dùng cho bong bóng "typing..."

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
  });
}