import 'package:flutter/material.dart';

import '../../data/logic/table_rules.dart';
import '../../data/models/dish.dart';
import '../../data/models/enums.dart';
import '../../data/models/restaurant.dart';
import '../../l10n/formatters.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../theme/app_theme.dart';

// Các ô nhập của form "Mở bàn mới". Chỉ hiển thị và báo thay đổi lên màn cha.

// Một mục của form: tiêu đề, ghi chú nhỏ (nếu có), nội dung và lỗi đỏ ngay dưới trường.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.child,
    this.note,
    this.error,
  });

  final String title;
  final String? note;
  final String? error;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(
              note!,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.text.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 8),
          child,
          if (error != null) ...[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: Text(
                error!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Chọn món (không bắt buộc): chưa chọn thì có ô tìm không dấu và vài kết quả;
// đã chọn thì hiện món kèm nút bỏ chọn.
class DishPickerField extends StatefulWidget {
  const DishPickerField({
    super.key,
    required this.dish,
    required this.onChanged,
  });

  final Dish? dish;
  final ValueChanged<Dish?> onChanged;

  @override
  State<DishPickerField> createState() => _DishPickerFieldState();
}

class _DishPickerFieldState extends State<DishPickerField> {
  static const _maxResults = 5;

  final _controller = TextEditingController();
  var _results = <Dish>[];
  var _requestId = 0; // bỏ kết quả của lần tìm cũ khi người dùng gõ tiếp
  var _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final id = ++_requestId;
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    try {
      final dishes = await AppScope.of(
        context,
        listen: false,
      ).dishRepository.getDishes(query: query);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = dishes.take(_maxResults).toList();
        _searched = true;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = [];
        _searched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    final selected = widget.dish;
    if (selected != null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        decoration: BoxDecoration(
          color: AppColors.selectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          children: [
            Text(selected.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selected.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: t(StrKey.ntDishClear),
              onPressed: () {
                _controller.clear();
                setState(() {
                  _results = [];
                  _searched = false;
                });
                widget.onChanged(null);
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: t(StrKey.searchHint),
            prefixIcon: const Icon(Icons.search),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0x1F000000)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (!_searched)
          Text(
            t(StrKey.ntDishHint),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          )
        else if (_results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(t(StrKey.ntDishNoResult)),
          )
        else
          for (final d in _results)
            ListTile(
              key: ValueKey('dish-${d.id}'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Text(d.emoji, style: const TextStyle(fontSize: 26)),
              title: Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                t.categoryLabel(d.category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                _controller.clear();
                setState(() {
                  _results = [];
                  _searched = false;
                });
                widget.onChanged(d);
              },
            ),
      ],
    );
  }
}

// Thẻ một quán để chọn: tên, địa chỉ, dấu chọn.
class RestaurantTile extends StatelessWidget {
  const RestaurantTile({
    super.key,
    required this.restaurant,
    required this.selected,
    required this.onTap,
  });

  final Restaurant restaurant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      // Gộp tên, địa chỉ, trạng thái chọn và thao tác chạm thành một mục cho trình đọc màn hình
      child: MergeSemantics(
        child: Semantics(
          button: true,
          selected: selected,
          child: Material(
            color: selected ? AppColors.selectedBg : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected ? AppColors.primary : const Color(0x1F000000),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      selected ? Icons.check_circle : Icons.storefront_outlined,
                      color: selected
                          ? AppColors.primary
                          : AppColors.text.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    // Tên và địa chỉ quán là dữ liệu, không dịch
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            restaurant.address,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.text.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Danh sách cuộn các mốc giờ theo khung 15 phút (giờ Việt Nam) của một ngày.
// Mốc đã qua (so với `now`) bị khoá, không chọn được.
class TimeSlotPicker extends StatelessWidget {
  const TimeSlotPicker({
    super.key,
    required this.date,
    required this.now,
    required this.selected,
    required this.language,
    required this.onChanged,
  });

  final DateTime date;
  final DateTime now;
  final int? selected; // phút trong ngày
  final AppLanguage language;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1F000000)),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in timeSlots())
                _slot(
                  m,
                  DateTime(date.year, date.month, date.day, m ~/ 60, m % 60),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slot(int minute, DateTime start) {
    final isSelected = minute == selected;
    final past = !start.isAfter(now);
    return ChoiceChip(
      label: Text(formatClockTime(start, language)),
      selected: isSelected,
      showCheckmark: false,
      backgroundColor: Colors.white,
      selectedColor: AppColors.selectedBg,
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? AppColors.primary : const Color(0x1F000000),
        ),
      ),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: isSelected ? AppColors.primary : AppColors.text,
      ),
      // Quá khứ: không có onSelected nên chip bị khoá
      onSelected: past ? null : (_) => onChanged(minute),
    );
  }
}

// Bộ tăng/giảm số chỗ trong khoảng 2–8.
class CapacityStepper extends StatelessWidget {
  const CapacityStepper({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return Row(
      children: [
        IconButton.outlined(
          tooltip: t(StrKey.ntSeatsDec),
          onPressed: value > minCapacity ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 96),
          alignment: Alignment.center,
          child: Text(
            t.seatsCount(value),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton.outlined(
          tooltip: t(StrKey.ntSeatsInc),
          onPressed: value < maxCapacity ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

// Một dòng ở màn xác nhận: nhãn nhỏ bên trên, giá trị bên dưới.
class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.text.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
