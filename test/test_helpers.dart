import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/mock/mock_data.dart';
import 'package:giua_ki_app/data/mock/mock_support.dart';
import 'package:giua_ki_app/data/mock_dishes.dart';
import 'package:giua_ki_app/data/models/dining_table.dart';
import 'package:giua_ki_app/data/models/dish.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/repositories/dish_repository.dart';
import 'package:giua_ki_app/data/repositories/mock_auth_repository.dart';
import 'package:giua_ki_app/data/repositories/mock_chat_repository.dart';
import 'package:giua_ki_app/data/repositories/mock_location_repository.dart';
import 'package:giua_ki_app/data/repositories/mock_safety_repository.dart';
import 'package:giua_ki_app/data/repositories/mock_table_repository.dart';
import 'package:giua_ki_app/data/repositories/table_repository.dart';
import 'package:giua_ki_app/state/app_scope.dart';
import 'package:giua_ki_app/state/app_state.dart';

// Giờ cố định dùng chung cho test: thứ Hai 05/10/2026, 10:00.
final testNow = DateTime(2026, 10, 5, 10, 0);

// AppState dùng dữ liệu mẫu, giờ cố định, không có độ trễ.
AppState makeAppState({Latency latency = noLatency}) =>
    AppState.mock(now: () => testNow, latency: latency);

