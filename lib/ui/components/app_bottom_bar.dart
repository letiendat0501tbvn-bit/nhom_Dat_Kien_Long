import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../theme/app_theme.dart';

// Thanh dưới 5 mục: Khám phá · Bàn ăn · [+] · Lịch hẹn · Tôi.
// Nút + ở giữa không phải là tab, chỉ gọi onCreate.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCreate,
  });

  final int currentIndex; // 0..3, tương ứng 4 tab
  final ValueChanged<int> onTap;
  final VoidCallback onCreate;

  static const _items = [
    (Icons.explore_outlined, StrKey.tabExplore),
    (Icons.restaurant_outlined, StrKey.tabTables),
    (Icons.calendar_month_outlined, StrKey.tabSchedule),
    (Icons.person_outline, StrKey.tabMe),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  _tab(t, 0),
                  _tab(t, 1),
                  const Expanded(child: SizedBox()), // chỗ cho nút +
                  _tab(t, 2),
                  _tab(t, 3),
                ],
              ),
              // Nút + đỏ tròn nổi ở giữa
              Positioned(
                top: -24,
                left: 0,
                right: 0,
                child: Center(
                  child: Semantics(
                    button: true,
                    label: t(StrKey.createTable),
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: onCreate,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        child:
                            const Icon(Icons.add, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(Strings t, int index) {
    final selected = index == currentIndex;
    final color = selected ? AppColors.primary : AppColors.text;
    final (icon, labelKey) = _items[index];
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gạch đỏ nhỏ phía trên mục đang chọn
            Container(
              width: 24,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              color: selected ? AppColors.primary : Colors.transparent,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppColors.selectedBg : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color),
            ),
            Text(
              t(labelKey),
              maxLines: 1, // nhãn dài (ví dụ bản EN) không được xuống dòng làm tràn
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
