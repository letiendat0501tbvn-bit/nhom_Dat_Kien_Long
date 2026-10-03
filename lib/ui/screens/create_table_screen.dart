import 'package:flutter/material.dart';

import '../../data/logic/table_rules.dart';
import '../../data/models/dining_table.dart';
import '../../data/models/dish.dart';
import '../../data/models/restaurant.dart';
import '../../data/repositories/table_repository.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../components/area_sheet.dart';
import '../components/login_sheet.dart';
import '../components/option_chips.dart';
import '../components/status_view.dart';
import '../components/table_filters.dart';
import '../theme/app_theme.dart';
import '../components/new_table_fields.dart';

// Màn "Mở bàn mới" (mục 4.4 và 7 SPEC; chưa có ảnh thiết kế). Màn toàn trang, không phải tab.
// Hai bước trong cùng một màn: form (món, quán, ngày giờ, thời lượng, số chỗ, ghi chú)
// rồi màn xác nhận tóm tắt. Khách điền được; chỉ khi bấm "Mở bàn" mới hiện bảng đăng nhập
// và dữ liệu đã điền được giữ nguyên. Đăng nhập xong KHÔNG tự mở bàn.
class CreateTableScreen extends StatefulWidget {
  const CreateTableScreen({super.key, this.initialDish});

  final Dish?
  initialDish; // món được chọn sẵn (từ nút "Mở bàn mới với món này")

  @override
  State<CreateTableScreen> createState() => _CreateTableScreenState();
}

class _CreateTableScreenState extends State<CreateTableScreen> {
  late Dish? _dish = widget.initialDish;
  Restaurant? _restaurant;
  DateTime? _date; // chỉ phần ngày; null cho tới khi biết "hôm nay"
  int? _minute; // giờ bắt đầu, phút trong ngày
  var _duration = 60;
  var _capacity = 4;
  final _note = TextEditingController();

  var _confirming = false;
  var _checking = false; // đang kiểm tra trùng giờ khi bấm "Xem lại"
  var _submitting = false; // đang gửi yêu cầu mở bàn (chặn bấm đúp)
  var _submitted =
      false; // đã thử "Xem lại" ít nhất một lần: từ đó báo lỗi trực tiếp
  var _overlaps = false; // kết quả kiểm tra trùng giờ gần nhất
  var _issues = <NewTableField, NewTableIssue>{};
  // Lỗi do repository trả về (đã dịch), hiện ở trường tương ứng.
  final _serverErrors = <NewTableField, String>{};

