import 'enums.dart';

// Mô hình dữ liệu một món ăn.
// Các trường từ `group` trở xuống là phần mở rộng theo SPEC, đều có giá trị
// mặc định nên dữ liệu mẫu cũ vẫn dùng được.
class Dish {
  const Dish({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.emoji,
    required this.tint,
    this.group = '',
    this.tastes = const [],
    this.moods = const [],
    this.region,
    this.hashtag,
    this.isTrending = false,
    this.mealTimes = const [],
  });

  final String id; // slug, ví dụ 'pho'
  final String name;
  final String category; // nhãn danh mục: Bún & mì, Bánh mặn, ...
  final String description;
  final String emoji; // ảnh tạm khi chưa có ảnh thật
  final int tint; // màu nền ảnh tạm (ARGB)

  final String group; // nhóm ở khối giới thiệu: Món nước & sợi, ...
  final List<Taste> tastes; // khẩu vị
  final List<Mood> moods; // tâm trạng
  final String? region; // vùng, dùng cho mục "ba miền"
  final String? hashtag; // ví dụ #HanoiClassic
  final bool isTrending; // tab "Đang hot"
  final List<MealTime> mealTimes; // buổi ăn phù hợp
}
