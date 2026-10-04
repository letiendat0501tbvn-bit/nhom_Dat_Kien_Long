import 'dart:async';
import 'dart:math';

import '../mock/mock_support.dart';
import '../models/chat_message.dart';
import 'chat_repository.dart';

// Phản hồi giả lập CHỈ ĐỂ DEMO: sau khi một người gửi tin, một thành viên khác của bàn
// tự trả lời sau 1–2 giây bằng một câu có sẵn. Không phải tính năng thật; bản
// Firebase/API sau này không có phần này. Tắt bằng cách không truyền AutoReply.
class AutoReply {
  AutoReply({
    required this.membersOf,
    Duration Function()? delay,
    this.phrases = _defaultPhrases,
  }) : delay = delay ?? _randomDelay;

  // Danh sách id thành viên của bàn (để chọn người trả lời).
  final Future<List<String>> Function(String tableId) membersOf;
  final Duration Function() delay;
  final List<String> phrases;

  // Ngẫu nhiên 1–2 giây.
  static Duration _randomDelay() =>
      Duration(milliseconds: 1000 + Random().nextInt(1001));
}

const _defaultPhrases = [
  'Ok bạn, hẹn gặp ở quán nhé!',
  'Mình sẽ đến sớm một chút.',
  'Bạn định gọi món gì vậy?',
  'Nghe hay đó, mình cũng thấy vậy.',
  'Mình có mang theo ô, trời hơi âm u.',
];

// Bản mock của ChatRepository: tin nhắn lưu trong bộ nhớ.
class MockChatRepository implements ChatRepository {
  MockChatRepository({
    required List<ChatMessage> messages,
    this.now = systemClock,
    this.latency = randomLatency,
    this.autoReply,
    this.blockedIdsOf,
  }) : _messages = List.of(messages);

  final Clock now;
  final Latency latency;
  final AutoReply? autoReply; // null: không có phản hồi giả lập
  // Id những người mà một người dùng đã chặn (để lọc tin nhắn). null: không ai bị chặn.
  final Future<Set<String>> Function(String userId)? blockedIdsOf;
  final List<ChatMessage> _messages;
  final _controller = StreamController<ChatMessage>.broadcast();
  var _nextId = 1000;
  var _replyCount = 0;

  @override
  Future<List<ChatMessage>> getMessages(
    String tableId, {
    String? viewerId,
  }) async {
    await Future<void>.delayed(latency());
    final blocked = await _blockedBy(viewerId);
    return _messages
        .where((m) => m.tableId == tableId && !blocked.contains(m.senderId))
        .toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  Future<Set<String>> _blockedBy(String? viewerId) async {
    final lookup = blockedIdsOf;
    if (viewerId == null || lookup == null) return const {};
    return lookup(viewerId);
  }

  @override
  Stream<ChatMessage> incoming(String tableId, {String? viewerId}) {
    // Kiểm tra lúc tin đến: chặn xong thì tin mới của người đó cũng không hiện.
    // Dùng asyncMap (không dùng async*) để đăng ký nghe luồng ngay khi listen.
    return _controller.stream
        .where((m) => m.tableId == tableId)
        .asyncMap(
          (m) async =>
              (await _blockedBy(viewerId)).contains(m.senderId) ? null : m,
        )
        .where((m) => m != null)
        .cast<ChatMessage>();
  }

  ChatMessage _add(String tableId, String senderId, String text) {
    final message = ChatMessage(
      id: 'm${_nextId++}',
      tableId: tableId,
      senderId: senderId,
      text: text,
      sentAt: now(),
    );
    _messages.add(message);
    return message;
  }

  @override
  Future<ChatMessage> sendMessage({
    required String tableId,
    required String senderId,
    required String text,
  }) async {
    await Future<void>.delayed(latency());
    final message = _add(tableId, senderId, text.trim());
    _scheduleReply(tableId, senderId);
    return message;
  }

  // Chỉ để demo: một thành viên khác trả lời sau 1–2 giây.
  void _scheduleReply(String tableId, String senderId) {
    final auto = autoReply;
    if (auto == null) return;
    Timer(auto.delay(), () async {
      if (_controller.isClosed) return;
      final others = (await auto.membersOf(tableId))
          .where((id) => id != senderId)
          .toList();
      if (others.isEmpty || _controller.isClosed) return;
      final i = _replyCount++;
      _controller.add(
        _add(
          tableId,
          others[i % others.length],
          auto.phrases[i % auto.phrases.length],
        ),
      );
    });
  }

  void dispose() => _controller.close();
}
