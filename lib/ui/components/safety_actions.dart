import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../data/repositories/safety_repository.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../theme/app_theme.dart';
import 'login_sheet.dart';
import 'option_chips.dart';

// Các thao tác báo cáo / chặn / bỏ chặn dùng chung (Chi tiết bàn, chat, Hồ sơ).
// Tất cả đều cần đăng nhập: khách bấm thì chỉ mở bảng đăng nhập, KHÔNG tự gửi báo cáo
// hay chặn sau khi đăng nhập (người dùng tự bấm lại).

const maxReportNoteLength = 280;

void _toast(ScaffoldMessengerState messenger, String text) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

// Báo cáo một bàn / người dùng / tin nhắn. title: tiêu đề hộp ("Báo cáo bàn"...).
Future<void> reportTarget(
  BuildContext context, {
  required ReportTargetType type,
  required String targetId,
  required String title,
}) async {
  final app = AppScope.of(context, listen: false);
  final user = app.currentUser;
  if (user == null) {
    await showLoginSheet(context);
    return;
  }
  // Không báo cáo chính mình
  if (type == ReportTargetType.user && targetId == user.id) return;
  final messenger = ScaffoldMessenger.of(context);
  final t = context.strings;
  final result = await showModalBottomSheet<_ReportResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _ReportSheet(type: type, targetId: targetId, title: title),
  );
  if (result == null) return;
  _toast(
    messenger,
    t(
      result == _ReportResult.sent ? StrKey.reportSent : StrKey.reportDuplicate,
    ),
  );
}

enum _ReportResult { sent, duplicate }

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.type,
    required this.targetId,
    required this.title,
  });

  final ReportTargetType type;
  final String targetId;
  final String title;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _note = TextEditingController();
  ReportReason? _reason;
  var _sending = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return; // chặn bấm đúp
    final t = context.strings;
    final reason = _reason;
    if (reason == null) {
      setState(() => _error = t(StrKey.reportNeedReason));
      return;
    }
    final app = AppScope.of(context, listen: false);
    final user = app.currentUser;
    if (user == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await app.safetyRepository.submitReport(
        reporterId: user.id,
        targetType: widget.type,
        targetId: widget.targetId,
        reason: reason.name,
        note: _note.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(_ReportResult.sent);
    } on SafetyException catch (e) {
      if (!mounted) return;
      if (e.error == SafetyError.alreadyReported) {
        Navigator.of(context).pop(_ReportResult.duplicate);
      } else {
        setState(() {
          _sending = false;
          _error = t(StrKey.reportFailed);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = t(StrKey.reportFailed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return Padding(
      // Đẩy nội dung lên trên bàn phím
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              t(StrKey.reportPrompt),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            OptionChips<ReportReason>(
              options: [
                for (final r in ReportReason.values)
                  (r, t.reportReasonLabel(r.name)),
              ],
              selected: _reason,
              onChanged: _sending
                  ? (_) {}
                  : (v) => setState(() {
                      _reason = v;
                      _error = null;
                    }),
            ),
            const SizedBox(height: 16),
            Text(
              t(StrKey.reportNoteTitle),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              enabled: !_sending,
              minLines: 2,
              maxLines: 4,
              maxLength: maxReportNoteLength,
              decoration: InputDecoration(
                hintText: t(StrKey.reportNoteHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0x1F000000)),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _sending ? null : _submit,
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
                        t(StrKey.reportSubmit),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chặn một người dùng, có hộp xác nhận nêu rõ hậu quả. Trả về true nếu đã chặn.
Future<bool> blockUserFlow(
  BuildContext context, {
  required String userId,
  required String name,
}) {
  return _confirmAction(context, userId: userId, name: name, block: true);
}

// Bỏ chặn một người dùng, có hộp xác nhận ngắn. Trả về true nếu đã bỏ chặn.
Future<bool> unblockUserFlow(
  BuildContext context, {
  required String userId,
  required String name,
}) {
  return _confirmAction(context, userId: userId, name: name, block: false);
}

Future<bool> _confirmAction(
  BuildContext context, {
  required String userId,
  required String name,
  required bool block,
}) async {
  final app = AppScope.of(context, listen: false);
  final me = app.currentUser;
  if (me == null) {
    await showLoginSheet(context);
    return false;
  }
  if (userId == me.id) return false; // không chặn chính mình
  final messenger = ScaffoldMessenger.of(context);
  final t = context.strings;
  final done = await showDialog<bool>(
    context: context,
    builder: (_) => _BlockDialog(userId: userId, name: name, block: block),
  );
  if (done != true) return false;
  _toast(
    messenger,
    t.fill(block ? StrKey.blockDone : StrKey.unblockDone, {'name': name}),
  );
  return true;
}

// Hộp xác nhận chặn/bỏ chặn. Nút xác nhận có vòng xoay khi đang gửi và khoá cả hai nút.
class _BlockDialog extends StatefulWidget {
  const _BlockDialog({
    required this.userId,
    required this.name,
    required this.block,
  });

  final String userId;
  final String name;
  final bool block;

  @override
  State<_BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends State<_BlockDialog> {
  var _busy = false;
  String? _error;

  Future<void> _confirm() async {
    if (_busy) return;
    final app = AppScope.of(context, listen: false);
    final t = context.strings;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.block) {
        await app.blockUser(widget.userId);
      } else {
        await app.unblockUser(widget.userId);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = t(StrKey.blockFailed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final block = widget.block;
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        t.fill(block ? StrKey.blockTitle : StrKey.unblockTitle, {
          'name': widget.name,
        }),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t(block ? StrKey.blockBody : StrKey.unblockBody)),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(t(StrKey.dialogCancel)),
        ),
        FilledButton(
          onPressed: _busy ? null : _confirm,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(t(block ? StrKey.blockConfirm : StrKey.unblockConfirm)),
        ),
      ],
    );
  }
}
