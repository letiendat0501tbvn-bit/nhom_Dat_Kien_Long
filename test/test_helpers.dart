import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/mock/mock_support.dart';
import 'package:giua_ki_app/data/models/dish.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/repositories/dish_repository.dart';
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
