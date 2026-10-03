import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Thanh chuyển tab dạng viên thuốc; mục đang chọn là nút trắng nổi lên.
class PillTabs extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0x1F000000)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: i == selected
                        ? const [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: i == selected
                          ? AppColors.text
                          : AppColors.text.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
