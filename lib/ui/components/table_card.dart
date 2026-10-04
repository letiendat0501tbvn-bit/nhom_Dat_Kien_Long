import 'package:flutter/material.dart';

import '../../data/logic/table_rules.dart';
import '../../data/models/dining_table.dart';
import '../../data/models/dish.dart';
import '../../data/models/restaurant.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../theme/app_theme.dart';
import 'dish_image.dart';

// Thẻ một bàn ăn: món, quán, giờ hẹn (theo ngôn ngữ), chỗ còn/tổng, vài ảnh đại diện
// thành viên (placeholder, ẩn danh) và nút Tham gia / Đã đầy / Đã tham gia.
// Thẻ chỉ hiển thị; việc tham gia do nơi dùng xử lý qua onJoin.
class TableCard extends StatelessWidget {
  const TableCard({
    super.key,
    required this.table,
    required this.dish,
    required this.restaurant,
    required this.joinState,
    required this.onJoin,
    this.onOpen,
    this.joining = false,
    this.statusLabel,
  });

  final DiningTable table;
  final Dish? dish; // null nếu bàn chưa chọn món
  final Restaurant? restaurant;
  final TableJoinState joinState;
  final VoidCallback onJoin;
  final VoidCallback? onOpen; // bấm cả thẻ để xem chi tiết bàn
  final bool joining; // đang gửi yêu cầu tham gia
  // Nếu có: thay nút Tham gia bằng nhãn trạng thái (bàn đã qua: Đã huỷ, Đã kết thúc...).
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final today = context.appState.today;
    final muted = TextStyle(
      fontSize: 14,
      color: AppColors.text.withValues(alpha: 0.7),
    );
    final day = DateTime(
      table.startAt.year,
      table.startAt.month,
      table.startAt.day,
    );
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0x1F000000)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 72, child: _image()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dish?.name ?? t(StrKey.noDishChosen),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Tên quán là dữ liệu, không dịch
                        _IconText(
                          icon: Icons.storefront_outlined,
                          text: restaurant?.name ?? '',
                          style: muted,
                        ),
                        const SizedBox(height: 2),
                        _IconText(
                          icon: Icons.schedule,
                          text:
                              '${t.timeRange(table.startAt, table.durationMin)} · ${t.dayLabel(day, today)}',
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (table.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  table.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _Avatars(memberIds: table.memberIds),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.seatsLabel(table.seatsLeft, table.capacity),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: table.isFull
                            ? AppColors.text.withValues(alpha: 0.6)
                            : AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: _joinButton(t),
                  ),
                ],
              ),
              if (joinState == TableJoinState.joined &&
                  onOpen != null &&
                  statusLabel == null) ...[
                const SizedBox(height: 8),
                Text(
                  t(StrKey.tdJoinedHint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted.copyWith(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Ảnh món (placeholder); bàn chưa chọn món thì dùng ô trống có biểu tượng quán.
  Widget _image() {
    final d = dish;
    if (d == null) {
      return AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.selectedBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.restaurant, color: AppColors.primary),
        ),
      );
    }
    return DishImage(
      dish: d,
      aspectRatio: 1,
      radius: 16,
      emojiSize: 34,
      excludeFromSemantics: true, // tên món đã có ngay bên cạnh
    );
  }

  Widget _joinButton(Strings t) {
    const height = 44.0;
    final status = statusLabel;
    if (status != null) {
      return _disabledButton(status, height, AppColors.text);
    }
    switch (joinState) {
      case TableJoinState.canJoin:
        return SizedBox(
          height: height,
          child: FilledButton(
            onPressed: joining ? null : onJoin,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: joining
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : _label(t(StrKey.joinTable)),
          ),
        );
      case TableJoinState.full:
        return _disabledButton(t(StrKey.tableFull), height, AppColors.text);
      case TableJoinState.joined:
        return _disabledButton(
          t(StrKey.tableJoined),
          height,
          AppColors.primary,
        );
    }
  }

  // Nút không bấm được (Đã đầy / Đã tham gia).
  Widget _disabledButton(String text, double height, Color color) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: color.withValues(alpha: 0.75),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: _label(text),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
  );
}

// Một dòng: biểu tượng nhỏ + chữ (cắt bằng "…" nếu dài).
class _IconText extends StatelessWidget {
  const _IconText({
    required this.icon,
    required this.text,
    required this.style,
  });

  final IconData icon;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.text.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

// Vài ảnh đại diện thành viên chồng lên nhau (placeholder, không lộ danh tính:
// khách chưa đăng nhập không được xem thành viên). Quá 3 người thì có "+N".
class _Avatars extends StatelessWidget {
  const _Avatars({required this.memberIds});

  final List<String> memberIds;

  static const _shown = 3;
  static const _size = 26.0;
  static const _overlap = 16.0;
  static const _tints = [0xFFF3D9C4, 0xFFDDEBD2, 0xFFEADFCB, 0xFFF1CFC6];

  @override
  Widget build(BuildContext context) {
    final count = memberIds.length;
    final visible = count < _shown ? count : _shown;
    final extra = count - visible;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: visible == 0 ? 0 : _size + (visible - 1) * _overlap,
            height: _size,
            child: Stack(
              children: [
                for (var i = 0; i < visible; i++)
                  Positioned(
                    left: i * _overlap,
                    child: Container(
                      width: _size,
                      height: _size,
                      decoration: BoxDecoration(
                        color: Color(
                          _tints[memberIds[i].hashCode.abs() % _tints.length],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 16,
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (extra > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '+$extra',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
