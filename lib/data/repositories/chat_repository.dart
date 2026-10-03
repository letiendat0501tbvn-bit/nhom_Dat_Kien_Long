import '../models/chat_message.dart';

// Trò chuyện trong bàn. Quyền (chỉ thành viên bàn còn hiệu lực) kiểm tra ở tầng trên.
// Chưa có tin hệ thống ("X đã tham gia"...): ChatMessage chỉ có tin của người dùng.
abstract class ChatRepository {
  Future<List<ChatMessage>> getMessages(String tableId);

  Future<ChatMessage> sendMessage({
    required String tableId,
    required String senderId,
    required String text,
  });

  // Tin mới do NGƯỜI KHÁC gửi vào bàn (tin của chính mình đã có trong kết quả của
  // sendMessage). Giao diện nghe luồng này để hiện tin mới ngay.
  Stream<ChatMessage> incoming(String tableId);
}
