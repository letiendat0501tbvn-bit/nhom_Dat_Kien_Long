// Khu vực để chọn tâm tìm kiếm, ví dụ: Hà Nội · Hoàn Kiếm.
class Area {
  const Area({
    required this.id,
    required this.city,
    required this.district,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String city;
  final String district;
  // Tâm khu vực, dùng để tính bán kính tới quán.
  final double lat;
  final double lng;

  String get label => '$city · $district';
}