  var _restStatus = LoadStatus.loading;
  var _restaurants = <Restaurant>[];
  String? _loadedAreaId;
  var _restStarted = false;
  var _restRequestId = 0;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    _date ??= app.today;
    final areaId = app.selectedAreaId;
    if (!_restStarted || areaId != _loadedAreaId) {
      _restStarted = true;
      _loadedAreaId = areaId;
      _loadRestaurants();
    }
  }

  Future<void> _loadRestaurants() async {
    final areaId = _loadedAreaId;
    if (areaId == null) return;
    final id = ++_restRequestId;
    setState(() => _restStatus = LoadStatus.loading);
    try {
      final list = await AppScope.of(
        context,
        listen: false,
      ).locationRepository.getRestaurants(areaId: areaId);
      if (!mounted || id != _restRequestId) return;
      setState(() {
        _restaurants = list;
        _restStatus = LoadStatus.ready;
        // Đổi khu vực thì quán đã chọn ở khu vực cũ không còn hợp lệ
        if (_restaurant != null && !list.any((r) => r.id == _restaurant!.id)) {
          _restaurant = null;
        }
      });
    } catch (_) {
      if (!mounted || id != _restRequestId) return;
      setState(() => _restStatus = LoadStatus.error);
    }
  }

  // Giờ bắt đầu đầy đủ (ngày + giờ), giờ Việt Nam; null nếu chưa chọn giờ.
  DateTime? get _startAt {
    final d = _date, m = _minute;
    if (d == null || m == null) return null;
    return DateTime(d.year, d.month, d.day, m ~/ 60, m % 60);
  }

  Map<NewTableField, NewTableIssue> _validate() {
    final app = AppScope.of(context, listen: false);
    return validateNewTableForm(
      now: app.now(),
      restaurantId: _restaurant?.id,
      startAt: _startAt,
      durationMin: _duration,
      capacity: _capacity,
      note: _note.text,
      overlaps: _overlaps,
    );
  }

  // Mỗi lần người dùng sửa: xoá lỗi của server; nếu đã thử "Xem lại" thì kiểm tra lại ngay.
  void _edit(VoidCallback change, {bool resetsOverlap = false}) {
    setState(() {
      change();
      _serverErrors.clear();
      if (resetsOverlap) _overlaps = false;
      if (_submitted) _issues = _validate();
    });
  }

  // Lỗi hiện ở một trường: lỗi của server trước, rồi lỗi kiểm tra của form.
  String? _errorOf(NewTableField field, Strings t) {
    final server = _serverErrors[field];
    if (server != null) return server;
    final issue = _issues[field];
    return issue == null ? null : t.newTableIssue(issue);
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // Bàn dự kiến, chỉ để dùng hasOverlap.
  DiningTable _prospective(String userId, DateTime startAt) => DiningTable(
    id: 'new',
    restaurantId: _restaurant?.id ?? '',
    hostId: userId,
    startAt: startAt,
    durationMin: _duration,
    capacity: _capacity,
    memberIds: [userId],
  );

  // "Xem lại": kiểm tra form (và trùng giờ nếu đã đăng nhập) rồi sang màn xác nhận.
  Future<void> _review() async {
    if (_checking) return;
    final app = AppScope.of(context, listen: false);
    final user = app.currentUser;
    final startAt = _startAt;
    setState(() {
      _submitted = true;
      _checking = true;
      _serverErrors.clear();
    });
    var overlaps = false;
    if (user != null && startAt != null && startAt.isAfter(app.now())) {
      try {
        final mine = await app.tableRepository.getMyTables(user.id);
        overlaps = hasOverlap(mine, user.id, _prospective(user.id, startAt));
      } catch (_) {
        // Không kiểm tra được thì để repository kiểm tra lại khi mở bàn
      }
      if (!mounted) return;
    }
    _overlaps = overlaps;
    final issues = _validate();
    setState(() {
      _checking = false;
      _issues = issues;
      _confirming = issues.isEmpty;
    });
  }

  // "Mở bàn": khách thì mở bảng đăng nhập (giữ nguyên dữ liệu), thành viên thì gửi yêu cầu.
  Future<void> _submit() async {
    if (_submitting) return;
    final app = AppScope.of(context, listen: false);
    final user = app.currentUser;
    if (user == null) {
      showLoginSheet(context);
      return;
    }
    final restaurant = _restaurant, startAt = _startAt;
    if (restaurant == null || startAt == null) return;
    setState(() => _submitting = true);
    try {
      await app.tableRepository.createTable(
        hostId: user.id,
        dishId: _dish?.id,
        restaurantId: restaurant.id,
        startAt: startAt,
        durationMin: _duration,
        capacity: _capacity,
        note: _note.text.trim(),
      );
      app.notifyTablesChanged(); // danh sách bàn ở nơi mở màn tự làm mới
      if (!mounted) return;
      _toast(context.strings(StrKey.tableCreated));
      Navigator.of(context).pop(true);
    } on TableException catch (e) {
      if (!mounted) return;
      final t = context.strings;
      final field = switch (e.error) {
        TableError.invalidTime || TableError.overlap => NewTableField.time,
        TableError.invalidCapacity => NewTableField.capacity,
        _ => null,
      };
      if (field == null) {
        _toast(t.tableError(e.error));
      } else {
        // Quay về form để thấy lỗi ngay tại trường
        setState(() {
          _serverErrors[field] = t.tableError(e.error);
          _confirming = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      _toast(context.strings(StrKey.tableCreateFailed));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    // Ở màn xác nhận, nút Back quay về form thay vì đóng màn
    return PopScope(
      canPop: !_confirming,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _confirming) setState(() => _confirming = false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            t(_confirming ? StrKey.ntConfirmTitle : StrKey.newTableTitle),
          ),
        ),
        body: SafeArea(child: _confirming ? _confirmStep(t) : _formStep(t)),
      ),
    );
  }

  // ---------- Bước 1: form ----------

  Widget _formStep(Strings t) {
    final app = context.appState;
    final today = app.today;
    final now = app.now();
    final date = _date ?? today;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(StrKey.newTableSubtitle),
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                FormSection(
                  title: t(StrKey.ntDishTitle),
                  child: DishPickerField(
                    dish: _dish,
                    onChanged: (d) => _edit(() => _dish = d),
                  ),
                ),
                FormSection(
                  title: t(StrKey.ntRestaurantTitle),
                  error: _errorOf(NewTableField.restaurant, t),
                  child: _restaurantField(t),
                ),
                FormSection(
                  title: t(StrKey.ntDateTitle),
                  child: OptionChips<DateTime>(
                    options: [
                      for (var i = 0; i < 7; i++)
                        (
                          DateTime(today.year, today.month, today.day + i),
                          t.dayLabel(
                            DateTime(today.year, today.month, today.day + i),
                            today,
                          ),
                        ),
                    ],
                    selected: date,
                    onChanged: (v) =>
                        _edit(() => _date = v ?? date, resetsOverlap: true),
                  ),
                ),
                FormSection(
                  title: t(StrKey.ntTimeTitle),
                  note: t(StrKey.ntTimeNote),
                  error: _errorOf(NewTableField.time, t),
                  child: TimeSlotPicker(
                    date: date,
                    now: now,
                    selected: _minute,
                    language: app.language,
                    onChanged: (m) =>
                        _edit(() => _minute = m, resetsOverlap: true),
                  ),
                ),
                FormSection(
                  title: t(StrKey.ntDurationTitle),
                  error: _errorOf(NewTableField.duration, t),
                  child: OptionChips<int>(
                    options: [
                      for (
                        var m = minDurationMin;
                        m <= maxDurationMin;
                        m += slotMinutes
                      )
                        (m, t.minutesLabel(m)),
                    ],
                    selected: _duration,
                    onChanged: (v) => _edit(
                      () => _duration = v ?? _duration,
                      resetsOverlap: true,
                    ),
                  ),
                ),
                FormSection(
                  title: t(StrKey.ntCapacityTitle),
                  note: t(StrKey.ntCapacityHint),
                  error: _errorOf(NewTableField.capacity, t),
                  child: CapacityStepper(
                    value: _capacity,
                    onChanged: (v) => _edit(() => _capacity = v),
                  ),
                ),
                FormSection(
                  title: t(StrKey.ntNoteTitle),
                  error: _errorOf(NewTableField.note, t),
                  child: TextField(
                    controller: _note,
                    maxLength: maxNoteLength,
                    minLines: 2,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    onChanged: (_) => _edit(() {}),
                    decoration: InputDecoration(
                      hintText: t(StrKey.ntNoteHint),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0x1F000000)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _BottomBar(
          children: [
            Expanded(
              child: _PrimaryButton(
                label: t(StrKey.ntReview),
                loading: _checking,
                onPressed: _checking ? null : _review,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _restaurantField(Strings t) {
    if (context.appState.selectedAreaId == null) {
      return AreaCard(onPressed: () => showAreaSheet(context));
    }
    return StatusView(
      status: _restStatus,
      isEmpty: _restaurants.isEmpty,
      onRetry: _loadRestaurants,
      emptyKey: StrKey.ntRestaurantEmpty,
      errorKey: StrKey.ntRestaurantError,
      padding: const EdgeInsets.symmetric(vertical: 16),
      builder: (_) => Column(
        children: [
          for (final r in _restaurants)
            RestaurantTile(
              key: ValueKey(r.id),
              restaurant: r,
              selected: r.id == _restaurant?.id,
              onTap: () => _edit(() => _restaurant = r),
            ),
        ],
      ),
    );
  }

  // ---------- Bước 2: xác nhận ----------

  Widget _confirmStep(Strings t) {
    final app = context.appState;
    final restaurant = _restaurant!;
    final startAt = _startAt!;
    final today = app.today;
    final day = DateTime(startAt.year, startAt.month, startAt.day);
    final note = _note.text.trim();
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(StrKey.ntConfirmBody),
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x1F000000)),
                  ),
                  child: Column(
                    children: [
                      SummaryRow(
                        label: t(StrKey.ntSumDish),
                        value: _dish?.name ?? t(StrKey.noDishChosen),
                      ),
                      SummaryRow(
                        label: t(StrKey.ntSumVenue),
                        // Tên và địa chỉ quán là dữ liệu, không dịch
                        value: '${restaurant.name}\n${restaurant.address}',
                      ),
                      SummaryRow(
                        label: t(StrKey.ntSumTime),
                        value:
                            '${t.timeRange(startAt, _duration)}\n${t.dayLabel(day, today)}',
                      ),
                      SummaryRow(
                        label: t(StrKey.ntSumDuration),
                        value: t.minutesLabel(_duration),
                      ),
                      SummaryRow(
                        label: t(StrKey.ntSumSeats),
                        value: t.fill(StrKey.ntSeatsWithYou, {'n': _capacity}),
                      ),
                      if (note.isNotEmpty)
                        SummaryRow(label: t(StrKey.ntSumNote), value: note),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _BottomBar(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _confirming = false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    t(StrKey.ntEdit),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PrimaryButton(
                label: t(StrKey.ntOpenTable),
                loading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Thanh nút cố định ở đáy màn.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x1F000000))),
      ),
      child: Row(children: children),
    );
  }
}

// Nút đỏ viên thuốc; loading thì hiện vòng xoay và không bấm được.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: const StadiumBorder(),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

// Mở màn "Mở bàn mới". Trả về true nếu đã mở bàn thành công.
// initialDish: món chọn sẵn (nếu có).
Future<bool?> openCreateTable(BuildContext context, {Dish? dish}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => CreateTableScreen(initialDish: dish),
    ),
  );
}
