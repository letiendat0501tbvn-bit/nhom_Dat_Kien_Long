import '../models/area.dart';
import '../models/restaurant.dart';

// Khu vực và quán ăn.
abstract class LocationRepository {
  Future<List<Area>> getAreas();

  Future<List<Restaurant>> getRestaurants({String? areaId});
}
