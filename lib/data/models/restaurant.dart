import '../../core/entity.dart';
import '../../core/map_utils.dart';

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

  factory Restaurant.fromMap(String id, Map<String, dynamic> map) => Restaurant(
    id: id,
    name: map['name'] as String,
    address: map['address'] as String,
    areaId: map['areaId'] as String,
    lat: readDouble(map['lat']),
    lng: readDouble(map['lng']),
  );

  final String name;
  final String address;
  final String areaId;
  final double lat;
  final double lng;

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'address': address,
    'areaId': areaId,
    'lat': lat,
    'lng': lng,
  };

  @override
  String get label => name;
}
