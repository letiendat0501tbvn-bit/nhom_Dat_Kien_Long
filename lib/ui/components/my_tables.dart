import 'package:flutter/material.dart';

import '../../data/logic/table_rules.dart';
import '../../data/models/dining_table.dart';
import '../../data/models/dish.dart';
import '../../data/models/restaurant.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../screens/create_table_screen.dart';
import '../screens/table_detail_screen.dart';
import '../theme/app_theme.dart';
import 'status_view.dart';
import 'table_card.dart';

// Danh sách "Bàn của tôi" (tab Lịch hẹn): bàn đã mở hoặc đã tham gia, chia "Sắp tới"
// và "Đã qua". Tự tải lại âm thầm khi dữ liệu bàn đổi ở nơi khác (tablesVersion).
// Chưa có bàn nào thì hiện câu gợi ý + nút "Mở bàn mới" và "Tìm bàn ăn".
class MyTables extends StatefulWidget {
  const MyTables({super.key, required this.userId, this.onFindTables});

  final String userId;
  final VoidCallback? onFindTables;

  @override
  State<MyTables> createState() => _MyTablesState();
}

class _MyTablesState extends State<MyTables> {
  var _status = LoadStatus.loading;
  var _tables = <DiningTable>[];
  var _restaurants = <String, Restaurant>{};
  var _dishes = <String, Dish>{};
  var _requestId = 0;
  var _version = -1; // tablesVersion đã dùng cho lần tải gần nhất

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final version = AppScope.of(context).tablesVersion;
    if (version == _version) return;
    final first = _version < 0;
    _version = version;
    _load(quiet: !first);
  }

  Future<void> _load({bool quiet = false}) async {
    final id = ++_requestId;
    if (!quiet) setState(() => _status = LoadStatus.loading);
    try {
      final app = AppScope.of(context, listen: false);
      final (tables, restaurants) = await (
        app.tableRepository.getMyTables(widget.userId),
        app.locationRepository.getRestaurants(),
      ).wait;
      final dishes = await app.dishesByIds([
        for (final t in tables)
          if (t.dishId != null) t.dishId!,
      ]);
      if (!mounted || id != _requestId) return;
      setState(() {
        _tables = tables;
        _restaurants = {for (final r in restaurants) r.id: r};
        _dishes = dishes;
        _status = LoadStatus.ready;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      if (quiet) return; // tải lại âm thầm hỏng thì giữ nguyên danh sách cũ
      setState(() => _status = LoadStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusView(
      status: _status,
      isEmpty: _tables.isEmpty,
      onRetry: _load,
      errorKey: StrKey.tablesError,
      emptyBuilder: _empty,
      builder: _list,
    );
  }

  Widget _list(BuildContext context) {
    final t = context.strings;
    final app = context.appState;
    final groups = splitMyTables(_tables, app.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(t(StrKey.myTablesUpcoming)),
        if (groups.upcoming.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              t(StrKey.myTablesNoUpcoming),
              style: TextStyle(
                fontSize: 16,
                color: AppColors.text.withValues(alpha: 0.7),
              ),
            ),
          )
        else
          for (final table in groups.upcoming)
            _card(t, app.now(), table, false),
        if (groups.past.isNotEmpty) ...[
          const SizedBox(height: 8),
          _heading(t(StrKey.myTablesPast)),
          for (final table in groups.past) _card(t, app.now(), table, true),
        ],
      ],
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _card(Strings t, DateTime now, DiningTable table, bool past) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TableCard(
        key: ValueKey(table.id),
        table: table,
        dish: _dishes[table.dishId],
        restaurant: _restaurants[table.restaurantId],
        joinState: joinStateOf(table, widget.userId),
        // Bàn đã qua: nhãn trạng thái (Đã huỷ, Đã kết thúc, Đã bắt đầu) thay cho nút
        statusLabel: past
            ? t.tableStatusLabel(displayStatusOf(table, now))
            : null,
        onJoin: () {}, // đã là thành viên: nút không bấm được
        onOpen: () => openTableDetail(context, table.id),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final t = context.strings;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(StrKey.myTablesEmpty),
            style: TextStyle(
              fontSize: 16,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () => openCreateTable(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const StadiumBorder(),
              ),
              child: Text(
                t(StrKey.openTableNew),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (widget.onFindTables != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: widget.onFindTables,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  t(StrKey.findTable),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
