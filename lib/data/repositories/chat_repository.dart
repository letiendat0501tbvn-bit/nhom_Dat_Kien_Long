import '../models/chat_message.dart';

// Trò chuyện trong bàn. Quyền (chỉ thành viên bàn) kiểm tra ở tầng trên.
abstract class ChatRepository {
  Future<List<ChatMessage>> getMessages(String tableId);

  Future<ChatMessage> sendMessage({
    required String tableId,
    required String senderId,
    required String text,
  });
}
