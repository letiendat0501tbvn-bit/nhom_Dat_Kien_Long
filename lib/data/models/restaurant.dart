// Quán ăn (dữ liệu mẫu dùng tên giả).
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.areaId,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;
  final String address;
  final String areaId;
  final double lat;
  final double lng;
}
