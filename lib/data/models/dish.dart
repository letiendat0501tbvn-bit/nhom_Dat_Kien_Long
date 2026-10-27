import '../../core/entity.dart';
import '../../core/map_utils.dart';
import 'enums.dart';

// Mô hình dữ liệu một món ăn.
// Các trường từ `group` trở xuống là phần mở rộng theo SPEC, đều có giá trị
// mặc định nên dữ liệu mẫu cũ vẫn dùng được.
class Dish extends Entity<String> {
  const Dish({
    required String id,
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
    this.imageAsset,
    this.descriptionEn,
  }) : super(id);

  factory Dish.fromMap(String id, Map<String, dynamic> map) => Dish(
    id: id,
    name: map['name'] as String,
    category: map['category'] as String,
    description: map['description'] as String,
    emoji: map['emoji'] as String,
    tint: readInt(map['tint']),
    group: map['group'] as String? ?? '',
    tastes: readEnums(Taste.values, map['tastes']),
    moods: readEnums(Mood.values, map['moods']),
    region: map['region'] as String?,
    hashtag: map['hashtag'] as String?,
    isTrending: map['isTrending'] as bool? ?? false,
    mealTimes: readEnums(MealTime.values, map['mealTimes']),
    imageAsset: map['imageAsset'] as String?,
    descriptionEn: map['descriptionEn'] as String?,
  );

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
  // Đường dẫn ảnh trong assets; null (hoặc file không đọc được) thì dùng ô màu + emoji.
  final String? imageAsset;
  // Mô tả tiếng Anh; null thì dùng mô tả tiếng Việt. Tên món luôn giữ tiếng Việt.
  final String? descriptionEn;

  // Mô tả theo ngôn ngữ đang chọn, có dự phòng về tiếng Việt nếu thiếu bản dịch.
  String descriptionFor(AppLanguage language) {
    final en = descriptionEn;
    if (language == AppLanguage.en && en != null && en.isNotEmpty) return en;
    return description;
  }

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'description': description,
    'emoji': emoji,
    'tint': tint,
    'group': group,
    'tastes': [for (final t in tastes) t.name],
    'moods': [for (final m in moods) m.name],
    'region': region,
    'hashtag': hashtag,
    'isTrending': isTrending,
    'mealTimes': [for (final m in mealTimes) m.name],
    'imageAsset': imageAsset,
    'descriptionEn': descriptionEn,
  };

  @override
  String get label => name;
}
