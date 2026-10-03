import 'package:flutter/material.dart';

import '../../data/models/area.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../theme/app_theme.dart';
import 'area_sheet.dart';
import 'filter_sheet.dart';
import 'pill_tabs.dart';

// Các khối dùng chung cho phần "bàn ăn" ở màn Bàn ăn và màn Chi tiết món.

// Thẻ tóm tắt: khu vực đang chọn + bộ lọc đang dùng, kèm nút đổi khu vực và mở bộ lọc.
class FilterSummaryCard extends StatelessWidget {
  const FilterSummaryCard({super.key, required this.area});

  final Area? area; // null nếu danh sách khu vực chưa nạp xong

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final app = context.appState;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1F000000)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên thành phố và quận là dữ liệu, không dịch
                Text(
                  area?.label ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  t.filterSummary(
                    radiusM: app.radiusM,
                    date: app.date,
                    today: app.today,
                    mealTime: app.mealTime,
                    fromMinute: app.fromMinute,
                    toMinute: app.toMinute,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => showAreaSheet(context),
            child: Text(t(StrKey.changeArea)),
          ),
          IconButton(
            tooltip: t(StrKey.filterTitle),
            onPressed: () => showFilterSheet(context),
            icon: Icon(
              Icons.tune,
              color: app.hasActiveFilters ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

// Chuyển nhanh giữa hôm nay và ngày mai (dùng lại PillTabs). Đang xem ngày khác
// (chọn trong bảng lọc) thì không tab nào được chọn.
class DayTabs extends StatelessWidget {
  const DayTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final app = context.appState;
    final today = app.today;
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final selected = app.date == today ? 0 : (app.date == tomorrow ? 1 : -1);
    return PillTabs(
      labels: [t.dayLabel(today, today), t.dayLabel(tomorrow, today)],
      selected: selected,
      onChanged: (i) => app.setDate(i == 0 ? null : tomorrow),
    );
  }
}

// Thẻ trắng bo góc lớn: biểu tượng ghim, mô tả và nút đỏ "Chọn khu vực".
class AreaCard extends StatelessWidget {
  const AreaCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x1F000000)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.selectedBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(StrKey.chooseArea),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t(StrKey.chooseAreaHint),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      t(StrKey.chooseArea),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
