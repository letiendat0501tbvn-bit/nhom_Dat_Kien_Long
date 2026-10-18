import '../../core/entity.dart';

// Tin nhắn trong khung trò chuyện của một bàn.
class ChatMessage extends Entity<String> {
  const ChatMessage({
    required String id,
    required this.tableId,
    required this.senderId,
    required this.text,
    required this.sentAt,
  }) : super(id);

  final String tableId;
  final String senderId;
  final String text;
  final DateTime sentAt;

  @override
  String get label => text;
}
