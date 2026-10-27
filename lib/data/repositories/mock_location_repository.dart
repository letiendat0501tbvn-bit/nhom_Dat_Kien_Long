import '../../core/memory_repo.dart';
import '../mock/mock_support.dart';
import '../models/area.dart';
import '../models/restaurant.dart';
import 'location_repository.dart';

// Bản mock của LocationRepository: khu vực và quán lưu trong bộ nhớ (hai MemoryRepo).
class MockLocationRepository implements LocationRepository {
  MockLocationRepository({
    required List<Area> areas,
    required List<Restaurant> restaurants,
    this.latency = randomLatency,
  }) : _areas = MemoryRepo(areas),
       _restaurants = MemoryRepo(restaurants);

  final Latency latency;
  final MemoryRepo<Area, String> _areas;
  final MemoryRepo<Restaurant, String> _restaurants;

  @override
  Future<List<Area>> getAreas() async {
    await Future<void>.delayed(latency());
    return _areas.all();
  }

  @override
  Future<List<Restaurant>> getRestaurants({String? areaId}) async {
    await Future<void>.delayed(latency());
    return _restaurants.where((r) => areaId == null || r.areaId == areaId);
  }
}
