import '../../core/firestore_repo.dart';
import '../models/area.dart';
import '../models/restaurant.dart';
import 'firebase_errors.dart';
import 'location_repository.dart';

// LocationRepository đọc từ hai collection Firestore: `areas` (khu vực) và `restaurants` (quán).
class FirestoreLocationRepository implements LocationRepository {
  FirestoreLocationRepository({required this.areas, required this.restaurants});

  final FirestoreRepo<Area> areas;
  final FirestoreRepo<Restaurant> restaurants;

  @override
  Future<List<Area>> getAreas() => guardData(areas.all);

  @override
  Future<List<Restaurant>> getRestaurants({String? areaId}) => guardData(
    () => areaId == null
        ? restaurants.all()
        : restaurants.where('areaId', isEqualTo: areaId),
  );
}
