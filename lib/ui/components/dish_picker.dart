import 'package:flutter/material.dart';

import '../../data/models/dish.dart';
import '../../data/repositories/dish_repository.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../theme/app_theme.dart';
import 'dish_card.dart';

// Khối "ô tìm kiếm + nút lọc + lưới món 2 cột", dùng chung cho màn Khám phá và Bàn ăn.
// Không tự cuộn: đặt bên trong một widget cuộn của màn hình cha.
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
  String? _category; // null = tất cả
  var _status = _Status.loading;
  var _dishes = <Dish>[];
  var _categories = <String>[];
  var _requestId = 0; // bỏ kết quả của lần gọi cũ khi người dùng gõ tiếp

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = ++_requestId;
    setState(() => _status = _Status.loading);
    try {
      final categoriesFuture = _categories.isEmpty
          ? _repository.getCategories()
          : Future.value(_categories);
      final (dishes, categories) = await (
        _repository.getDishes(query: _query, category: _category),
        categoriesFuture,
      ).wait;
      if (!mounted || id != _requestId) return;
      setState(() {
        _dishes = dishes;
        _categories = categories;
        _status = _Status.ready;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() => _status = _Status.error);
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
            _filterButton(t),
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
                itemBuilder: (_, i) => DishCard(dish: _dishes[i]),
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

  // Nút lọc danh mục: bấm để chọn danh mục
  Widget _filterButton(Strings t) {
    return PopupMenuButton<String?>(
      tooltip: t(StrKey.filterByCategory),
      onSelected: (v) {
        _category = v;
        _load();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String?>(value: null, child: Text(t(StrKey.all))),
        for (final c in _categories)
          PopupMenuItem<String?>(value: c, child: Text(t.categoryLabel(c))),
      ],
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _category == null ? Colors.white : AppColors.selectedBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _category == null
                ? const Color(0x1F000000)
                : AppColors.primary,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
      ),
    );
  }
}
