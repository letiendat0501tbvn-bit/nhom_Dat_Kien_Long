import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../components/dish_picker.dart';
import '../components/section_heading.dart';

// Màn Khám phá: tiêu đề + khối chọn món (tìm kiếm, lọc, lưới 2 cột).
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
          const DishPicker(),
        ],
      ),
    );
  }
}
