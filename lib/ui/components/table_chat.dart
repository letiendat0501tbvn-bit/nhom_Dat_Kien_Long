import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/logic/table_rules.dart';
import '../../data/models/chat_message.dart';
import '../../l10n/formatters.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../theme/app_theme.dart';
import 'status_view.dart';

// Chat của một bàn (mục 4.5 SPEC). Widget này chỉ được dựng cho THÀNH VIÊN của bàn;
// việc quyết định ai thấy gì nằm ở chatAccessOf (table_rules.dart) và màn Chi tiết bàn.
// readOnly: bàn đã bắt đầu/kết thúc, ô nhập được thay bằng một dòng thông báo.
// Tin của mình căn phải, tin người khác căn trái kèm tên và giờ. Tin mới của người khác
// đến qua ChatRepository.incoming.
class TableChat extends StatefulWidget {
  const TableChat({
    super.key,
    required this.tableId,
    required this.userId,
    required this.readOnly,
    required this.nameOf,
  });

  final String tableId;
  final String userId;
  final bool readOnly;
  final String Function(String userId) nameOf;

  @override
  State<TableChat> createState() => _TableChatState();
}

class _TableChatState extends State<TableChat> {
  // Gần đáy (tính bằng pixel) thì coi như đang đọc tin mới nhất và được tự cuộn theo.
  static const _nearBottom = 80.0;
  static const _counterFrom = 450; // hiện bộ đếm khi gần chạm giới hạn

  final _input = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<ChatMessage>? _sub;
  var _status = LoadStatus.loading;
  var _messages = <ChatMessage>[];
  var _sending = false;
  String? _failedText; // nội dung của lần gửi lỗi gần nhất
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final repo = AppScope.of(context, listen: false).chatRepository;
    _sub = repo.incoming(widget.tableId).listen(_onIncoming);
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _status = LoadStatus.loading);
    try {
      final list = await AppScope.of(
        context,
        listen: false,
      ).chatRepository.getMessages(widget.tableId);
      if (!mounted) return;
      setState(() {
        _messages = list;
        _status = LoadStatus.ready;
      });
      _scrollToBottom(jump: true); // mở chat là thấy tin mới nhất
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = LoadStatus.error);
    }
  }

  bool get _isNearBottom =>
      !_scroll.hasClients ||
      _scroll.position.maxScrollExtent - _scroll.position.pixels <= _nearBottom;

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Tin của người khác: chỉ tự cuộn nếu người dùng đang ở cuối, không giật khi đang đọc tin cũ.
  void _onIncoming(ChatMessage m) {
    if (!mounted || _messages.any((x) => x.id == m.id)) return;
    final follow = _isNearBottom;
    setState(() => _messages = [..._messages, m]);
    if (follow) _scrollToBottom();
  }

  bool get _canSend =>
      !_sending && _status == LoadStatus.ready && isValidChatText(_input.text);

  Future<void> _send() async {
    final text = _input.text.trim();
    // Chặn bấm đúp, tin rỗng và tin quá dài
    if (_sending || !isValidChatText(text)) return;
    final repo = AppScope.of(context, listen: false).chatRepository;
    setState(() {
      _sending = true;
      _failedText = null;
    });
    try {
      final sent = await repo.sendMessage(
        tableId: widget.tableId,
        senderId: widget.userId,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        if (!_messages.any((x) => x.id == sent.id)) {
          _messages = [..._messages, sent];
        }
        // Chỉ xoá ô nhập nếu người dùng chưa sửa tiếp trong lúc gửi
        if (_input.text.trim() == text) _input.clear();
      });
      _scrollToBottom(); // tin của chính mình thì luôn cuộn xuống
    } catch (_) {
      if (!mounted) return;
      setState(() => _failedText = text); // giữ nguyên chữ trong ô để gửi lại
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _resend() {
    if (_input.text.trim().isEmpty && _failedText != null) {
      _input.text = _failedText!;
    }
    _send();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 340,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x1F000000)),
          ),
          clipBehavior: Clip.antiAlias,
          child: StatusView(
            status: _status,
            isEmpty: _messages.isEmpty,
            onRetry: _load,
            errorKey: StrKey.chatError,
            emptyKey: StrKey.chatEmpty,
            padding: const EdgeInsets.all(16),
            builder: (_) => _list(t),
          ),
        ),
        const SizedBox(height: 10),
        if (widget.readOnly)
          _ReadOnlyNotice(text: t(StrKey.chatReadOnly))
        else
          _composer(t),
      ],
    );
  }

  Widget _list(Strings t) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final m = _messages[i];
        final mine = m.senderId == widget.userId;
        return _Bubble(
          key: ValueKey(m.id),
          mine: mine,
          name: mine ? t(StrKey.chatYou) : widget.nameOf(m.senderId),
          time: formatClockTime(m.sentAt, t.language),
          text: m.text,
        );
      },
    );
  }

  Widget _composer(Strings t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_failedText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      t(StrKey.chatSendFailed),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _sending ? null : _resend,
                  child: Text(t(StrKey.chatResend)),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Semantics(
                textField: true,
                label: t(StrKey.chatHint),
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: maxChatLength, // chặn gõ quá 500 ký tự
                  keyboardType:
                      TextInputType.text, // Enter là gửi, không xuống dòng
                  textInputAction: TextInputAction.send,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _send(),
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        required maxLength,
                      }) => currentLength >= _counterFrom
                      ? Text(
                          t.fill(StrKey.chatCounter, {
                            'n': currentLength,
                            'max': maxLength ?? maxChatLength,
                          }),
                        )
                      : null,
                  decoration: InputDecoration(
                    hintText: t(StrKey.chatHint),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0x1F000000)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              // Cùng hàng với ô nhập một dòng (bỏ qua chỗ bộ đếm bên dưới)
              padding: const EdgeInsets.only(bottom: 2),
              child: IconButton.filled(
                tooltip: t(StrKey.chatSend),
                onPressed: _canSend ? _send : null,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.35,
                  ),
                ),
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Một tin nhắn: của mình căn phải (nền đỏ), của người khác căn trái (tên + giờ).
class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.mine,
    required this.name,
    required this.time,
    required this.text,
  });

  final bool mine;
  final String name;
  final String time;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textColor = mine ? Colors.white : AppColors.text;
    final subColor = mine
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.text.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      // Một mục cho trình đọc màn hình: "Tên, giờ: nội dung"
      child: Semantics(
        label: '$name, $time: $text',
        excludeSemantics: true,
        child: Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (context, c) => ConstrainedBox(
              constraints: BoxConstraints(maxWidth: c.maxWidth * 0.8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: mine ? AppColors.primary : AppColors.selectedBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: mine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!mine)
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    // Tin dài tự xuống dòng
                    Text(
                      text,
                      style: TextStyle(fontSize: 15, color: textColor),
                    ),
                    const SizedBox(height: 2),
                    Text(time, style: TextStyle(fontSize: 11, color: subColor)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.text.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 18,
            color: AppColors.text.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
