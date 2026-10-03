import 'package:flutter/material.dart';

import '../../data/models/dish.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../components/area_sheet.dart';
import '../components/dish_image.dart';
import '../components/section_heading.dart';
import '../components/table_filters.dart';
import '../components/table_list.dart';
import '../theme/app_theme.dart';
import 'create_table_screen.dart';

// Chi tiết món (mục 4.2 SPEC; chưa có ảnh thiết kế, dựng theo phong cách các màn khác).
// Trên: ảnh, tên, danh mục, mô tả, vùng/hashtag, khẩu vị và tâm trạng.
// Dưới: "Bàn ăn cho món này" lọc theo món + khu vực/bộ lọc trong AppState.
// scrollToTables: mở từ nút "Tìm bàn ăn" thì tự cuộn tới phần bàn ăn.
class DishDetailScreen extends StatefulWidget {
  const DishDetailScreen({
    super.key,
    required this.dish,
    this.scrollToTables = false,
  });

  final Dish dish;
  final bool scrollToTables;

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  final _tablesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.scrollToTables) {
      // Đợi khung hình đầu tiên dựng xong mới biết vị trí phần bàn ăn
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _tablesKey.currentContext;
        if (!mounted || target == null) return;
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final app = context.appState;
    final dish = widget.dish;
    final region = dish.region;
    final hashtag = dish.hashtag;
    return Scaffold(
      appBar: AppBar(title: Text(dish.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DishImage(dish: dish, radius: 28, emojiSize: 96),
            const SizedBox(height: 16),
            Text(
              dish.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              t.categoryLabel(dish.category),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            if (region != null || hashtag != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (region != null)
                    _Tag(
                      text: t.regionLabel(region),
                      icon: Icons.place_outlined,
                    ),
                  // Hashtag là dữ liệu, không dịch
                  if (hashtag != null)
                    Text(
                      hashtag,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              dish.description,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            if (dish.tastes.isNotEmpty) ...[
              const SizedBox(height: 18),
              _TagGroup(
                title: t(StrKey.dishTastes),
                tags: [for (final x in dish.tastes) t.tasteLabel(x)],
                filled: true,
              ),
            ],
            if (dish.moods.isNotEmpty) ...[
              const SizedBox(height: 14),
              _TagGroup(
                title: t(StrKey.dishMoods),
                tags: [for (final x in dish.moods) t.moodLabel(x)],
                filled: false,
              ),
            ],
            const SizedBox(height: 32),
            // Phần bàn ăn: key để cuộn tới khi bấm "Tìm bàn ăn"
            Container(
              key: _tablesKey,
              child: SectionHeading(
                title: t(StrKey.dishTablesTitle),
                subtitle: t(StrKey.dishTablesSubtitle),
              ),
            ),
            const SizedBox(height: 16),
            if (app.selectedAreaId == null)
              AreaCard(onPressed: () => showAreaSheet(context))
            else ...[
              FilterSummaryCard(area: app.selectedArea),
              const SizedBox(height: 12),
              const DayTabs(),
              const SizedBox(height: 12),
              TableList(
                dishId: dish.id,
                onOpenTable: () => openCreateTable(context, dish: dish),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Một nhóm thẻ nhỏ có nhãn (khẩu vị, tâm trạng).
class _TagGroup extends StatelessWidget {
  const _TagGroup({
    required this.title,
    required this.tags,
    required this.filled,
  });

  final String title;
  final List<String> tags;
  final bool filled; // true: nền hồng nhạt; false: viền

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final x in tags) _Tag(text: x, filled: filled)],
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.icon, this.filled = true});

  final String text;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? AppColors.selectedBg : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: filled ? null : Border.all(color: const Color(0x1F000000)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// Mở màn chi tiết món. Dùng chung cho thẻ món ở mọi nơi.
// scrollToTables: true khi bấm "Tìm bàn ăn" (hoặc thẻ ba miền) để cuộn tới phần bàn ăn.
void openDishDetail(
  BuildContext context,
  Dish dish, {
  bool scrollToTables = false,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          DishDetailScreen(dish: dish, scrollToTables: scrollToTables),
    ),
  );
}
