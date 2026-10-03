import 'package:flutter/material.dart';

import '../../data/logic/table_rules.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/enums.dart';
import '../../l10n/formatters.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import 'option_chips.dart';

// Bảng "Bộ lọc & giờ ăn" (mục 4.8 SPEC): buổi ăn, bán kính, khung giờ, ngày.
// Người dùng chỉnh trên bản nháp; bấm "Áp dụng" mới ghi vào AppState.
// "Đặt lại" đưa bản nháp về mặc định (chưa áp dụng cho tới khi bấm "Áp dụng").
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final AppState _app = AppScope.of(context, listen: false);

  // Bản nháp của bộ lọc
  late MealTime? _meal = _app.mealTime;
  late int _radius = _app.radiusM;
  late DateTime _date = _app.date;
  late int? _from = _snap(_app.fromMinute);
  late int? _to = _snap(_app.toMinute);

  // Hôm nay, bỏ phần giờ.
  late final DateTime _today = DateTime(
    _app.now().year,
    _app.now().month,
    _app.now().day,
  );

  // Dropdown chỉ có các mốc 15 phút nên làm tròn xuống nếu giá trị đến từ nơi khác.
  static int? _snap(int? minute) =>
      minute == null ? null : minute - minute % slotMinutes;

  void _reset() => setState(() {
    _meal = null;
    _radius = AppState.defaultRadiusM;
    _date = _today;
    _from = null;
    _to = null;
  });

  void _apply() {
    _app.applyFilters(
      mealTime: _meal,
      radiusM: _radius,
      date: _date,
      fromMinute: _from,
      toMinute: _to,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            t(StrKey.filterTitle),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Section(
                  title: t(StrKey.filterMealTime),
                  child: OptionChips<MealTime>(
                    options: [
                      for (final m in MealTime.values) (m, t.mealTimeLabel(m)),
                    ],
                    selected: _meal,
                    allowClear: true, // chọn lại để bỏ chọn
                    onChanged: (v) => setState(() => _meal = v),
                  ),
                ),
                _Section(
                  title: t(StrKey.filterRadius),
                  child: OptionChips<int>(
                    options: [
                      for (final r in radiusOptionsM) (r, formatRadius(r)),
                    ],
                    selected: _radius,
                    onChanged: (v) => setState(() => _radius = v ?? _radius),
                  ),
                ),
                _Section(
                  title: t(StrKey.filterTimeWindow),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _TimeDropdown(
                              label: t(StrKey.filterFrom),
                              anyLabel: t(StrKey.filterAnyTime),
                              value: _from,
                              // "Từ" không được sau "Đến"
                              slots: timeSlots(max: _to ?? 1439),
                              onChanged: (v) => setState(() => _from = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TimeDropdown(
                              label: t(StrKey.filterTo),
                              anyLabel: t(StrKey.filterAnyTime),
                              value: _to,
                              // "Đến" không được trước "Từ"
                              slots: timeSlots(min: _from ?? 0),
                              onChanged: (v) => setState(() => _to = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t(StrKey.filterTimeNote),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: t(StrKey.filterDate),
                  child: OptionChips<DateTime>(
                    // 7 ngày kể từ hôm nay
                    options: [
                      for (var i = 0; i < 7; i++)
                        (
                          DateTime(_today.year, _today.month, _today.day + i),
                          t.dayLabel(
                            DateTime(_today.year, _today.month, _today.day + i),
                            _today,
                          ),
                        ),
                    ],
                    selected: _date,
                    onChanged: (v) => setState(() => _date = v ?? _date),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      t(StrKey.filterReset),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      t(StrKey.filterApply),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Một mục của bảng: tiêu đề nhỏ + nội dung.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// Ô chọn giờ theo bước 15 phút, có lựa chọn "Bất kỳ" (null).
class _TimeDropdown extends StatelessWidget {
  const _TimeDropdown({
    required this.label,
    required this.anyLabel,
    required this.value,
    required this.slots,
    required this.onChanged,
  });

  final String label;
  final String anyLabel;
  final int? value;
  final List<int> slots;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0x1F000000)),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: value,
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(anyLabel)),
            for (final m in slots)
              DropdownMenuItem<int?>(
                value: m,
                child: Text(formatMinuteOfDay(m)),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
