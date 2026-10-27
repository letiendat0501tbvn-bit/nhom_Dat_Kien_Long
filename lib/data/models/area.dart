import '../../core/entity.dart';
import '../../core/map_utils.dart';

// Khu vực để chọn tâm tìm kiếm, ví dụ: Hà Nội · Hoàn Kiếm.
class Area extends Entity<String> {
  const Area({
    required String id,
    required this.city,
    required this.district,
    required this.lat,
    required this.lng,
  }) : super(id);

  // Đọc từ dữ liệu Firestore/JSON (id là id của document).
  factory Area.fromMap(String id, Map<String, dynamic> map) => Area(
    id: id,
    city: map['city'] as String,
    district: map['district'] as String,
    lat: readDouble(map['lat']),
    lng: readDouble(map['lng']),
  );

  final String city;
  final String district;
  // Tâm khu vực, dùng để tính bán kính tới quán.
  final double lat;
  final double lng;

  @override
  Map<String, dynamic> toMap() => {
    'city': city,
    'district': district,
    'lat': lat,
    'lng': lng,
  };

  @override
  String get label => '$city · $district';
}
