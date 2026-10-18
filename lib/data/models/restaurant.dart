import '../../core/entity.dart';

// Quán ăn (dữ liệu mẫu dùng tên giả).
class Restaurant extends Entity<String> {
  const Restaurant({
    required String id,
    required this.name,
    required this.address,
    required this.areaId,
    required this.lat,
    required this.lng,
  }) : super(id);

  final String name;
  final String address;
  final String areaId;
  final double lat;
  final double lng;

  @override
  String get label => name;
}
