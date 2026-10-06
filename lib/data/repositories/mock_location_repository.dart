import '../mock/mock_support.dart';
import '../models/area.dart';
import '../models/restaurant.dart';
import 'location_repository.dart';

// Bản mock của LocationRepository: khu vực và quán lưu trong bộ nhớ.
class MockLocationRepository implements LocationRepository {
  MockLocationRepository({
    required this.areas,
    required this.restaurants,
    this.latency = randomLatency,
  });

  final Latency latency;
  final List<Area> areas;
  final List<Restaurant> restaurants;

  @override
  Future<List<Area>> getAreas() async {
    await Future<void>.delayed(latency());
    return List.of(areas);
  }

  @override
  Future<List<Restaurant>> getRestaurants({String? areaId}) async {
    await Future<void>.delayed(latency());
    return restaurants
        .where((r) => areaId == null || r.areaId == areaId)
        .toList();
  }
}
