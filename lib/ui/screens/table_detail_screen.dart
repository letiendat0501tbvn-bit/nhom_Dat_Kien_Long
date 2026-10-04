import 'package:flutter/material.dart';

import '../../data/logic/table_rules.dart';
import '../../data/models/dining_table.dart';
import '../../data/models/dish.dart';
import '../../data/models/enums.dart';
import '../../data/models/restaurant.dart';
import '../../data/repositories/table_repository.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../components/dish_image.dart';
import '../components/login_sheet.dart';
import '../components/safety_actions.dart';
import '../components/status_view.dart';
import '../components/table_chat.dart';
import '../theme/app_theme.dart';

// Chi tiết bàn (mục 4.5 SPEC; chưa có ảnh thiết kế, dựng theo phong cách các màn khác).
// Danh sách thành viên chỉ hiện khi đã đăng nhập. Nút theo trạng thái: Tham gia / Rời bàn /
// Huỷ bàn (chỉ chủ bàn) / Đã đầy; bàn đã bắt đầu, huỷ, kết thúc thì không có thao tác.
// Chat của bàn làm ở giai đoạn F: tạm chỉ có một khối ghi chú ngắn.
class TableDetailScreen extends StatefulWidget {
  const TableDetailScreen({super.key, required this.tableId});

  final String tableId;

  @override
  State<TableDetailScreen> createState() => _TableDetailScreenState();
}

// Thao tác đang gửi (để hiện vòng xoay đúng nút và khoá các nút còn lại).
enum _Busy { none, join, leave, cancel }

class _TableDetailScreenState extends State<TableDetailScreen> {
  var _status = LoadStatus.loading;
  DiningTable? _table; // null sau khi tải xong nghĩa là bàn không còn tồn tại
  Restaurant? _restaurant;
  Dish? _dish;
  var _names =
      <String, String>{}; // id thành viên -> tên (chỉ khi đã đăng nhập)
  var _blockedIds = <String>{}; // người mà mình đã chặn (chỉ khi đã đăng nhập)
  var _busy = _Busy.none;
  var _requestId = 0;
  Object? _key; // (tablesVersion, userId) của lần tải gần nhất

