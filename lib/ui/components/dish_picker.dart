import 'package:flutter/material.dart';

import '../../data/models/dish.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/dish_repository.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../screens/dish_detail_screen.dart';
import '../theme/app_theme.dart';
import 'dish_card.dart';
import 'filter_sheet.dart';
import 'status_view.dart';

// Số món hiện ở màn Khám phá / Bàn ăn trước nút "Xem tất cả".
const dishPreviewCount = 8;

// Khối "ô tìm kiếm + nút lọc + lưới món 2 cột", dùng chung cho màn Khám phá, Bàn ăn
// và màn "Tất cả món ngon". Không tự cuộn: đặt bên trong một widget cuộn của màn cha.
// Tìm kiếm không phân biệt dấu; buổi ăn trong bảng lọc lọc món theo mealTimes.
class DishPicker extends StatefulWidget {
  // repository: truyền vào khi test; mặc định lấy từ AppState.
  // maxItems: chỉ hiện chừng đó món đầu khi chưa gõ tìm kiếm; null = hiện hết.
  // onSeeAll: nếu có và còn món bị ẩn thì hiện nút "Xem tất cả N món ngon".
  const DishPicker({super.key, this.repository, this.maxItems, this.onSeeAll});

  final DishRepository? repository;
  final int? maxItems;
  final VoidCallback? onSeeAll;

  @override
  State<DishPicker> createState() => _DishPickerState();
}

class _DishPickerState extends State<DishPicker> {
  // Chỉ lấy repository, không cần dựng lại khi AppState đổi (listen: false).
  late final DishRepository _repository =
      widget.repository ?? AppScope.of(context, listen: false).dishRepository;
  String _query = '';
  var _status = LoadStatus.loading;
  var _dishes = <Dish>[];
  var _requestId = 0; // bỏ kết quả của lần gọi cũ khi người dùng gõ tiếp
  var _started = false;
  MealTime? _mealTime; // buổi ăn đã dùng cho lần tải gần nhất

  // Tải lần đầu, và tải lại khi buổi ăn trong bộ lọc đổi.
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
    setState(() => _status = LoadStatus.loading);
    try {
      final dishes = await _repository.getDishes(
        query: _query,
        mealTime: _mealTime,
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
        Row(
          children: [
            Expanded(child: _searchBox(t)),
            const SizedBox(width: 10),
            _filterButton(t, active: context.appState.hasActiveFilters),
          ],
        ),
        const SizedBox(height: 16),
        StatusView(
          status: _status,
          isEmpty: _dishes.isEmpty,
          onRetry: _load,
          builder: (_) => _results(t),
        ),
      ],
    );
  }

  // Lưới món (+ nút "Xem tất cả" nếu có giới hạn). Gõ tìm kiếm thì hiện mọi kết quả.
  Widget _results(Strings t) {
    final max = widget.maxItems;
    final limited =
        max != null && _query.trim().isEmpty && _dishes.length > max;
    final shown = limited ? _dishes.take(max) : _dishes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Chiều cao mỗi ô = ảnh 4:3 + phần chữ bên dưới (phần chữ nở theo cỡ chữ hệ thống)
            const gap = 16.0;
            final itemWidth = (constraints.maxWidth - gap) / 2;
            final textHeight = MediaQuery.textScalerOf(context).scale(100);
            final items = shown.toList();
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: gap,
                mainAxisSpacing: 12,
                mainAxisExtent: itemWidth * 3 / 4 + textHeight,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => DishCard(
                dish: items[i],
                // Tạm thời mở chi tiết món (chưa có thiết kế); danh sách bàn theo món làm ở GĐ D
                onTap: () => openDishDetail(context, items[i]),
                onFindTable: () =>
                    openDishDetail(context, items[i], scrollToTables: true),
              ),
            );
          },
        ),
        if (limited && widget.onSeeAll != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: widget.onSeeAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.arrow_forward, size: 18),
              iconAlignment: IconAlignment.end,
              label: Text(
                t.seeAllDishesLabel(_dishes.length),
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

  // Ô tìm kiếm dạng viên thuốc
  Widget _searchBox(Strings t) {
    return TextField(
      onChanged: (v) {
        _query = v;
        _load();
      },
      decoration: InputDecoration(
        hintText: t(StrKey.searchHint),
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: _border(const Color(0x1F000000)),
        focusedBorder: _border(AppColors.primary),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide(color: color),
  );

  // Nút mở bảng "Bộ lọc & giờ ăn". Tô sáng khi đang có bộ lọc khác mặc định.
  Widget _filterButton(Strings t, {required bool active}) {
    return Semantics(
      button: true,
      label: t(StrKey.filterTitle),
      excludeSemantics: true,
      child: Material(
        color: active ? AppColors.selectedBg : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: active ? AppColors.primary : const Color(0x1F000000),
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showFilterSheet(context),
          child: const SizedBox(
            height: 52,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
