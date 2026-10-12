import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/mock/mock_support.dart';
import 'package:giua_ki_app/data/mock_dishes.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/state/app_state.dart';
import 'package:giua_ki_app/ui/components/dish_card.dart';
import 'package:giua_ki_app/ui/components/dish_picker.dart';
import 'package:giua_ki_app/ui/screens/profile_screen.dart';

import 'test_helpers.dart';

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
    expect(find.text('Mở bàn mới'), findsWidgets);
  });

  testWidgets('Lịch hẹn and Tôi open the right profile tab', (
    WidgetTester tester,
  ) async {
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

  testWidgets('Lịch hẹn and Tôi share one profile screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Lịch hẹn'));
    await tester.pumpAndSettle();
    final first = tester.state(find.byType(ProfileScreen));

    await tester.tap(find.text('Tôi'));
    await tester.pumpAndSettle();
    // Cùng một State: không dựng lại màn hình khi đổi giữa hai tab
    expect(tester.state(find.byType(ProfileScreen)), same(first));
  });

  testWidgets('Explore shows loading, then dishes, then filters by search', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Chọn món để lên kèo'), findsOneWidget);

    // Vừa mở: đang tải (khối chọn món và dải ba miền), chưa có món
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Phở'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Phở'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Phở'), findsNothing);
    expect(find.text('Không tìm thấy món phù hợp.'), findsOneWidget);
  });

  testWidgets('DishPicker shows error and retries', (
    WidgetTester tester,
  ) async {
    final repo = FakeDishRepository(fail: true);
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
    // tải đầu 100ms, gõ "phở" chậm 800ms, gõ "lẩu" nhanh 100ms.
    // Kết quả "phở" về sau cùng nhưng không được ghi đè kết quả "lẩu".
    final delays = [100, 800, 100];
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
    testWidgets('nút EN/VI đổi toàn bộ chữ ngay lập tức', (
      WidgetTester tester,
    ) async {
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

    testWidgets('màn Hồ sơ và thanh dưới cũng đổi ngôn ngữ', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(find.text('Your profile'), findsOneWidget);
      expect(find.text('Guest visitor'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(
        find.text('Good food • New friends • Real connections'),
        findsOneWidget,
      );
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
      await tester.ensureVisible(
        find.text('Đăng nhập'),
      ); // tiêu đề lớn đẩy nút xuống
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();
      return app;
    }

    testWidgets('bảng đăng nhập có đủ nội dung mục 4.7 SPEC', (
      WidgetTester tester,
    ) async {
      await openLoginSheet(tester);

      expect(find.text('Vào hội thôi!'), findsOneWidget);
      expect(
        find.text(
          'Đăng nhập để xem thành viên, tham gia bàn và trò chuyện. Đăng nhập không tự tham gia hay mở bàn.',
        ),
        findsOneWidget,
      );
      expect(find.text('Tiếp tục với Google'), findsOneWidget);
      expect(
        find.text('Không cần mật khẩu. Chỉ cần một chiếc bụng đói.'),
        findsOneWidget,
      );
      expect(find.text('Chính sách quyền riêng tư'), findsOneWidget);
      expect(find.text('Điều khoản sử dụng'), findsOneWidget);
    });

    testWidgets('đăng nhập xong ở lại đúng màn cũ và không tự tham gia/mở bàn', (
      WidgetTester tester,
    ) async {
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

    testWidgets('đăng xuất quay lại trạng thái khách', (
      WidgetTester tester,
    ) async {
      await openLoginSheet(tester);
      await tester.tap(find.text('Tiếp tục với Google'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.text('Đăng xuất'),
      ); // nút nằm dưới, cần cuộn tới
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      // Có hộp xác nhận
      expect(find.text('Đăng xuất?'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Đăng xuất'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Khách ghé chơi'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
    });

    testWidgets('tab Bàn của tôi đổi nội dung theo khách/thành viên', (
      WidgetTester tester,
    ) async {
      await openLoginSheet(tester);
      await tester.tap(find.text('Tiếp tục với Google'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Bàn của tôi')); // trang đã cuộn xuống ở bước trước
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bàn của tôi'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập để xem những bàn ăn của bạn.'), findsNothing);
      // Thành viên: danh sách bàn thật (u1 có sẵn một bàn sắp tới)
      expect(find.text('Sắp tới'), findsOneWidget);
    });

    testWidgets('bảng đăng nhập hiện bằng tiếng Anh khi đang chọn EN', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sign in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text("Let's get in!"), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(
        find.text('No password needed. Just an empty stomach.'),
        findsOneWidget,
      );
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Use'), findsOneWidget);
    });
  });

  group('Khám phá: tìm kiếm không dấu và thẻ món', () {
    phoneTest('gõ "banh xeo" ra Bánh xèo', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'banh xeo');
      await tester.pumpAndSettle();
      expect(find.text('Bánh xèo'), findsOneWidget);
      expect(find.text('Phở'), findsNothing);

      await tester.enterText(find.byType(TextField), 'PHO');
      await tester.pumpAndSettle();
      expect(find.text('Phở'), findsOneWidget);
      expect(find.text('Phở chay'), findsOneWidget);
    });

    phoneTest('bấm thẻ món mở màn chi tiết món , bấm Back quay lại', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Phở'));
      await tester.pumpAndSettle();
      expect(find.text('Bàn ăn cho món này'), findsOneWidget);
      expect(find.text('Phở'), findsNWidgets(2)); // tiêu đề AppBar + tên món
      expect(
        find.text('Nước dùng thơm, bánh phở mềm, một tô thật ấm bụng.'),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Bàn ăn cho món này'), findsNothing);
      expect(find.text('Chọn món để lên kèo'), findsOneWidget);
    });

    phoneTest('liên kết "Tìm bàn ăn" cũng mở màn chi tiết món', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tìm bàn ăn').first);
      await tester.pumpAndSettle();
      expect(find.text('Bàn ăn cho món này'), findsOneWidget);
    });

    phoneTest('thẻ món không đọc lặp tên món và không đọc emoji', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();
      final semantics = tester
          .ensureSemantics(); // bật cây ngữ nghĩa trong test

      final label = tester.getSemantics(find.byType(DishCard).first).label;
      expect(
        'Phở'.allMatches(label).length,
        1,
        reason: label,
      ); // tên món đúng một lần
      expect(label, isNot(contains('🍜')), reason: label); // emoji không bị đọc
      expect(label, contains('Bún & mì')); // nhãn danh mục vẫn được đọc

      semantics.dispose();
    });
  });

  group('bảng Bộ lọc & giờ ăn', () {
    // Mở màn Khám phá và bấm nút lọc.
    Future<AppState> openSheet(WidgetTester tester, {AppState? app}) async {
      final state = app ?? makeAppState();
      await tester.pumpWidget(MyApp(appState: state));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      return state;
    }

    // Cuộn tới chữ rồi bấm (bảng cao hơn khung nhìn nhỏ của test).
    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.pumpAndSettle();
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    phoneTest('có đủ các mục của mục 4.8 SPEC', (WidgetTester tester) async {
      await openSheet(tester);

      expect(find.text('Bộ lọc & giờ ăn'), findsOneWidget);
      expect(find.text('Buổi ăn'), findsOneWidget);
      for (final meal in ['Sáng', 'Trưa', 'Xế', 'Tối', 'Khuya']) {
        expect(find.text(meal), findsOneWidget, reason: meal);
      }
      expect(find.text('Bán kính tới quán'), findsOneWidget);
      for (final r in ['100 m', '500 m', '1 km', '10 km']) {
        expect(find.text(r), findsOneWidget, reason: r);
      }
      expect(find.text('Khung giờ'), findsOneWidget);
      expect(find.text('Từ'), findsOneWidget);
      expect(find.text('Đến'), findsOneWidget);
      expect(find.text('Bất kỳ'), findsWidgets);
      expect(
        find.text('Giờ Việt Nam · 30–120 phút · khung 15 phút'),
        findsOneWidget,
      );
      expect(find.text('Ngày'), findsOneWidget);
      expect(find.text('Hôm nay · 05/10'), findsOneWidget); // kèm ngày thực tế
      expect(find.text('Ngày mai · 06/10'), findsOneWidget);
      expect(find.text('Áp dụng'), findsOneWidget);
      expect(find.text('Đặt lại'), findsOneWidget);
    });

    phoneTest('mặc định: 1 km và Hôm nay được chọn, chưa chọn buổi ăn', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      ChoiceChip chip(String label) =>
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));
      expect(chip('1 km').selected, isTrue);
      expect(chip('100 m').selected, isFalse);
      expect(chip('Hôm nay · 05/10').selected, isTrue);
      for (final meal in ['Sáng', 'Trưa', 'Xế', 'Tối', 'Khuya']) {
        expect(chip(meal).selected, isFalse, reason: meal);
      }
    });

    phoneTest('Áp dụng ghi buổi ăn, bán kính, ngày vào AppState và đóng bảng', (
      WidgetTester tester,
    ) async {
      final app = await openSheet(tester);

      await tapText(tester, 'Sáng');
      await tapText(tester, '500 m');
      await tapText(tester, 'Ngày mai · 06/10');
      // Chưa áp dụng thì AppState chưa đổi
      expect(app.mealTime, isNull);
      expect(app.radiusM, 1000);

      await tapText(tester, 'Áp dụng');

      expect(find.text('Bộ lọc & giờ ăn'), findsNothing); // bảng đã đóng
      expect(app.mealTime, MealTime.morning);
      expect(app.radiusM, 500);
      expect(app.date, DateTime(2026, 10, 6));
      expect(app.hasActiveFilters, isTrue);
    });

    phoneTest('buổi ăn lọc món trên màn Khám phá theo mealTimes', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      await tapText(tester, 'Sáng');
      await tapText(tester, 'Áp dụng');

      // Phở có buổi sáng nên vẫn hiện; Lẩu không có buổi sáng nên biến mất
      expect(find.text('Phở'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'lau');
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy món phù hợp.'), findsOneWidget);

      // Bỏ lọc buổi ăn thì Lẩu hiện lại
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tapText(tester, 'Đặt lại');
      await tapText(tester, 'Áp dụng');
      expect(find.text('Lẩu'), findsOneWidget);
    });

    phoneTest('bấm lại buổi ăn đang chọn thì bỏ chọn', (
      WidgetTester tester,
    ) async {
      final app = await openSheet(tester);
      await tapText(tester, 'Tối');
      await tapText(tester, 'Tối');
      await tapText(tester, 'Áp dụng');
      expect(app.mealTime, isNull);
    });

    phoneTest(
      'Đặt lại đưa bản nháp về mặc định nhưng chỉ có hiệu lực khi Áp dụng',
      (WidgetTester tester) async {
        final app = makeAppState()
          ..applyFilters(
            mealTime: MealTime.evening,
            radiusM: 500,
            date: DateTime(2026, 10, 7),
            fromMinute: 17 * 60,
            toMinute: 20 * 60,
          );
        await openSheet(tester, app: app);

        // Mở lên phải phản ánh bộ lọc đang áp dụng
        ChoiceChip chip(String label) =>
            tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));
        expect(chip('Tối').selected, isTrue);
        expect(chip('500 m').selected, isTrue);
        expect(chip('T4 · 07/10').selected, isTrue);
        expect(find.text('17:00'), findsOneWidget); // giá trị "Từ"
        expect(find.text('20:00'), findsOneWidget); // giá trị "Đến"

        await tapText(tester, 'Đặt lại');
        expect(chip('Tối').selected, isFalse);
        expect(chip('1 km').selected, isTrue);
        expect(chip('Hôm nay · 05/10').selected, isTrue);
        expect(find.text('17:00'), findsNothing);
        // Chưa áp dụng: AppState còn nguyên
        expect(app.mealTime, MealTime.evening);
        expect(app.radiusM, 500);

        await tapText(tester, 'Áp dụng');
        expect(app.mealTime, isNull);
        expect(app.radiusM, 1000);
        expect(app.isDateDefault, isTrue);
        expect(app.fromMinute, isNull);
        expect(app.toMinute, isNull);
        expect(app.hasActiveFilters, isFalse);
      },
    );

    phoneTest('đóng bảng mà không bấm Áp dụng thì không đổi gì', (
      WidgetTester tester,
    ) async {
      final app = await openSheet(tester);
      await tapText(tester, 'Sáng');
      // Vuốt bảng xuống để đóng mà không bấm Áp dụng
      await tester.fling(
        find.text('Bộ lọc & giờ ăn'),
        const Offset(0, 800),
        2000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Bộ lọc & giờ ăn'), findsNothing);
      expect(app.mealTime, isNull);
    });

    phoneTest('khung giờ đã lưu có thể áp dụng lại không bị mất', (
      WidgetTester tester,
    ) async {
      final app = makeAppState()
        ..applyFilters(radiusM: 1000, fromMinute: 600, toMinute: 780);
      await openSheet(tester, app: app);
      await tapText(tester, 'Áp dụng');
      expect(app.fromMinute, 600);
      expect(app.toMinute, 780);
    });

    phoneTest('bảng lọc hiện bằng tiếng Anh khi chọn EN', (
      WidgetTester tester,
    ) async {
      final app = makeAppState()..setLanguage(AppLanguage.en);
      await openSheet(tester, app: app);

      expect(find.text('Filters & meal time'), findsOneWidget);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Late night'), findsOneWidget);
      expect(find.text('Distance to venue'), findsOneWidget);
      expect(find.text('Time window'), findsOneWidget);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);
      expect(find.text('Today · 05/10'), findsOneWidget);
      expect(find.text('Tomorrow · 06/10'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    phoneTest('nút lọc được tô sáng khi có bộ lọc khác mặc định', (
      WidgetTester tester,
    ) async {
      final app = makeAppState();
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();

      Color? filterButtonColor() => tester
          .widget<Material>(
            find
                .ancestor(
                  of: find.byIcon(Icons.tune),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color;
      expect(filterButtonColor(), Colors.white);

      app.setMealTime(MealTime.noon);
      await tester.pumpAndSettle();
      expect(filterButtonColor(), isNot(Colors.white));
    });

    phoneTest('màn Bàn ăn cũng dùng chung bảng lọc', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bàn ăn'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      expect(find.text('Bộ lọc & giờ ăn'), findsOneWidget);
    });
  });
}
