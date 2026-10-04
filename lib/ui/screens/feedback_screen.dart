import 'package:flutter/material.dart';

import '../../data/logic/feedback_rules.dart';
import '../../data/models/user_feedback.dart';
import '../../l10n/formatters.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../components/status_view.dart';
import '../theme/app_theme.dart';

// "Phản hồi riêng tư" (Hồ sơ > Tài khoản, chỉ thành viên): gửi phản hồi và xem lại các phản
// hồi đã gửi (mới nhất trước). Phản hồi chỉ của riêng người gửi, không hiện cho người khác.
// Chưa có ảnh thiết kế; dựng theo phong cách các màn khác.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const _counterFrom = 450; // hiện bộ đếm khi gần chạm giới hạn

  final _input = TextEditingController();
  var _status = LoadStatus.loading;
  var _items = <UserFeedback>[];
  var _sending = false;
  String? _failedText; // nội dung của lần gửi lỗi gần nhất
  var _started = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = LoadStatus.loading);
    try {
      final app = AppScope.of(context, listen: false);
      final me = app.currentUser;
      final list = me == null
          ? <UserFeedback>[]
          : await app.safetyRepository.getFeedbacks(me.id);
      if (!mounted) return;
      setState(() {
        _items = _newestFirst(list);
        _status = LoadStatus.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = LoadStatus.error);
    }
  }

  List<UserFeedback> _newestFirst(List<UserFeedback> list) =>
      [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  bool get _canSend =>
      !_sending &&
      _status != LoadStatus.loading &&
      isValidFeedback(_input.text);

  Future<void> _send() async {
    final text = _input.text.trim();
    // Chặn bấm đúp, phản hồi rỗng và quá dài
    if (_sending || !isValidFeedback(text)) return;
    final app = AppScope.of(context, listen: false);
    final me = app.currentUser;
    if (me == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final t = context.strings;
    setState(() {
      _sending = true;
      _failedText = null;
    });
    try {
      final sent = await app.safetyRepository.submitFeedback(
        userId: me.id,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        _items = _newestFirst([..._items, sent]);
        // Chỉ xoá ô nhập nếu người dùng chưa sửa tiếp trong lúc gửi
        if (_input.text.trim() == text) _input.clear();
      });
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t(StrKey.fbSent))));
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
    return Scaffold(
      appBar: AppBar(title: Text(t(StrKey.privateFeedback))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PrivateNote(text: t(StrKey.fbNote)),
              const SizedBox(height: 16),
              _composer(t),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  t(StrKey.fbSentTitle),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StatusView(
                status: _status,
                isEmpty: _items.isEmpty,
                onRetry: _load,
                emptyKey: StrKey.fbEmpty,
                errorKey: StrKey.fbError,
                builder: (_) => Column(
                  children: [
                    for (final f in _items)
                      _FeedbackCard(key: ValueKey(f.id), feedback: f),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer(Strings t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _input,
          minLines: 4,
          maxLines: 8,
          maxLength: maxFeedbackLength, // chặn gõ quá 500 ký tự
          onChanged: (_) => setState(() {}),
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
                    'max': maxLength ?? maxFeedbackLength,
                  }),
                )
              : null,
          decoration: InputDecoration(
            labelText: t(StrKey.fbHint),
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0x1F000000)),
            ),
          ),
        ),
        if (_failedText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      t(StrKey.fbSendFailed),
                      style: const TextStyle(
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
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: _canSend ? _send : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: const StadiumBorder(),
            ),
            child: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    t(StrKey.fbSend),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}

// Ghi chú "phản hồi này là riêng tư".
class _PrivateNote extends StatelessWidget {
  const _PrivateNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.selectedBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(
            child: Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({super.key, required this.feedback});

  final UserFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final when =
        '${formatDayMonth(feedback.createdAt)} · ${formatClockTime(feedback.createdAt, t.language)}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1F000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            when,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            feedback.text,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// Mở màn "Phản hồi riêng tư".
Future<void> openFeedback(BuildContext context) {
  return Navigator.of(
    context,
  ).push<void>(MaterialPageRoute<void>(builder: (_) => const FeedbackScreen()));
}
