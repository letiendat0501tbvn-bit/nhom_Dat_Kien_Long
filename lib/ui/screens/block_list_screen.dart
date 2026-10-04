import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../components/safety_actions.dart';
import '../components/status_view.dart';
import '../theme/app_theme.dart';

// "Danh sách chặn" (Hồ sơ > Tài khoản): tên người đã chặn + nút Bỏ chặn (có hộp xác nhận).
// Chưa có ảnh thiết kế; dựng theo phong cách các màn khác.
class BlockListScreen extends StatefulWidget {
  const BlockListScreen({super.key});

  @override
  State<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends State<BlockListScreen> {
  var _status = LoadStatus.loading;
  var _entries = <({String id, String name})>[];
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _status = LoadStatus.loading);
    try {
      final app = AppScope.of(context, listen: false);
      final me = app.currentUser;
      final blocks = me == null
          ? const []
          : await app.safetyRepository.getBlocks(me.id);
      final users = await Future.wait(
        blocks.map((b) => app.authRepository.getUser(b.blockedUserId)),
      );
      if (!mounted) return;
      setState(() {
        _entries = [
          for (var i = 0; i < blocks.length; i++)
            (
              id: blocks[i].blockedUserId,
              name:
                  users[i]?.displayName ??
                  context.strings(StrKey.tdUnknownUser),
            ),
        ];
        _status = LoadStatus.ready;
      });
    } catch (_) {
      if (!mounted) return;
      if (quiet) return;
      setState(() => _status = LoadStatus.error);
    }
  }

  Future<void> _unblock(String id, String name) async {
    final done = await unblockUserFlow(context, userId: id, name: name);
    if (done && mounted) _load(quiet: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(t(StrKey.blockList))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: StatusView(
            status: _status,
            isEmpty: _entries.isEmpty,
            onRetry: _load,
            emptyKey: StrKey.blocksEmpty,
            errorKey: StrKey.blocksError,
            builder: (_) => Column(
              children: [
                for (final e in _entries)
                  _BlockRow(
                    key: ValueKey('block-${e.id}'),
                    name: e.name,
                    label: t(StrKey.unblockConfirm),
                    onUnblock: () => _unblock(e.id, e.name),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockRow extends StatelessWidget {
  const _BlockRow({
    super.key,
    required this.name,
    required this.label,
    required this.onUnblock,
  });

  final String name;
  final String label;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1F000000)),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              backgroundColor: AppColors.selectedBg,
              child: Text(
                initial,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          // Chữ nút "Bỏ chặn" kèm tên để trình đọc màn hình phân biệt các dòng
          Semantics(
            label: '$label: $name',
            excludeSemantics: true,
            button: true,
            child: OutlinedButton(
              onPressed: onUnblock,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: const StadiumBorder(),
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}

// Mở màn "Danh sách chặn".
Future<void> openBlockList(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const BlockListScreen()),
  );
}
