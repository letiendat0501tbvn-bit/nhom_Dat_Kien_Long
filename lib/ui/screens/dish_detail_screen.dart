import 'package:flutter/material.dart';

import '../../data/models/dish.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../components/dish_image.dart';
import '../theme/app_theme.dart';

// Chi tiết món. TẠM THỜI: chưa có thiết kế, chỉ hiện ảnh, tên, danh mục, mô tả.
// Danh sách bàn theo món và nút "Tìm bàn ăn" làm ở giai đoạn D.
class DishDetailScreen extends StatelessWidget {
  const DishDetailScreen({super.key, required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(dish.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DishImage(dish: dish, radius: 28, emojiSize: 96),
          const SizedBox(height: 16),
          Text(
            dish.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            t.categoryLabel(dish.category),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dish.description,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 24),
          Text(
            t(StrKey.dishDetailPending),
            style: TextStyle(color: AppColors.text.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

// Mở màn chi tiết món. Dùng chung cho thẻ món ở mọi nơi.
void openDishDetail(BuildContext context, Dish dish) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => DishDetailScreen(dish: dish)));
}
