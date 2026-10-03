// Mô hình dữ liệu một món ăn.
class Dish {
  const Dish({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.emoji,
    required this.tint,
  });

  final String id;
  final String name;
  final String category; // nhãn danh mục: Bún & mì, Bánh mặn, ...
  final String description;
  final String emoji; // ảnh tạm khi chưa có ảnh thật
  final int tint; // màu nền ảnh tạm (ARGB)
}
