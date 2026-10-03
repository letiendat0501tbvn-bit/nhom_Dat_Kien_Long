// Tin nhắn trong khung trò chuyện của một bàn.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.tableId,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String tableId;
  final String senderId;
  final String text;
  final DateTime sentAt;
}
