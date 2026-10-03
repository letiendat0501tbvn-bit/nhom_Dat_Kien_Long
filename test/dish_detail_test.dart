import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/models/dish.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/repositories/table_repository.dart';
import 'package:giua_ki_app/l10n/strings.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/state/app_scope.dart';
import 'package:giua_ki_app/state/app_state.dart';
import 'package:giua_ki_app/ui/components/table_card.dart';
import 'package:giua_ki_app/ui/screens/dish_detail_screen.dart';

import 'test_helpers.dart';

const tall = Size(412, 3500);

// Mở thẳng màn Chi tiết món của một món trong dữ liệu mẫu.
Future<AppState> pumpDetail(
  WidgetTester tester,
  String dishId, {
  AppState? app,
  bool area = true,
  bool login = false,
  bool scrollToTables = false,
}) async {
  final state = app ?? makeAppStateWithTables(standardTables());
  if (area) state.selectArea('hcm-q1');
  await tester.runAsync(state.load);
  if (login) await tester.runAsync(state.signIn);
  final dish = (await tester.runAsync(
    () => state.dishRepository.getDish(dishId),
  ))!;
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(
        home: DishDetailScreen(dish: dish, scrollToTables: scrollToTables),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return state;
}

List<String> shown(WidgetTester tester) => tester
    .widgetList<TableCard>(find.byType(TableCard))
    .map((c) => c.table.id)
    .toList();

Finder inCard(String id, String text) =>
    find.descendant(of: find.byKey(ValueKey(id)), matching: find.text(text));

void main() {
  group('AppState.dishesByIds (bộ đệm món)', () {
    test('chỉ hỏi repository những id chưa có, lần sau dùng bộ đệm', () async {
      final repo = FakeDishRepository(dishes: [_dish('a'), _dish('b')]);
      final app = makeAppStateWithTables(const [], dishRepository: repo);
      addTearDown(app.dispose);

      final first = await app.dishesByIds(['a', 'b']);
      expect(first.keys.toSet(), {'a', 'b'});
      expect(repo.getDishCalls, 2);

      final again = await app.dishesByIds(['b', 'a', 'a']);
      expect(again.keys.toSet(), {'a', 'b'});
      expect(repo.getDishCalls, 2); // không gọi thêm

      await app.dishesByIds(['a', 'zzz']); // chỉ id mới 'zzz' bị hỏi
      expect(repo.getDishCalls, 3);
    });

    test('id không tồn tại bị bỏ qua; danh sách rỗng không gọi gì', () async {
      final repo = FakeDishRepository(dishes: [_dish('a')]);
      final app = makeAppStateWithTables(const [], dishRepository: repo);
      addTearDown(app.dispose);

      expect(await app.dishesByIds(['x']), isEmpty);
      expect(await app.dishesByIds(const []), isEmpty);
      expect(repo.getDishCalls, 1);
      // Id không có thì lần sau hỏi lại (có thể món mới xuất hiện)
      await app.dishesByIds(['x']);
      expect(repo.getDishCalls, 2);
    });
  });

  group('Chi tiết món: nội dung', () {
    phoneTest('hiện ảnh có nhãn, tên, danh mục, mô tả, vùng, hashtag (vi)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpDetail(tester, 'banh-xeo', area: false);

      expect(find.text('Bánh xèo'), findsNWidgets(2)); // AppBar + tên
      expect(find.bySemanticsLabel('Bánh xèo'), findsWidgets);
      expect(find.text('Bàn ăn cho món này'), findsOneWidget);
      expect(find.text('#CrispyPancakes'), findsOneWidget);
      expect(find.text('Hương vị ba miền'), findsOneWidget);
      handle.dispose();
    }, size: tall);

    phoneTest('thẻ khẩu vị và tâm trạng được dịch VI/EN', (tester) async {
      final dish = const Dish(
        id: 'x',
        name: 'Món thử',
        category: 'Bún & mì',
        description: 'Mô tả thử',
        emoji: '🍜',
        tint: 0xFFEEEEEE,
        tastes: [Taste.spicy, Taste.sweet],
        moods: [Mood.cozy],
      );
      final app = makeAppState();
      app.selectArea('hcm-q1');
      Future<void> pump() async {
        await tester.pumpWidget(
          AppScope(
            state: app,
            child: MaterialApp(home: DishDetailScreen(dish: dish)),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pump();
      var t = app.strings;
      expect(find.text(t(StrKey.dishTastes)), findsOneWidget);
      expect(find.text(t(StrKey.dishMoods)), findsOneWidget);
      expect(find.text(t.tasteLabel(Taste.spicy)), findsOneWidget);
      expect(find.text(t.tasteLabel(Taste.sweet)), findsOneWidget);
      expect(find.text(t.moodLabel(Mood.cozy)), findsOneWidget);

      app.setLanguage(AppLanguage.en);
      await tester.pumpAndSettle();
      t = app.strings;
      expect(find.text('Flavors'), findsOneWidget);
      expect(find.text('Moods'), findsOneWidget);
      expect(find.text(t.tasteLabel(Taste.spicy)), findsOneWidget);
      expect(find.text(t.moodLabel(Mood.cozy)), findsOneWidget);
      expect(find.text('Tables for this dish'), findsOneWidget);
      expect(
        t.tasteLabel(Taste.spicy),
        isNot(app.strings.tasteLabel(Taste.sweet)),
      );
    }, size: tall);

    phoneTest('món không có khẩu vị/tâm trạng/vùng thì không hiện nhóm trống', (
      tester,
    ) async {
      final app = makeAppState();
      await tester.pumpWidget(
        AppScope(
          state: app,
          child: const MaterialApp(
            home: DishDetailScreen(
              dish: Dish(
                id: 'x',
                name: 'Món trơn',
                category: 'Bún & mì',
                description: 'Mô tả',
                emoji: '🍜',
                tint: 0xFFEEEEEE,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Khẩu vị'), findsNothing);
      expect(find.text('Tâm trạng'), findsNothing);
      expect(find.byIcon(Icons.place_outlined), findsNothing);
    }, size: tall);

    phoneTest('nút Back quay về màn trước', (tester) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phở'));
      await tester.pumpAndSettle();
      expect(find.byType(DishDetailScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DishDetailScreen), findsNothing);
    });
  });

  group('Chi tiết món: bàn ăn của món', () {
    phoneTest(
      'chưa chọn khu vực → thẻ "Chọn khu vực" → chọn xong thấy ngay bàn của đúng món',
      (tester) async {
        final app = await pumpDetail(tester, 'pho', area: false);
        expect(find.text('Chọn khu vực'), findsWidgets);
        expect(find.byType(TableCard), findsNothing);

        await tester.tap(find.widgetWithText(FilledButton, 'Chọn khu vực'));
        await tester.pumpAndSettle();
        expect(find.text('Vị trí của bạn'), findsOneWidget);

        await tester.tap(find.text('Quận 1'));
        await tester.pumpAndSettle();

        // Vẫn ở màn này, bảng đã đóng, chỉ có bàn Phở còn hiệu lực (ta)
        expect(find.byType(DishDetailScreen), findsOneWidget);
        expect(find.text('Vị trí của bạn'), findsNothing);
        expect(app.selectedAreaId, 'hcm-q1');
        expect(shown(tester), ['ta']);
        expect(inCard('ta', 'Còn 2/4 chỗ'), findsOneWidget);
      },
      size: tall,
    );

    phoneTest('chỉ hiện bàn của món này, không lẫn món khác', (tester) async {
      await pumpDetail(tester, 'banh-xeo');
      expect(shown(tester), ['td']);
    }, size: tall);

    phoneTest('bàn đã đầy hiện "Đã đầy"', (tester) async {
      await pumpDetail(tester, 'lau');
      expect(shown(tester), ['tb']);
      expect(inCard('tb', 'Đã đầy'), findsOneWidget);
    }, size: tall);

    phoneTest('đổi bộ lọc trong AppState thì danh sách tải lại ngay', (
      tester,
    ) async {
      final app = await pumpDetail(tester, 'com-tam'); // bàn ở ngày mai
      expect(shown(tester), isEmpty);

      app.setDate(DateTime(2026, 10, 6));
      await tester.pumpAndSettle();
      expect(shown(tester), ['tf']);
    }, size: tall);

    phoneTest('truy vấn gửi đi mang đúng món và khu vực', (tester) async {
      final repo = ThrowingTableRepository(tables: [standardTables().first]);
      final app = makeAppStateWithTables(const [], tableRepository: repo);
      await pumpDetail(tester, 'pho', app: app);
      expect(repo.listCalls, 1);
      expect(repo.lastQuery?.dishId, 'pho');
      expect(repo.lastQuery?.areaId, 'hcm-q1');
    }, size: tall);

    phoneTest('mở lại danh sách không nạp lại món đã có trong bộ đệm', (
      tester,
    ) async {
      final repo = FakeDishRepository(dishes: [_dish('pho', name: 'Phở')]);
      final app = makeAppStateWithTables(
        standardTables(),
        dishRepository: repo,
      );
      await pumpDetail(tester, 'pho', app: app);
      expect(repo.calls, 0); // không bao giờ nạp cả danh sách món
      final first = repo.getDishCalls;

      // Đổi ngày rồi quay lại: món 'pho' lấy từ bộ đệm
      app.setDate(DateTime(2026, 10, 6));
      await tester.pumpAndSettle();
      app.setDate(null);
      await tester.pumpAndSettle();
      expect(repo.calls, 0);
      expect(repo.getDishCalls, first);
    }, size: tall);

    phoneTest('đang tải hiện vòng xoay; lỗi hiện nút Thử lại và thử lại được', (
      tester,
    ) async {
      final repo = ThrowingTableRepository(failList: true);
      final app = makeAppStateWithTables(const [], tableRepository: repo);
      await pumpDetail(tester, 'pho', app: app);
      expect(
        find.text(
          'Không tải được danh sách bàn. Kiểm tra mạng rồi thử lại nhé.',
        ),
        findsOneWidget,
      );

      repo.failList = false;
      repo.tables = [standardTables().first];
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(shown(tester), ['ta']);
    }, size: tall);

    phoneTest('trạng thái rỗng: câu riêng cho món + 3 nút', (tester) async {
      await pumpDetail(tester, 'com-tam');
      expect(
        find.text('Chưa có bàn nào cho món này quanh đây.'),
        findsOneWidget,
      );
      expect(find.text('Xem ngày mai'), findsOneWidget);
      expect(find.text('Nới bán kính lên 10 km'), findsOneWidget);
      expect(find.text('Mở bàn mới với món này'), findsOneWidget);
    }, size: tall);

    phoneTest('rỗng: "Xem ngày mai" hiện bàn của ngày mai', (tester) async {
      await pumpDetail(tester, 'com-tam');
      await tester.tap(find.text('Xem ngày mai'));
      await tester.pumpAndSettle();
      expect(shown(tester), ['tf']);
    }, size: tall);

    phoneTest('trạng thái rỗng bằng tiếng Anh', (tester) async {
      final app = makeAppStateWithTables(standardTables())
        ..setLanguage(AppLanguage.en);
      await pumpDetail(tester, 'com-tam', app: app);
      expect(
        find.text('No tables for this dish around here yet.'),
        findsOneWidget,
      );
      expect(find.text('Open a new table with this dish'), findsOneWidget);
    }, size: tall);

    phoneTest('có bàn thì không hiện nút "Mở bàn mới"', (tester) async {
      await pumpDetail(tester, 'pho');
      expect(find.text('Mở bàn mới với món này'), findsNothing);
    }, size: tall);
  });

  group('Chi tiết món: tham gia', () {
    phoneTest(
      'khách bấm Tham gia → đăng nhập → quay lại đúng màn, chưa tự tham gia',
      (tester) async {
        final app = await pumpDetail(tester, 'pho');
        await tester.tap(inCard('ta', 'Tham gia'));
        await tester.pumpAndSettle();
        expect(find.text('Vào hội thôi!'), findsOneWidget);

        await tester.tap(find.text('Tiếp tục với Google'));
        await tester.pumpAndSettle();

        expect(find.text('Vào hội thôi!'), findsNothing);
        expect(find.byType(DishDetailScreen), findsOneWidget);
        expect(app.isLoggedIn, isTrue);
        final table = await tester.runAsync(
          () => app.tableRepository.getTable('ta'),
        );
        expect(table!.memberIds, ['u2', 'u3']);
        expect(inCard('ta', 'Tham gia'), findsOneWidget);
      },
      size: tall,
    );

    phoneTest(
      'thành viên bấm Tham gia: số chỗ cập nhật ngay, nút thành Đã tham gia',
      (tester) async {
        await pumpDetail(tester, 'pho', login: true);
        await tester.tap(inCard('ta', 'Tham gia'));
        await tester.pumpAndSettle();
        expect(inCard('ta', 'Còn 1/4 chỗ'), findsOneWidget);
        expect(inCard('ta', 'Đã tham gia'), findsOneWidget);
        expect(
          find.text('Đã tham gia bàn. Hẹn gặp bạn tại quán!'),
          findsOneWidget,
        );
      },
      size: tall,
    );

    phoneTest('lỗi trùng giờ hiện thông báo riêng', (tester) async {
      // u1 đã ở bàn tc (14:00); td (Bánh xèo 14:30) trùng giờ
      await pumpDetail(tester, 'banh-xeo', login: true);
      await tester.tap(inCard('td', 'Tham gia'));
      await tester.pumpAndSettle();
      expect(find.text(app0().tableError(TableError.overlap)), findsOneWidget);
    }, size: tall);
  });

  group('Mở màn từ nơi khác', () {
    phoneTest('"Tìm bàn ăn" ở thẻ món mở màn và cuộn tới phần bàn ăn', (
      tester,
    ) async {
      final app = makeAppState()..selectArea('hcm-q1');
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tìm bàn ăn').first);
      await tester.pumpAndSettle();

      expect(find.byType(DishDetailScreen), findsOneWidget);
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(DishDetailScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrollable.position.pixels, greaterThan(0));
      // Tiêu đề phần bàn ăn nằm trong khung nhìn
      final y = tester.getTopLeft(find.text('Bàn ăn cho món này')).dy;
      expect(y, inInclusiveRange(0, 700));
    }, size: const Size(412, 700));

    phoneTest('bấm thẻ món (không phải nút) thì mở từ đầu trang', (
      tester,
    ) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phở'));
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(DishDetailScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrollable.position.pixels, 0);
    }, size: const Size(412, 700));

    phoneTest('thẻ ở dải ba miền mở màn chi tiết và cuộn tới phần bàn ăn', (
      tester,
    ) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();
      final card = find.text('#HanoiClassic').first;
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(DishDetailScreen), findsOneWidget);
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(DishDetailScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrollable.position.pixels, greaterThan(0));
    }, size: const Size(412, 700));
  });

  group('Chi tiết món: không tràn dòng', () {
    for (final language in AppLanguage.values) {
      for (final scale in [1.0, 1.3]) {
        for (final width in [360.0, 412.0]) {
          phoneTest('${language.name}, chữ x$scale, rộng ${width.toInt()}', (
            tester,
          ) async {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.platformDispatcher.clearAllTestValues);

            final app = makeAppStateWithTables(standardTables())
              ..setLanguage(language);
            // Món có đủ vùng, hashtag, khẩu vị, tâm trạng nếu có; có bàn
            await pumpDetail(tester, 'banh-xeo', app: app, login: true);
            expect(find.byType(TableCard), findsOneWidget);

            // Chưa chọn khu vực
            app.selectArea(null);
            await tester.pumpAndSettle();
            expect(find.byType(TableCard), findsNothing);

            // Trạng thái rỗng (ba nút)
            app.selectArea('hcm-q1');
            app.setRadius(100);
            await tester.pumpAndSettle();
            expect(find.byType(TableCard), findsNothing);
            expect(
              find.text(app.strings(StrKey.openTableWithDish)),
              findsOneWidget,
            );
          }, size: Size(width, 3500));
        }
      }
    }
  });
}

Dish _dish(String id, {String name = 'Món'}) => Dish(
  id: id,
  name: name,
  category: 'Bún & mì',
  description: 'Mô tả',
  emoji: '🍜',
  tint: 0xFFEEEEEE,
);

Strings app0() => const Strings(AppLanguage.vi);
