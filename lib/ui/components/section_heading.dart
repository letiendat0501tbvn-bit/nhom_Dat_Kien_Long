import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Tiêu đề lớn + dòng phụ, dùng ở đầu mỗi khối nội dung.
class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.text.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