// Bọc một widget trong AppScope + MaterialApp để test riêng từng widget.
Widget wrapWithApp(Widget child, {AppState? app}) {
  return AppScope(
    state: app ?? makeAppState(),
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

// Giống testWidgets nhưng với khung nhìn cỡ điện thoại (mặc định 412x915), để thanh dưới
// không che mất nội dung như ở khung 800x600 mặc định của test.
void phoneTest(
  String description,
  Future<void> Function(WidgetTester) body, {
  Size size = const Size(412, 915),
}) {
  testWidgets(description, (tester) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await body(tester);
  });
}

// Repository món giả để thử các trạng thái: trả về danh sách cho trước hoặc báo lỗi.
// Ghi lại số lần gọi và tham số của lần gọi gần nhất.
class FakeDishRepository implements DishRepository {
  FakeDishRepository({
    this.dishes = const [],
    this.regional = const [],
    this.fail = false,
  });

  List<Dish> dishes;
  List<Dish> regional;
  bool fail;
  int calls = 0;
  int regionalCalls = 0;
  Taste? lastTaste;
  Mood? lastMood;
  bool lastOnlyTrending = false;
  MealTime? lastMealTime;

  @override
  Future<List<Dish>> getDishes({
    String query = '',
    String? category,
    MealTime? mealTime,
    Taste? taste,
    Mood? mood,
    bool onlyTrending = false,
  }) async {
    calls++;
    lastTaste = taste;
    lastMood = mood;
    lastOnlyTrending = onlyTrending;
    lastMealTime = mealTime;
    if (fail) throw Exception('Không có mạng');
    return dishes;
  }

  @override
  Future<List<Dish>> getRegionalDishes() async {
    regionalCalls++;
    if (fail) throw Exception('Không có mạng');
    return regional;
  }

  @override
  Future<Dish?> getDish(String id) async => null;

  @override
  Future<List<String>> getCategories() async => const [];
}

// ---------- Dữ liệu bàn riêng cho test ----------

// Bàn nhỏ gọn cho test (giờ Việt Nam, mặc định đang mở).
DiningTable makeTable(
  String id, {
  String? dishId,
  String restaurantId = 'q1-1',
  required DateTime start,
  int duration = 60,
  int capacity = 4,
  required List<String> members,
  TableStatus? status,
}) {
  return DiningTable(
    id: id,
    dishId: dishId,
    restaurantId: restaurantId,
    hostId: members.first,
    startAt: start,
    durationMin: duration,
    capacity: capacity,
    status: status ?? (members.length >= capacity ? TableStatus.full : TableStatus.open),
    memberIds: members,
  );
}

// Bộ bàn cố định cho test (testNow = thứ Hai 05/10/2026 10:00). Cả bộ nằm ở Quận 1.
// ta  11:00 Phở        quán q1-1 còn 2 chỗ        (u2, u3)
// tb  12:00 Lẩu        quán q1-1 đã đầy 2/2       (u2, u3)
// tc  14:00 chưa món   quán q1-2 còn 2 chỗ        (u1, u2)  -> u1 đã tham gia
// td  14:30 Bánh xèo   quán q1-2 còn 3 chỗ        (u4)      -> trùng giờ với tc
// tg  18:00 Ốc         quán q1-4 (khoảng 660 m)   (u5, u6)
// tf  mai 08:00 Cơm tấm quán q1-4                 (u5)
// te  09:30 đã bắt đầu (ẩn), th 13:00 đã huỷ (ẩn)
List<DiningTable> standardTables() {
  final d = testNow;
  DateTime at(int h, int m, {int dayOffset = 0}) =>
      DateTime(d.year, d.month, d.day + dayOffset, h, m);
  return [
    makeTable('ta', dishId: 'pho', start: at(11, 0), members: ['u2', 'u3']),
    makeTable('tb', dishId: 'lau', start: at(12, 0), capacity: 2, members: ['u2', 'u3']),
    makeTable('tc', restaurantId: 'q1-2', start: at(14, 0), members: ['u1', 'u2']),
    makeTable('td', dishId: 'banh-xeo', restaurantId: 'q1-2', start: at(14, 30), members: ['u4']),
    makeTable('tg', dishId: 'oc', restaurantId: 'q1-4', start: at(18, 0), capacity: 6, members: ['u5', 'u6']),
    makeTable('tf', dishId: 'com-tam', restaurantId: 'q1-4', start: at(8, 0, dayOffset: 1), members: ['u5']),
    makeTable('te', dishId: 'pho', start: at(9, 30), members: ['u7', 'u8']),
    makeTable('th', dishId: 'pho', start: at(13, 0), members: ['u7'], status: TableStatus.cancelled),
  ];
}

// AppState với bộ bàn riêng (thay vì bàn mẫu ngẫu nhiên theo giờ). Có thể thay luôn
// TableRepository (ví dụ bản giả luôn báo lỗi) và đồng hồ.
AppState makeAppStateWithTables(
  List<DiningTable> tables, {
  Clock? now,
  Latency latency = noLatency,
  TableRepository? tableRepository,
}) {
  final data = MockData.build(testNow);
  final clock = now ?? () => testNow;
  return AppState(
    now: clock,
    dishRepository: MockDishRepository(latency: latency),
    tableRepository: tableRepository ??
        MockTableRepository(
          tables: tables,
          restaurants: data.restaurants,
          areas: data.areas,
          now: clock,
          latency: latency,
        ),
    authRepository: MockAuthRepository(users: data.users, latency: latency),
    chatRepository: MockChatRepository(messages: const [], now: clock, latency: latency),
    safetyRepository: MockSafetyRepository(now: clock, latency: latency),
    locationRepository: MockLocationRepository(
      areas: data.areas,
      restaurants: data.restaurants,
      latency: latency,
    ),
  );
}

// TableRepository giả: trả về danh sách cho trước; joinTable luôn ném lỗi cho trước
// (TableException, hoặc lỗi chung nếu `error` là null).
class ThrowingTableRepository implements TableRepository {
  ThrowingTableRepository({
    this.tables = const [],
    this.error,
    this.failList = false,
  });

  List<DiningTable> tables;
  final TableError? error;
  bool failList; // true: getTables báo lỗi (để thử trạng thái lỗi + Thử lại)
  int listCalls = 0;
  int joinCalls = 0;

  @override
  Future<List<DiningTable>> getTables(TableQuery query) async {
    listCalls++;
    if (failList) throw Exception('Không có mạng');
    return tables;
  }

  @override
  Future<DiningTable> joinTable(String tableId, String userId) async {
    joinCalls++;
    final e = error;
    if (e != null) throw TableException(e);
    throw Exception('Lỗi bất ngờ');
  }

  @override
  Future<DiningTable?> getTable(String id) async => null;

  @override
  Future<List<DiningTable>> getMyTables(String userId) async => [];

  @override
  Future<DiningTable> createTable({
    required String hostId,
    String? dishId,
    required String restaurantId,
    required DateTime startAt,
    required int durationMin,
    required int capacity,
    String note = '',
  }) => throw UnimplementedError();

  @override
  Future<DiningTable> leaveTable(String tableId, String userId) =>
      throw UnimplementedError();

  @override
  Future<DiningTable> cancelTable(String tableId, String userId) =>
      throw UnimplementedError();
}
