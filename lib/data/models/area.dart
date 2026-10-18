import '../../core/entity.dart';

// Khu vực để chọn tâm tìm kiếm, ví dụ: Hà Nội · Hoàn Kiếm.
class Area extends Entity<String> {
  const Area({
    required String id,
    required this.city,
    required this.district,
    required this.lat,
    required this.lng,
  }) : super(id);

  final String city;
  final String district;
  // Tâm khu vực, dùng để tính bán kính tới quán.
  final double lat;
  final double lng;

  @override
  String get label => '$city · $district';
}
