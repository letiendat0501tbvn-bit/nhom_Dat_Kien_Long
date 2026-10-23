import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../core/firestore_repo.dart';
import '../state/app_state.dart';
import 'firebase_seed.dart';
import 'mock/mock_support.dart';
import 'mock_dishes.dart';
import 'models/area.dart';
import 'models/dining_table.dart';
import 'models/restaurant.dart';
import 'models/user.dart';
import 'repositories/firebase_auth_repository.dart';
import 'repositories/firestore_location_repository.dart';
import 'repositories/firestore_table_repository.dart';
import 'repositories/mock_chat_repository.dart';
import 'repositories/mock_safety_repository.dart';

// AppState dùng Firebase: tài khoản (Firebase Auth + collection users), bàn ăn (tables),
// khu vực và quán (areas, restaurants) nằm trên Firestore. Món ăn, trò chuyện, báo cáo và
// chặn vẫn là bản Mock trong bộ nhớ. Chỉ gọi sau khi đã Firebase.initializeApp.
AppState createFirebaseAppState({Clock now = systemClock}) {
  final db = FirebaseFirestore.instance;
  final users = FirestoreRepo<User>(
    firestore: db,
    collection: 'users',
    fromMap: User.fromMap,
  );
  final safety = MockSafetyRepository(now: now);
  Future<Set<String>> blockedIdsOf(String id) async => safety.blockedIdsOf(id);
  return AppState(
    now: now,
    dishRepository: MockDishRepository(),
    tableRepository: FirestoreTableRepository(
      tables: FirestoreRepo<DiningTable>(
        firestore: db,
        collection: 'tables',
        fromMap: DiningTable.fromMap,
      ),
      restaurants: FirestoreRepo<Restaurant>(
        firestore: db,
        collection: 'restaurants',
        fromMap: Restaurant.fromMap,
      ),
      areas: FirestoreRepo<Area>(
        firestore: db,
        collection: 'areas',
        fromMap: Area.fromMap,
      ),
      now: now,
      blockedIdsOf: blockedIdsOf,
    ),
    authRepository: FirebaseAuthRepository(
      auth: fb.FirebaseAuth.instance,
      users: users,
      now: now,
    ),
    chatRepository: MockChatRepository(
      messages: const [],
      now: now,
      blockedIdsOf: blockedIdsOf,
    ),
    safetyRepository: safety,
    locationRepository: FirestoreLocationRepository(
      areas: FirestoreRepo<Area>(
        firestore: db,
        collection: 'areas',
        fromMap: Area.fromMap,
      ),
      restaurants: FirestoreRepo<Restaurant>(
        firestore: db,
        collection: 'restaurants',
        fromMap: Restaurant.fromMap,
      ),
    ),
    seedData: () => seedFirestore(db, now: now()),
  );
}
