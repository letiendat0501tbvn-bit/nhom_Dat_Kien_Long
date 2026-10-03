import 'package:flutter/material.dart';

import '../../data/models/dish.dart';
import '../../l10n/strings.dart';
import '../../state/app_scope.dart';
import '../theme/app_theme.dart';
import 'dish_image.dart';

// Thẻ món: ảnh bo góc + nhãn danh mục, tên, mô tả 1 dòng, liên kết "Tìm bàn ăn".
// Bấm vào thẻ gọi onTap (mở chi tiết món); bấm "Tìm bàn ăn" gọi onFindTable.
class DishCard extends StatelessWidget {
  const DishCard({super.key, required this.dish, this.onTap, this.onFindTable});

  final Dish dish;
  final VoidCallback? onTap;
  final VoidCallback? onFindTable;

  @override
  Widget build(BuildContext context) {
    final t = context.strings;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DishImage(
              dish: dish,
              overlay: Positioned(
                top: 8,
                left: 8,
                child: _CategoryLabel(t.categoryLabel(dish.category)),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dish.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onFindTable,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            t(StrKey.findTable),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Nhãn danh mục (viên thuốc trắng) ở góc ảnh.
class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
