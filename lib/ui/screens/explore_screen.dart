import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../components/dish_picker.dart';
import '../components/recommend_section.dart';
import '../components/region_section.dart';
import '../components/section_heading.dart';
import 'all_dishes_screen.dart';

// Màn Khám phá (mục 4.1 SPEC): chọn món (tìm kiếm, lọc, lưới 2 cột, "Xem tất cả"),
// Gợi ý cho bạn, Gói trọn hương vị ba miền.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: t(StrKey.exploreTitle),
            subtitle: t(StrKey.exploreSubtitle),
          ),
          const SizedBox(height: 16),
          DishPicker(
            maxItems: dishPreviewCount,
            onSeeAll: () => openAllDishes(context),
          ),
          const SizedBox(height: 32),
          const RecommendSection(),
          const SizedBox(height: 32),
          RegionSection(onMore: () => openAllDishes(context)),
        ],
      ),
    );
  }
}
