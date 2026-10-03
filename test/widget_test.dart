import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/mock/mock_support.dart';
import 'package:giua_ki_app/data/mock_dishes.dart';
import 'package:giua_ki_app/data/models/dish.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/repositories/dish_repository.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/state/app_state.dart';
import 'package:giua_ki_app/ui/components/dish_picker.dart';
import 'package:giua_ki_app/ui/screens/profile_screen.dart';

import 'test_helpers.dart';

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
    await tester.pumpWidget(wrapWithApp(DishPicker(repository: repo)));
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
    await tester.pumpWidget(wrapWithApp(DishPicker(repository: repo)));
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

  group('đổi ngôn ngữ', () {
    testWidgets('nút EN/VI đổi toàn bộ chữ ngay lập tức',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('Khám phá'), findsOneWidget);
      expect(find.text('Chọn món để lên kèo'), findsOneWidget);
      expect(find.text('Bún & mì'), findsWidgets); // nhãn danh mục trên thẻ món

      await tester.tap(find.text('EN')); // đang là VI nên nút ghi EN
      await tester.pumpAndSettle();

      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Khám phá'), findsNothing);
      expect(find.text('Pick a dish to start a meetup'), findsOneWidget);
      expect(find.text('Noodles'), findsWidgets);
      expect(find.text('Bún & mì'), findsNothing);
      expect(find.text('Find a table'), findsWidgets);
      expect(find.text('VI'), findsOneWidget); // nút giờ ghi VI

      await tester.tap(find.text('VI'));
      await tester.pumpAndSettle();
      expect(find.text('Khám phá'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('màn Hồ sơ và thanh dưới cũng đổi ngôn ngữ',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(find.text('Your profile'), findsOneWidget);
      expect(find.text('Guest visitor'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Good food • New friends • Real connections'), findsOneWidget);
    });
  });

  group('đăng nhập giả lập', () {
    // Mở màn Tôi và bấm "Đăng nhập" để hiện bảng đăng nhập.
    Future<AppState> openLoginSheet(WidgetTester tester) async {
      final app = makeAppState();
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();
      return app;
    }

    testWidgets('bảng đăng nhập có đủ nội dung mục 4.7 SPEC',
        (WidgetTester tester) async {
      await openLoginSheet(tester);

      expect(find.text('Vào hội thôi!'), findsOneWidget);
      expect(
        find.text(
            'Đăng nhập để xem thành viên, tham gia bàn và trò chuyện. Đăng nhập không tự tham gia hay mở bàn.'),
        findsOneWidget,
      );
      expect(find.text('Tiếp tục với Google'), findsOneWidget);
      expect(find.text('Không cần mật khẩu. Chỉ cần một chiếc bụng đói.'), findsOneWidget);
      expect(find.text('Chính sách quyền riêng tư'), findsOneWidget);
      expect(find.text('Điều khoản sử dụng'), findsOneWidget);
    });

    testWidgets('đăng nhập xong ở lại đúng màn cũ và không tự tham gia/mở bàn',
        (WidgetTester tester) async {
      final app = await openLoginSheet(tester);
      // runAsync: repository dùng Future.delayed nên phải chạy ngoài đồng hồ giả của test
      Future<int> countTablesOfU1() async =>
          (await tester.runAsync(() => app.tableRepository.getMyTables('u1')))!
              .length;
      final before = await countTablesOfU1();
      expect(app.isLoggedIn, isFalse);

      await tester.tap(find.text('Tiếp tục với Google'));
      await tester.pumpAndSettle();

      // Bảng đã đóng, vẫn ở màn Hồ sơ, tab Tài khoản, hiện thông tin thành viên
      expect(find.text('Vào hội thôi!'), findsNothing);
      expect(find.text('Hồ sơ của bạn'), findsOneWidget);
      expect(find.text('Minh Anh'), findsOneWidget);
      expect(find.text('minhanh@example.com'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
      expect(find.text('Khách ghé chơi'), findsNothing);
      expect(app.isLoggedIn, isTrue);

      // Không có bàn nào được thêm/tham gia thay người dùng
      expect(await countTablesOfU1(), before);
    });

    testWidgets('đăng xuất quay lại trạng thái khách', (WidgetTester tester) async {
      await openLoginSheet(tester);
      await tester.tap(find.text('Tiếp tục với Google'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Đăng xuất')); // nút nằm dưới, cần cuộn tới
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(find.text('Khách ghé chơi'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
    });

    testWidgets('tab Bàn của tôi đổi nội dung theo khách/thành viên',
        (WidgetTester tester) async {
      await openLoginSheet(tester);
      await tester.tap(find.text('Tiếp tục với Google'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bàn của tôi'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập để xem những bàn ăn của bạn.'), findsNothing);
      expect(find.text('Danh sách bàn của bạn sẽ hiện ở đây.'), findsOneWidget);
    });

    testWidgets('bảng đăng nhập hiện bằng tiếng Anh khi đang chọn EN',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text("Let's get in!"), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('No password needed. Just an empty stomach.'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Use'), findsOneWidget);
    });
  });
}
