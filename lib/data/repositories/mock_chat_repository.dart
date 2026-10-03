import '../mock/mock_support.dart';
import '../models/chat_message.dart';
import 'chat_repository.dart';

// Bản mock của ChatRepository: tin nhắn lưu trong bộ nhớ.
class MockChatRepository implements ChatRepository {
  MockChatRepository({
    required List<ChatMessage> messages,
    this.now = systemClock,
    this.latency = randomLatency,
  }) : _messages = List.of(messages);

  final Clock now;
  final Latency latency;
  final List<ChatMessage> _messages;
  var _nextId = 1000;

  @override
  Future<List<ChatMessage>> getMessages(String tableId) async {
    await Future<void>.delayed(latency());
    return _messages.where((m) => m.tableId == tableId).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  @override
  Future<ChatMessage> sendMessage({
    required String tableId,
    required String senderId,
    required String text,
  }) async {
    await Future<void>.delayed(latency());
    final message = ChatMessage(
      id: 'm${_nextId++}',
      tableId: tableId,
      senderId: senderId,
      text: text.trim(),
      sentAt: now(),
    );
    _messages.add(message);
    return message;
  }
}
