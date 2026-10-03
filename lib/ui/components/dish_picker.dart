import 'package:flutter/material.dart';

import '../../data/mock_dishes.dart';
import '../theme/app_theme.dart';
import 'dish_card.dart';

// Khối "ô tìm kiếm + nút lọc + lưới món 2 cột", dùng chung cho màn Khám phá và Bàn ăn.
// Không tự cuộn: đặt bên trong một widget cuộn của màn hình cha.
class DishPicker extends StatefulWidget {
  const DishPicker({super.key});

  @override
  State<DishPicker> createState() => _DishPickerState();
}

class _DishPickerState extends State<DishPicker> {
  final _repository = const DishRepository();
  String _query = '';
  String? _category; // null = tất cả

  @override
  Widget build(BuildContext context) {
    final dishes = _repository.getDishes(query: _query, category: _category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _searchBox()),
            const SizedBox(width: 10),
            _filterButton(),
          ],
        ),
        const SizedBox(height: 16),
        if (dishes.isEmpty)
          // Trường hợp danh sách rỗng
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('Không tìm thấy món phù hợp.')),
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
                itemCount: dishes.length,
                itemBuilder: (_, i) => DishCard(dish: dishes[i]),
              );
            },
          ),
      ],
    );
  }

  // Ô tìm kiếm dạng viên thuốc
  Widget _searchBox() {
    return TextField(
      onChanged: (v) => setState(() => _query = v),
      decoration: InputDecoration(
        hintText: 'Tìm món ăn…',
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
  Widget _filterButton() {
    return PopupMenuButton<String?>(
      tooltip: 'Lọc theo danh mục',
      onSelected: (v) => setState(() => _category = v),
      itemBuilder: (_) => [
        const PopupMenuItem<String?>(value: null, child: Text('Tất cả')),
        for (final c in _repository.categories)
          PopupMenuItem<String?>(value: c, child: Text(c)),
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
