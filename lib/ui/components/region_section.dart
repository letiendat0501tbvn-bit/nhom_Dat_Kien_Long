import 'package:flutter/material.dart';

import '../../data/models/dish.dart';
import '../../data/repositories/dish_repository.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../screens/dish_detail_screen.dart';
import '../theme/app_theme.dart';
import 'dish_image.dart';
import 'section_heading.dart';
import 'status_view.dart';

// Mục "Gói trọn hương vị ba miền" (mục 4.1 SPEC): dải thẻ ngang có vùng và hashtag,
// kèm nút "Khám phá thêm món Việt" (onMore).
class RegionSection extends StatefulWidget {
  // repository: truyền vào khi test; mặc định lấy từ AppState.
  const RegionSection({super.key, this.repository, this.onMore});

  final DishRepository? repository;
  final VoidCallback? onMore;

  @override
  State<RegionSection> createState() => _RegionSectionState();
}

class _RegionSectionState extends State<RegionSection> {
  late final DishRepository _repository =
      widget.repository ?? AppScope.of(context, listen: false).dishRepository;

  var _status = LoadStatus.loading;
  var _dishes = <Dish>[];
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _status = LoadStatus.loading);
    try {
      final dishes = await _repository.getRegionalDishes();
      if (!mounted) return;
      setState(() {
        _dishes = dishes;
        _status = LoadStatus.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = LoadStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          title: t(StrKey.regionsTitle),
          subtitle: t(StrKey.regionsSubtitle),
        ),
        const SizedBox(height: 16),
        StatusView(
          status: _status,
          isEmpty: _dishes.isEmpty,
          onRetry: _load,
          padding: const EdgeInsets.symmetric(vertical: 24),
          builder: (_) => _strip(context),
        ),
        if (widget.onMore != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: widget.onMore,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.arrow_forward, size: 18),
              iconAlignment: IconAlignment.end,
              label: Text(
                t(StrKey.regionsMore),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _strip(BuildContext context) {
    const cardWidth = 240.0;
    final height =
        cardWidth * 3 / 4 + MediaQuery.textScalerOf(context).scale(80);
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _dishes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) => SizedBox(
          width: cardWidth,
          child: _RegionCard(
            dish: _dishes[i],
            onTap: () =>
                openDishDetail(context, _dishes[i], scrollToTables: true),
          ),
        ),
      ),
    );
  }
}

// Thẻ vùng: ảnh món + nhãn vùng ở góc, tên món, hashtag đỏ.
class _RegionCard extends StatelessWidget {
  const _RegionCard({required this.dish, required this.onTap});

  final Dish dish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final region = dish.region;
    final hashtag = dish.hashtag;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DishImage(
              dish: dish,
              excludeFromSemantics: true, // tên món đã có ngay bên dưới
              overlay: region == null
                  ? null
                  : Positioned(
                      top: 8,
                      left: 8,
                      child: ImageLabel(t.regionLabel(region)),
                    ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hashtag != null)
                    Text(
                      hashtag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
