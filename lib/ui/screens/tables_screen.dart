import 'package:flutter/material.dart';

import '../components/dish_picker.dart';
import '../components/section_heading.dart';
import '../theme/app_theme.dart';

// Màn Bàn ăn: thẻ "Chọn khu vực" ở trên, bên dưới là khối chọn món như màn Khám phá.
class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            title: 'Bàn còn chỗ',
            subtitle: 'Chọn điểm hẹn tại quán và giờ ăn phù hợp.',
          ),
          const SizedBox(height: 16),
          _AreaCard(
            // Chưa có chức năng chọn khu vực, sẽ làm ở bước sau
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chọn khu vực: chưa làm')),
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeading(
            title: 'Chọn món để lên kèo',
            subtitle: 'Chọn món → Xem quán và giờ hẹn → Xác nhận tham gia.',
          ),
          const SizedBox(height: 16),
          const DishPicker(),
        ],
      ),
    );
  }
}

// Thẻ trắng bo góc lớn: biểu tượng ghim, mô tả và nút đỏ "Chọn khu vực".
class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x1F000000)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.selectedBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_outlined,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn khu vực',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dùng vị trí để tìm điểm hẹn tại quán.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Chọn khu vực',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
