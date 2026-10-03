import 'package:flutter/material.dart';

import '../../data/logic/table_rules.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/dining_table.dart';
import '../../data/models/dish.dart';
import '../../data/models/restaurant.dart';
import '../../data/repositories/table_repository.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../screens/table_detail_screen.dart';
import 'login_sheet.dart';
import 'status_view.dart';
import 'table_card.dart';

// Danh sách bàn theo khu vực và bộ lọc hiện tại của AppState (tableQuery()).
// Tự tải lại khi khu vực/bán kính/buổi ăn/khung giờ/ngày đổi.
// Nút Tham gia: khách thì mở bảng đăng nhập và KHÔNG tự tham gia sau khi đăng nhập;
// thành viên thì gọi repository, báo thành công hoặc đúng lỗi của TableError.
// dishId: chỉ lấy bàn của món này (màn Chi tiết món); khi đó trạng thái rỗng dùng câu
// riêng. Trạng thái rỗng có nút "Mở bàn mới" (hoặc "...với món này") nếu có onOpenTable.
class TableList extends StatefulWidget {
  const TableList({super.key, this.dishId, this.onOpenTable});

  final String? dishId;
  final VoidCallback? onOpenTable;

  @override
  State<TableList> createState() => _TableListState();
}

class _TableListState extends State<TableList> {
  var _status = LoadStatus.loading;
  var _tables = <DiningTable>[];
  var _restaurants = <String, Restaurant>{};
  var _dishes = <String, Dish>{};
  final _joining = <String>{}; // id các bàn đang gửi yêu cầu tham gia
  var _requestId = 0; // bỏ kết quả của lần tải cũ
  var _version = 0; // tablesVersion đã dùng cho lần tải gần nhất
  Object? _queryKey; // bộ lọc đã dùng cho lần tải gần nhất

  // Chỉ lấy những thứ cần so sánh để biết bộ lọc có đổi không.
  Object _keyOf(TableQuery q) => (
    q.areaId,
    q.dishId,
    q.radiusM,
    q.mealTime,
    q.date,
    q.fromMinute,
    q.toMinute,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    final key = _keyOf(app.tableQuery(dishId: widget.dishId));
    if (key != _queryKey) {
      _queryKey = key;
      _version = app.tablesVersion;
      _load();
    } else if (app.tablesVersion != _version) {
      // Dữ liệu bàn đổi ở nơi khác (mở bàn, tham gia, rời, huỷ...): tải lại âm thầm
      _version = app.tablesVersion;
      _load(quiet: true);
    }
  }

  // quiet: tải lại âm thầm (không hiện vòng xoay), dùng sau khi thao tác lỗi.
  Future<void> _load({bool quiet = false}) async {
    final id = ++_requestId;
    if (!quiet) setState(() => _status = LoadStatus.loading);
    try {
      final app = AppScope.of(context, listen: false);
      final query = app.tableQuery(dishId: widget.dishId);
      final (tables, restaurants) = await (
        app.tableRepository.getTables(query),
        app.locationRepository.getRestaurants(areaId: query.areaId),
      ).wait;
      // Chỉ lấy những món có trong các bàn này (AppState đệm theo id)
      final dishes = await app.dishesByIds([
        for (final tb in tables)
          if (tb.dishId != null) tb.dishId!,
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

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _join(DiningTable table) async {
    final app = AppScope.of(context, listen: false);
    final user = app.currentUser;
    if (user == null) {
      // Khách: chỉ mở bảng đăng nhập. Đăng nhập xong không tự tham gia.
      showLoginSheet(context);
      return;
    }
    setState(() => _joining.add(table.id));
    try {
      final updated = await app.tableRepository.joinTable(table.id, user.id);
      if (!mounted) return;
      setState(() {
        // Cập nhật ngay số chỗ trên thẻ
        _tables = [for (final x in _tables) x.id == updated.id ? updated : x];
      });
      _toast(context.strings(StrKey.joinSuccess));
      app.notifyTablesChanged(); // các màn khác (chi tiết bàn...) làm mới theo
    } on TableException catch (e) {
      if (!mounted) return;
      _toast(context.strings.tableError(e.error));
      _load(
        quiet: true,
      ); // trạng thái bàn đã đổi (đầy, huỷ, bắt đầu...): làm mới danh sách
    } catch (_) {
      if (!mounted) return;
      _toast(context.strings(StrKey.joinFailed));
    } finally {
      if (mounted) setState(() => _joining.remove(table.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.appState.currentUser?.id;
    return StatusView(
      status: _status,
      isEmpty: _tables.isEmpty,
      onRetry: _load,
      errorKey: StrKey.tablesError,
      emptyBuilder: _empty,
      builder: (_) => Column(
        children: [
          for (final table in _tables) ...[
            TableCard(
              key: ValueKey(table.id),
              table: table,
              dish: _dishes[table.dishId],
              restaurant: _restaurants[table.restaurantId],
              joinState: joinStateOf(table, userId),
              joining: _joining.contains(table.id),
              onJoin: () => _join(table),
              onOpen: () => openTableDetail(context, table.id),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  // Trạng thái rỗng: câu gợi ý + nút "Xem ngày mai" (hoặc "Xem hôm nay") + nới bán kính.
  Widget _empty(BuildContext context) {
    final t = context.strings;
    final app = context.appState;
    final viewingToday = app.date == app.today;
    final tomorrow = DateTime(
      app.today.year,
      app.today.month,
      app.today.day + 1,
    );
    final widerRadius = radiusOptionsM.where((r) => r > app.radiusM);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            t(
              widget.dishId == null
                  ? StrKey.tablesEmpty
                  : StrKey.dishTablesEmpty,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              // Đang xem hôm nay thì chuyển sang ngày mai; ngược lại quay về hôm nay
              onPressed: () => app.setDate(viewingToday ? tomorrow : null),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const StadiumBorder(),
              ),
              child: Text(
                t(viewingToday ? StrKey.seeTomorrow : StrKey.seeToday),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (widerRadius.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => app.setRadius(widerRadius.first),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  t.widenRadiusLabel(widerRadius.first),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          if (widget.onOpenTable != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: widget.onOpenTable,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  t(
                    widget.dishId == null
                        ? StrKey.openTableNew
                        : StrKey.openTableWithDish,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
