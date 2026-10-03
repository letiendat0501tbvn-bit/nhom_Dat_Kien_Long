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
  });

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
              image: true,
              label: dish.name,
              excludeSemantics: true,
              child: ColoredBox(
                color: Color(dish.tint),
                child: Center(
                  child: Text(dish.emoji, style: TextStyle(fontSize: emojiSize)),
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
