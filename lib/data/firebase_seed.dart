import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_repo.dart';
import 'mock/mock_data.dart';
import 'models/area.dart';
import 'models/dining_table.dart';
import 'models/restaurant.dart';
import 'models/user.dart';

// Đưa dữ liệu mẫu lên Firestore MỘT LẦN (chạy lại thì ghi đè, id giữ nguyên):
// khu vực (areas), quán (restaurants), người dùng mẫu (users) và bàn ăn (tables).
// Giờ của các bàn tính từ `now`, nên chạy lại để làm mới dữ liệu khi các bàn đã cũ.
// Gọi từ app bằng cách nhấn giữ logo ở thanh trên (chỉ có khi chạy với USE_FIREBASE=true).
Future<void> seedFirestore(FirebaseFirestore db, {DateTime? now}) async {
  final data = MockData.build(now ?? DateTime.now());
  final areas = FirestoreRepo<Area>(
    firestore: db,
    collection: 'areas',
    fromMap: Area.fromMap,
  );
  final restaurants = FirestoreRepo<Restaurant>(
    firestore: db,
    collection: 'restaurants',
    fromMap: Restaurant.fromMap,
  );
  final users = FirestoreRepo<User>(
    firestore: db,
    collection: 'users',
    fromMap: User.fromMap,
  );
  final tables = FirestoreRepo<DiningTable>(
    firestore: db,
    collection: 'tables',
    fromMap: DiningTable.fromMap,
  );
  await Future.wait([
    for (final a in data.areas) areas.set(a),
    for (final r in data.restaurants) restaurants.set(r),
    for (final u in data.users) users.set(u),
    for (final t in data.tables) tables.set(t),
  ]);
}
