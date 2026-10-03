import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../components/area_sheet.dart';
import '../components/dish_picker.dart';
import '../components/table_filters.dart';
import '../components/table_list.dart';
import 'all_dishes_screen.dart';
import '../components/section_heading.dart';

// Màn Bàn ăn (mục 4.3 SPEC): chưa chọn khu vực thì hiện thẻ "Chọn khu vực"; đã chọn thì
// hiện tóm tắt bộ lọc + danh sách bàn. Bên dưới là khối chọn món như màn Khám phá.
class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final app = context.appState;
    final area = app.selectedArea;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: t(StrKey.tablesTitle),
            subtitle: t(StrKey.tablesSubtitle),
          ),
          const SizedBox(height: 16),
          if (app.selectedAreaId == null)
            AreaCard(onPressed: () => showAreaSheet(context))
          else ...[
            FilterSummaryCard(area: area),
            const SizedBox(height: 12),
            const DayTabs(),
            const SizedBox(height: 12),
            const TableList(),
          ],
          const SizedBox(height: 28),
          SectionHeading(
            title: t(StrKey.exploreTitle),
            subtitle: t(StrKey.exploreSubtitle),
          ),
          const SizedBox(height: 16),
          DishPicker(
            maxItems: dishPreviewCount,
            onSeeAll: () => openAllDishes(context),
          ),
        ],
      ),
    );
  }
}
