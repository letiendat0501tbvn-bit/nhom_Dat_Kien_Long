import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Hàng chip chọn một giá trị. allowClear: bấm lại chip đang chọn thì bỏ chọn (null).
class OptionChips<T> extends StatelessWidget {
  const OptionChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.allowClear = false,
  });

  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T?> onChanged;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: value == selected,
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: AppColors.selectedBg,
            shape: StadiumBorder(
              side: BorderSide(
                color: value == selected
                    ? AppColors.primary
                    : const Color(0x1F000000),
              ),
            ),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: value == selected ? AppColors.primary : AppColors.text,
            ),
            onSelected: (_) =>
                onChanged(allowClear && value == selected ? null : value),
          ),
      ],
    );
  }
}
