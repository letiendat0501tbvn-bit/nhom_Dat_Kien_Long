import '../../core/entity.dart';
import '../../core/map_utils.dart';

// Tin nhắn trong khung trò chuyện của một bàn.
class ChatMessage extends Entity<String> {
  const ChatMessage({
    required String id,
    required this.tableId,
    required this.senderId,
    required this.text,
    required this.sentAt,
  }) : super(id);

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) =>
      ChatMessage(
        id: id,
        tableId: map['tableId'] as String,
        senderId: map['senderId'] as String,
        text: map['text'] as String,
        sentAt: readDate(map['sentAt']),
      );

  final String tableId;
  final String senderId;
  final String text;
  final DateTime sentAt;

  @override
  Map<String, dynamic> toMap() => {
    'tableId': tableId,
    'senderId': senderId,
    'text': text,
    'sentAt': sentAt,
  };

  @override
  String get label => text;
}