  // Tải lại khi dữ liệu bàn đổi ở nơi khác (tablesVersion) hoặc khi đăng nhập/đăng xuất.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    final key = (app.tablesVersion, app.currentUser?.id);
    if (key == _key) return;
    // Chỉ lần đầu mới hiện vòng xoay; các lần sau tải âm thầm
    final first = _key == null;
    _key = key;
    _load(quiet: !first);
  }

  Future<void> _load({bool quiet = false}) async {
    final id = ++_requestId;
    if (!quiet) setState(() => _status = LoadStatus.loading);
    try {
      final app = AppScope.of(context, listen: false);
      final table = await app.tableRepository.getTable(widget.tableId);
      Restaurant? restaurant;
      Dish? dish;
      var names = <String, String>{};
      var blocked = <String>{};
      if (table != null) {
        final restaurants = await app.locationRepository.getRestaurants();
        for (final r in restaurants) {
          if (r.id == table.restaurantId) restaurant = r;
        }
        if (table.dishId != null) {
          dish = (await app.dishesByIds([table.dishId!]))[table.dishId];
        }
        // Khách không được xem thành viên nên không tra tên
        if (app.currentUser != null) {
          final users = await Future.wait(
            table.memberIds.map(app.authRepository.getUser),
          );
          names = {
            for (var i = 0; i < users.length; i++)
              if (users[i] != null) table.memberIds[i]: users[i]!.displayName,
          };
          blocked = {
            for (final b in await app.safetyRepository.getBlocks(
              app.currentUser!.id,
            ))
              b.blockedUserId,
          };
        }
      }
      if (!mounted || id != _requestId) return;
      setState(() {
        _table = table;
        _restaurant = restaurant;
        _dish = dish;
        _names = names;
        _blockedIds = blocked;
        _status = LoadStatus.ready;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      if (quiet) return; // tải lại âm thầm hỏng thì giữ nguyên nội dung cũ
      setState(() => _status = LoadStatus.error);
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _nameOf(String id) =>
      _names[id] ?? context.strings(StrKey.tdUnknownUser);

  // Chạy một thao tác với repository, xử lý chung: vòng xoay, lỗi riêng từng TableError,
  // rồi báo các màn khác làm mới danh sách bàn.
  Future<void> _run(
    _Busy kind,
    Future<DiningTable> Function() action,
    String Function(DiningTable) successText,
  ) async {
    if (_busy != _Busy.none) return; // chặn bấm đúp
    final app = AppScope.of(context, listen: false);
    setState(() => _busy = kind);
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() => _table = updated);
      _toast(successText(updated));
    } on TableException catch (e) {
      if (!mounted) return;
      _toast(context.strings.tableError(e.error));
    } catch (_) {
      if (!mounted) return;
      _toast(context.strings(StrKey.tdActionFailed));
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
      // Dù thành công hay lỗi, trạng thái bàn có thể đã đổi: làm mới mọi nơi
      app.notifyTablesChanged();
    }
  }

  void _join() {
    final app = AppScope.of(context, listen: false);
    final user = app.currentUser;
    if (user == null) {
      // Khách: chỉ mở bảng đăng nhập, đăng nhập xong không tự tham gia
      showLoginSheet(context);
      return;
    }
    _run(
      _Busy.join,
      () => app.tableRepository.joinTable(widget.tableId, user.id),
      (_) => context.strings(StrKey.joinSuccess),
    );
  }

  Future<void> _leave() async {
    final app = AppScope.of(context, listen: false);
    final user = app.currentUser;
    final table = _table;
    if (user == null || table == null) return;
    final t = context.strings;
    final isHost = table.hostId == user.id;
    final alone = table.memberIds.length <= 1;
    // Hộp xác nhận nói rõ hậu quả: chủ bàn rời thì chuyển quyền hoặc huỷ bàn
    final body = !isHost
        ? t(StrKey.tdLeaveBody)
        : alone
        ? t(StrKey.tdLeaveAloneBody)
        : t.fill(StrKey.tdLeaveHostBody, {'name': _nameOf(table.memberIds[1])});
    final ok = await _confirm(
      title: t(StrKey.tdLeaveTitle),
      body: body,
      keep: t(StrKey.tdLeaveStay),
      confirm: t(StrKey.tdLeave),
    );
    if (ok != true || !mounted) return;
    _run(
      _Busy.leave,
      () => app.tableRepository.leaveTable(widget.tableId, user.id),
      (updated) {
        final s = context.strings;
        if (updated.status == TableStatus.cancelled) {
          return s(StrKey.tdLeftCancelled);
        }
        if (isHost) {
          return s.fill(StrKey.tdLeftHost, {'name': _nameOf(updated.hostId)});
        }
        return s(StrKey.tdLeft);
      },
    );
  }

  Future<void> _cancel() async {
    final app = AppScope.of(context, listen: false);
    final user = app.currentUser;
    final table = _table;
    if (user == null || table == null) return;
    final t = context.strings;
    final others = table.memberIds.length - 1;
    final ok = await _confirm(
      title: t(StrKey.tdCancelTitle),
      body: others > 0
          ? t.fill(StrKey.tdCancelBodyOthers, {'n': others})
          : t(StrKey.tdCancelBody),
      keep: t(StrKey.tdCancelKeep),
      confirm: t(StrKey.tdCancel),
    );
    if (ok != true || !mounted) return;
    _run(
      _Busy.cancel,
      () => app.tableRepository.cancelTable(widget.tableId, user.id),
      (_) => context.strings(StrKey.tdCancelled),
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String keep,
    required String confirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(keep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final table = _table;
    final actions = table == null
        ? const TableActions()
        : tableActionsOf(
            table,
            context.appState.currentUser?.id,
            context.appState.now(),
          );
    return Scaffold(
      appBar: AppBar(
        title: Text(t(StrKey.tdTitle)),
        actions: [
          // Menu "⋯": báo cáo bàn (chủ bàn không báo cáo bàn của chính mình)
          if (table != null && table.hostId != context.appState.currentUser?.id)
            PopupMenuButton<String>(
              tooltip: t(StrKey.tdMore),
              icon: const Icon(Icons.more_horiz),
              onSelected: (_) => reportTarget(
                context,
                type: ReportTargetType.table,
                targetId: table.id,
                title: t(StrKey.tdReportTable),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'report',
                  child: Text(t(StrKey.tdReportTable)),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: StatusView(
                  status: _status,
                  isEmpty: table == null,
                  onRetry: _load,
                  errorKey: StrKey.tablesError,
                  emptyKey: StrKey.tdNotFound,
                  builder: (_) => _content(t, table!),
                ),
              ),
            ),
            if (table != null && !actions.none) _actionBar(t, actions),
          ],
        ),
      ),
    );
  }

  Widget _content(Strings t, DiningTable table) {
    final app = context.appState;
    final user = app.currentUser;
    final muted = TextStyle(
      fontSize: 15,
      color: AppColors.text.withValues(alpha: 0.75),
    );
    final start = table.startAt;
    final day = DateTime(start.year, start.month, start.day);
    final status = displayStatusOf(table, app.now());
    final restaurant = _restaurant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Đầu trang: món + trạng thái
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 88, child: _image()),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dish?.name ?? t(StrKey.noDishChosen),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusChip(
                    status: status,
                    label: t.tableStatusLabel(status),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            children: [
              // Tên và địa chỉ quán là dữ liệu, không dịch
              _InfoRow(
                icon: Icons.storefront_outlined,
                title: restaurant?.name ?? '',
                subtitle: restaurant?.address,
              ),
              _InfoRow(
                icon: Icons.schedule,
                title: t.timeRange(start, table.durationMin),
                subtitle: t.dayLabel(day, app.today),
              ),
              _InfoRow(
                icon: Icons.timer_outlined,
                title: t.minutesLabel(table.durationMin),
              ),
              _InfoRow(
                icon: Icons.event_seat_outlined,
                title: t.seatsLabel(table.seatsLeft, table.capacity),
                last: true,
              ),
            ],
          ),
        ),
        if (table.note.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(StrKey.tdNote),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: Text(table.note, style: muted),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _members(t, table, user?.id),
        ..._chat(t, table, user?.id, muted),
        const SizedBox(height: 16),
      ],
    );
  }

  // Khối trò chuyện theo quyền: thành viên xem/gửi (hoặc chỉ xem), người khác chỉ thấy
  // lời mời tham gia; bàn đã huỷ hoặc không còn nhận người thì không hiện gì.
  List<Widget> _chat(
    Strings t,
    DiningTable table,
    String? userId,
    TextStyle muted,
  ) {
    final access = chatAccessOf(table, userId, context.appState.now());
    if (access == ChatAccess.none) return const [];
    return [
      const SizedBox(height: 20),
      Text(
        t(StrKey.tdChatTitle),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      if (access == ChatAccess.joinToChat)
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t(StrKey.chatJoinToChat), style: muted),
              if (userId == null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 46,
                  child: FilledButton(
                    onPressed: () => showLoginSheet(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      t(StrKey.signIn),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        )
      else
        TableChat(
          // Rời bàn thì widget này bị gỡ: mất quyền xem ngay
          // Chặn/bỏ chặn ai đó thì dựng lại để tải lại tin nhắn đã lọc
          key: ValueKey('chat-${table.id}-${context.appState.blocksVersion}'),
          tableId: table.id,
          userId: userId!,
          readOnly: access == ChatAccess.readOnly,
          nameOf: _nameOf,
        ),
    ];
  }

  Widget _image() {
    final d = _dish;
    if (d == null) {
      return AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.selectedBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.restaurant, color: AppColors.primary),
        ),
      );
    }
    return DishImage(dish: d, aspectRatio: 1, radius: 20, emojiSize: 40);
  }

  // Khối thành viên: khách thì chỉ thấy lời mời đăng nhập, không lộ danh tính.
  Widget _members(Strings t, DiningTable table, String? userId) {
    if (userId == null) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t(StrKey.tdMembersGuest),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: FilledButton(
                onPressed: () => showLoginSheet(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  t(StrKey.signIn),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.fill(StrKey.tdMembers, {
            'n': table.memberIds.length,
            'total': table.capacity,
          }),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _Card(
          child: Column(
            children: [
              for (final id in table.memberIds)
                _MemberRow(
                  key: ValueKey('member-$id'),
                  name: _nameOf(id),
                  isHost: id == table.hostId,
                  hostLabel: t(StrKey.tdHostBadge),
                  blocked: _blockedIds.contains(id),
                  blockedLabel: t(StrKey.tdBlockedBadge),
                  // Không có menu cho chính mình (không tự chặn/báo cáo)
                  menu: id == userId ? null : _memberMenu(t, id),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Menu "⋯" của một thành viên khác: chặn/bỏ chặn và báo cáo người dùng.
  Widget _memberMenu(Strings t, String id) {
    final blocked = _blockedIds.contains(id);
    final name = _nameOf(id);
    return PopupMenuButton<String>(
      tooltip: '${t(StrKey.tdMore)}: $name',
      icon: const Icon(Icons.more_horiz),
      onSelected: (v) {
        if (v == 'block') {
          blockUserFlow(context, userId: id, name: name);
        } else if (v == 'unblock') {
          unblockUserFlow(context, userId: id, name: name);
        } else {
          reportTarget(
            context,
            type: ReportTargetType.user,
            targetId: id,
            title: t(StrKey.tdReportUser),
          );
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: blocked ? 'unblock' : 'block',
          child: Text(t(blocked ? StrKey.tdUnblockUser : StrKey.tdBlockUser)),
        ),
        PopupMenuItem(value: 'report', child: Text(t(StrKey.tdReportUser))),
      ],
    );
  }

  // Thanh nút cố định ở đáy: một nút chính + (nếu là chủ bàn) nút Huỷ bàn.
  Widget _actionBar(Strings t, TableActions a) {
    final busy = _busy != _Busy.none;
    final buttons = <Widget>[];
    if (a.canJoin) {
      buttons.add(
        _BarButton(
          label: t(StrKey.joinTable),
          loading: _busy == _Busy.join,
          onPressed: busy ? null : _join,
          filled: true,
        ),
      );
    }
    if (a.showFull) {
      buttons.add(
        _BarButton(label: t(StrKey.tableFull), loading: false, onPressed: null),
      );
    }
    if (a.canLeave) {
      buttons.add(
        _BarButton(
          label: t(StrKey.tdLeave),
          loading: _busy == _Busy.leave,
          onPressed: busy ? null : _leave,
        ),
      );
    }
    if (a.canCancel) {
      buttons.add(
        _BarButton(
          label: t(StrKey.tdCancel),
          loading: _busy == _Busy.cancel,
          onPressed: busy ? null : _cancel,
          filled: true,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x1F000000))),
      ),
      child: Row(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: buttons[i]),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1F000000)),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(icon, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.label});

  final TableDisplayStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Sắp diễn ra: màu nhấn; các trạng thái còn lại: xám
    final active = status == TableDisplayStatus.upcoming;
    final color = active ? AppColors.primary : AppColors.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? AppColors.selectedBg
            : AppColors.text.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color.withValues(alpha: active ? 1 : 0.75),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    super.key,
    required this.name,
    required this.isHost,
    required this.hostLabel,
    this.blocked = false,
    this.blockedLabel = '',
    this.menu,
  });

  final String name;
  final bool isHost;
  final String hostLabel;
  final bool blocked; // mình đã chặn người này
  final String blockedLabel;
  final Widget? menu; // menu "⋯" (null: chính mình)

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 18,
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
          if (isHost) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.selectedBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                hostLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          if (blocked) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.text.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                blockedLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
          ?menu,
        ],
      ),
    );
  }
}

// Nút ở thanh đáy. filled: nút đỏ đặc; ngược lại nút viền. onPressed null: bị khoá.
class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: filled ? Colors.white : AppColors.primary,
            ),
          )
        : Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          );
    return SizedBox(
      height: 50,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const StadiumBorder(),
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: onPressed == null
                      ? const Color(0x1F000000)
                      : AppColors.primary,
                ),
                shape: const StadiumBorder(),
              ),
              child: child,
            ),
    );
  }
}

// Mở màn Chi tiết bàn của một bàn.
Future<void> openTableDetail(BuildContext context, String tableId) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => TableDetailScreen(tableId: tableId),
    ),
  );
}
