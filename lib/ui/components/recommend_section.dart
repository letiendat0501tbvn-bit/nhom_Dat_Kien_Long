import 'package:flutter/material.dart';

import '../../data/models/dish.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/dish_repository.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../screens/dish_detail_screen.dart';
import '../theme/app_theme.dart';
import 'dish_card.dart';
import 'option_chips.dart';
import 'pill_tabs.dart';
import 'section_heading.dart';
import 'status_view.dart';

// Mục "Gợi ý cho bạn" (mục 4.1 SPEC): 3 tab Hợp vị / Tâm trạng / Đang hot.
// Hợp vị và Tâm trạng có hàng chip; chọn chip thì lọc món. Đang hot hiện ngay món đang hot.
// Tôn trọng buổi ăn trong bộ lọc chung của AppState.
class RecommendSection extends StatefulWidget {
  // repository: truyền vào khi test; mặc định lấy từ AppState.
  const RecommendSection({super.key, this.repository});

  final DishRepository? repository;

  @override
  State<RecommendSection> createState() => _RecommendSectionState();
}

class _RecommendSectionState extends State<RecommendSection> {
  static const _tasteTab = 0;
  static const _moodTab = 1;
  static const _hotTab = 2;

  late final DishRepository _repository =
      widget.repository ?? AppScope.of(context, listen: false).dishRepository;

  var _tab = _tasteTab;
  Taste? _taste;
  Mood? _mood;
  var _status = LoadStatus.ready;
  var _dishes = <Dish>[];
  var _requestId = 0; // bỏ kết quả của lần gọi cũ
  var _started = false;
  MealTime? _mealTime;

  // Tab Hợp vị / Tâm trạng mà chưa chọn chip thì chưa có gì để lọc: hiện lời nhắc.
  bool get _needsChoice =>
      (_tab == _tasteTab && _taste == null) ||
      (_tab == _moodTab && _mood == null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final meal = AppScope.of(context).mealTime;
    if (!_started || meal != _mealTime) {
      _started = true;
      _mealTime = meal;
      _load();
    }
  }

  Future<void> _load() async {
    final id = ++_requestId;
    if (_needsChoice) {
      setState(() {
        _dishes = [];
        _status = LoadStatus.ready;
      });
      return;
    }
    setState(() => _status = LoadStatus.loading);
    try {
      final dishes = await _repository.getDishes(
        mealTime: _mealTime,
        taste: _tab == _tasteTab ? _taste : null,
        mood: _tab == _moodTab ? _mood : null,
        onlyTrending: _tab == _hotTab,
      );
      if (!mounted || id != _requestId) return;
      setState(() {
        _dishes = dishes;
        _status = LoadStatus.ready;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
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
          title: t(StrKey.suggestTitle),
          subtitle: t(StrKey.suggestSubtitle),
        ),
        const SizedBox(height: 16),
        PillTabs(
          labels: [t(StrKey.tabTaste), t(StrKey.tabMood), t(StrKey.tabHot)],
          selected: _tab,
          onChanged: (i) {
            _tab = i;
            _load();
          },
        ),
        const SizedBox(height: 16),
        if (_tab == _tasteTab)
          OptionChips<Taste>(
            options: [for (final x in Taste.values) (x, t.tasteLabel(x))],
            selected: _taste,
            allowClear: true, // bấm lại chip để bỏ chọn
            onChanged: (v) {
              _taste = v;
              _load();
            },
          )
        else if (_tab == _moodTab)
          OptionChips<Mood>(
            options: [for (final x in Mood.values) (x, t.moodLabel(x))],
            selected: _mood,
            allowClear: true,
            onChanged: (v) {
              _mood = v;
              _load();
            },
          ),
        const SizedBox(height: 16),
        if (_needsChoice)
          Text(
            t(
              _tab == _tasteTab
                  ? StrKey.suggestPickTaste
                  : StrKey.suggestPickMood,
            ),
            style: TextStyle(color: AppColors.text.withValues(alpha: 0.7)),
          )
        else
          StatusView(
            status: _status,
            isEmpty: _dishes.isEmpty,
            onRetry: _load,
            padding: const EdgeInsets.symmetric(vertical: 24),
            builder: (_) => _strip(context),
          ),
      ],
    );
  }

  // Dải ngang thẻ món (dùng lại DishCard).
  Widget _strip(BuildContext context) {
    const cardWidth = 170.0;
    final height =
        cardWidth * 3 / 4 + MediaQuery.textScalerOf(context).scale(100);
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _dishes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) => SizedBox(
          width: cardWidth,
          child: DishCard(
            dish: _dishes[i],
            onTap: () => openDishDetail(context, _dishes[i]),
            onFindTable: () =>
                openDishDetail(context, _dishes[i], scrollToTables: true),
          ),
        ),
      ),
    );
  }
}
