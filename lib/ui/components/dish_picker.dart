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

// Khối "ô tìm kiếm + nút lọc + lưới món 2 cột", dùng chung cho màn Khám phá và Bàn ăn.
// Không tự cuộn: đặt bên trong một widget cuộn của màn hình cha.
// Tìm kiếm không phân biệt dấu; buổi ăn trong bảng lọc lọc món theo mealTimes.
class DishPicker extends StatefulWidget {
  // repository: truyền vào khi test; mặc định lấy từ AppState.
  const DishPicker({super.key, this.repository});

  final DishRepository? repository;

  @override
  State<DishPicker> createState() => _DishPickerState();
}

enum _Status { loading, ready, error }

class _DishPickerState extends State<DishPicker> {
  // Chỉ lấy repository, không cần dựng lại khi AppState đổi (listen: false).
  late final DishRepository _repository = widget.repository ??
      AppScope.of(context, listen: false).dishRepository;
  String _query = '';
  var _status = _Status.loading;
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
    setState(() => _status = _Status.loading);
    try {
      final dishes =
          await _repository.getDishes(query: _query, mealTime: _mealTime);
      if (!mounted || id != _requestId) return;
      setState(() {
        _dishes = dishes;
        _status = _Status.ready;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() => _status = _Status.error);
    }
  }

  // Tạm thời mở màn chi tiết món (chưa có thiết kế); danh sách bàn theo món làm ở GĐ D.
  void _openDish(Dish dish) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DishDetailScreen(dish: dish)),
    );
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
        if (_status == _Status.loading)
          // Đang tải
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_status == _Status.error)
          _errorView(t)
        else if (_dishes.isEmpty)
          // Trường hợp danh sách rỗng
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text(t(StrKey.dishesEmpty))),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Chiều cao mỗi ô = ảnh 4:3 + phần chữ bên dưới
              const gap = 16.0;
              final itemWidth = (constraints.maxWidth - gap) / 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: 12,
                  mainAxisExtent: itemWidth * 3 / 4 + 100,
                ),
                itemCount: _dishes.length,
                itemBuilder: (_, i) => DishCard(
                  dish: _dishes[i],
                  onTap: () => _openDish(_dishes[i]),
                  onFindTable: () => _openDish(_dishes[i]),
                ),
              );
            },
          ),
      ],
    );
  }

  // Lỗi tải (ví dụ không có mạng): báo và cho thử lại
  Widget _errorView(Strings t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(t(StrKey.dishesError), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _load,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: const StadiumBorder(),
            ),
            child: Text(t(StrKey.retry)),
          ),
        ],
      ),
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
