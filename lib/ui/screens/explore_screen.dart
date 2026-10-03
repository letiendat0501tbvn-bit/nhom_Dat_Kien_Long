import 'package:flutter/material.dart';

import '../components/dish_picker.dart';
import '../components/section_heading.dart';

// Màn Khám phá: tiêu đề + khối chọn món (tìm kiếm, lọc, lưới 2 cột).
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: 'Chọn món để lên kèo',
            subtitle: 'Chọn món → Xem quán và giờ hẹn → Xác nhận tham gia.',
          ),
          SizedBox(height: 16),
          DishPicker(),
        ],
      ),
    );
  }
}
