import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../components/dish_picker.dart';
import '../components/section_heading.dart';
import '../theme/app_theme.dart';

// Màn Bàn ăn: thẻ "Chọn khu vực" ở trên, bên dưới là khối chọn món như màn Khám phá.
class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
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
          _AreaCard(
            // Chưa có chức năng chọn khu vực, sẽ làm ở giai đoạn D
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t(StrKey.notBuiltYet))),
            ),
          ),
          const SizedBox(height: 28),
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

// Thẻ trắng bo góc lớn: biểu tượng ghim, mô tả và nút đỏ "Chọn khu vực".
class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.onPressed});

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
            child: const Icon(Icons.location_on_outlined,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(StrKey.chooseArea),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
