import 'package:flutter/material.dart';

import '../../data/models/dish.dart';

// Ảnh món. Có ảnh thật (Dish.imageAsset) thì hiện ảnh, bo góc, tỉ lệ cố định, BoxFit.cover,
// hiện dần nhẹ khi tải xong. Món chưa có ảnh (hoặc file lỗi) thì dùng PLACEHOLDER: ô màu +
// emoji; ô này luôn nằm bên dưới ảnh nên bố cục không đổi và không nhảy khi ảnh tải xong.
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

  // Giải mã ảnh nhỏ lại theo kích thước hiển thị (không giải mã nguyên ảnh gốc nhiều MB).
  static const _maxDecodeWidth = 1200;

  @override
  Widget build(BuildContext context) {
    final asset = dish.imageAsset;
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
              excludeSemantics:
                  true, // luôn bỏ emoji và ảnh khỏi trình đọc màn hình
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _placeholder(),
                  if (asset != null) _photo(context, asset),
                ],
              ),
            ),
            ?overlay,
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: Color(dish.tint),
      child: Center(
        child: Text(dish.emoji, style: TextStyle(fontSize: emojiSize)),
      ),
    );
  }

  Widget _photo(BuildContext context, String asset) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        final cacheWidth = c.hasBoundedWidth
            ? (c.maxWidth * dpr).ceil().clamp(1, _maxDecodeWidth)
            : null;
        return Image.asset(
          asset,
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          // File thiếu hoặc hỏng: không báo lỗi, lộ ô màu + emoji bên dưới
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: child,
            );
          },
        );
      },
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
