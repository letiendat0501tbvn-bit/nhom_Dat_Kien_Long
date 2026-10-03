import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/mock/mock_support.dart';
import 'package:giua_ki_app/data/mock_dishes.dart';
import 'package:giua_ki_app/data/models/dish.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/repositories/dish_repository.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/ui/components/dish_picker.dart';
import 'package:giua_ki_app/ui/screens/profile_screen.dart';

// Repository giả luôn báo lỗi, để thử trạng thái lỗi + nút "Thử lại".
class _FailingDishRepository implements DishRepository {
  int calls = 0;

  @override
  Future<List<Dish>> getDishes({
    String query = '',
    String? category,
    MealTime? mealTime,
  }) async {
    calls++;
    throw Exception('Không có mạng');
  }

  @override
  Future<Dish?> getDish(String id) async => null;

  @override
  Future<List<String>> getCategories() async => const [];
}

void main() {
  testWidgets('Bottom bar switches tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Bàn ăn'));
    await tester.pumpAndSettle();
    expect(find.text('Bàn còn chỗ'), findsOneWidget);
    expect(find.text('Chọn khu vực'), findsNWidgets(2)); // tiêu đề + nút
    expect(find.text('Phở'), findsOneWidget); // dùng lại khối chọn món

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Tạo bàn mới'), findsWidgets);
  });

  testWidgets('Lịch hẹn and Tôi open the right profile tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Lịch hẹn'));
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ của bạn'), findsOneWidget);
    expect(find.text('Đăng nhập để xem những bàn ăn của bạn.'), findsOneWidget);

    await tester.tap(find.text('Tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Khách ghé chơi'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);

    // Chuyển tab trong màn Hồ sơ
    await tester.tap(find.text('Bàn của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Bàn ăn của bạn'), findsOneWidget);
    expect(find.text('Khách ghé chơi'), findsNothing);
  });

  testWidgets('Lịch hẹn and Tôi share one profile screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Lịch hẹn'));
    await tester.pumpAndSettle();
    final first = tester.state(find.byType(ProfileScreen));

    await tester.tap(find.text('Tôi'));
    await tester.pumpAndSettle();
    // Cùng một State: không dựng lại màn hình khi đổi giữa hai tab
    expect(tester.state(find.byType(ProfileScreen)), same(first));
  });

  testWidgets('Explore shows loading, then dishes, then filters by search',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Chọn món để lên kèo'), findsOneWidget);

    // Vừa mở: đang tải, chưa có món
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Phở'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Phở'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Phở'), findsNothing);
    expect(find.text('Không tìm thấy món phù hợp.'), findsOneWidget);
  });

  testWidgets('DishPicker shows error and retries', (WidgetTester tester) async {
    final repo = _FailingDishRepository();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: DishPicker(repository: repo))),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Không tải được danh sách món'), findsOneWidget);
    expect(repo.calls, 1);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('DishPicker ignores stale results', (WidgetTester tester) async {
    // Mỗi lần gọi repository lấy một độ trễ trong hàng đợi:
    // tải đầu (món + danh mục) 100/100ms, gõ "phở" chậm 800ms, gõ "lẩu" nhanh 100ms.
    // Kết quả "phở" về sau cùng nhưng không được ghi đè kết quả "lẩu".
    final delays = [100, 100, 800, 100];
    var next = 0;
    final repo = MockDishRepository(
      latency: () => Duration(milliseconds: delays[next++]),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: DishPicker(repository: repo))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Phở'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'phở');
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'lẩu');
    await tester.pumpAndSettle();
    expect(find.text('Lẩu'), findsOneWidget);

    // Chờ kết quả "phở" (chậm) về: vẫn phải giữ kết quả "lẩu"
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Lẩu'), findsOneWidget);
    expect(find.text('Phở'), findsNothing);
  });

  test('MockDishRepository uses injected latency', () async {
    final repo = MockDishRepository(latency: noLatency);
    final all = await repo.getDishes();
    expect(all.length, 56);
  });
}
