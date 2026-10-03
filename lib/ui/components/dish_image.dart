import 'package:flutter/material.dart';

import '../../data/models/dish.dart';

// Ảnh món. Hiện là PLACEHOLDER (ô màu + emoji) vì chưa có ảnh thật; khi có ảnh,
// chỉ cần sửa widget này là mọi nơi dùng đều đổi theo.
// `overlay` là phần chồng lên ảnh (ví dụ nhãn danh mục ở góc).
class DishImage extends StatelessWidget {
  const DishImage({
    super.key,
    required this.dish,
    this.aspectRatio = 4 / 3,
    this.radius = 24,
    this.emojiSize = 64,
    this.overlay,
    this.excludeFromSemantics = false,
  });

  // excludeFromSemantics: true khi ảnh nằm cạnh tên món (như trong thẻ món) để trình
  // đọc màn hình không đọc lặp tên; ảnh đứng một mình thì giữ nhãn là tên món.
  final bool excludeFromSemantics;
  final Dish dish;
  final double aspectRatio;
  final double radius;
  final double emojiSize;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              image: !excludeFromSemantics,
              label: excludeFromSemantics ? null : dish.name,
              excludeSemantics: true, // luôn bỏ emoji khỏi trình đọc màn hình
              child: ColoredBox(
                color: Color(dish.tint),
                child: Center(
                  child: Text(
                    dish.emoji,
                    style: TextStyle(fontSize: emojiSize),
                  ),
                ),
              ),
            ),
            ?overlay,
          ],
        ),
      ),
    );
  }
}

// Nhãn viên thuốc trắng đặt ở góc ảnh (nhãn danh mục, nhãn vùng...).
class ImageLabel extends StatelessWidget {
  const ImageLabel(this.text, {super.key});

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
