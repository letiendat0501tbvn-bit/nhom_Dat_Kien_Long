import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/models/dining_table.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/repositories/table_repository.dart';
import 'package:giua_ki_app/l10n/strings.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/state/app_state.dart';
import 'package:giua_ki_app/ui/components/table_card.dart';
import 'package:giua_ki_app/ui/components/table_list.dart';

import 'test_helpers.dart';

// Khung rất cao để mọi thẻ được dựng cùng lúc.
const tall = Size(412, 3500);

// Mở app ở tab Bàn ăn. area: chọn sẵn Quận 1; login: đăng nhập sẵn (Minh Anh = u1).
Future<AppState> pumpTables(
  WidgetTester tester, {
  AppState? app,
  bool area = true,
  bool login = false,
}) async {
  final state = app ?? makeAppStateWithTables(standardTables());
  if (area) state.selectArea('hcm-q1');
  await tester.pumpWidget(MyApp(appState: state));
  await tester.pumpAndSettle();
  if (login) {
    // runAsync: repository dùng Future.delayed nên phải chạy ngoài đồng hồ giả của test
    await tester.runAsync(state.signIn);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text(state.strings(StrKey.tabTables)));
  await tester.pumpAndSettle();
  return state;
}

// Id các bàn đang hiện, theo thứ tự trên màn hình.
List<String> shown(WidgetTester tester) => tester
    .widgetList<TableCard>(find.byType(TableCard))
    .map((c) => c.table.id)
    .toList();

// Tìm chữ nằm bên trong thẻ của một bàn.
Finder inCard(String id, String text) =>
    find.descendant(of: find.byKey(ValueKey(id)), matching: find.text(text));

Future<List<String>?> membersOf(
  WidgetTester tester,
  AppState app,
  String id,
) async {
  final table = await tester.runAsync(() => app.tableRepository.getTable(id));
  return table?.memberIds;
}

void main() {
  group('Bàn ăn: chưa chọn khu vực', () {
    phoneTest('hiện thẻ "Chọn khu vực" như ảnh thiết kế, chưa có danh sách', (
      tester,
    ) async {
      await pumpTables(tester, area: false);

      expect(find.text('Bàn còn chỗ'), findsOneWidget);
      expect(
        find.text('Chọn điểm hẹn tại quán và giờ ăn phù hợp.'),
        findsOneWidget,
      );
      expect(find.text('Chọn khu vực'), findsNWidgets(2)); // tiêu đề thẻ + nút
      expect(
        find.text('Dùng vị trí để tìm điểm hẹn tại quán.'),
        findsOneWidget,
      );
      expect(find.byType(TableList), findsNothing);
      expect(find.byType(TableCard), findsNothing);
      expect(find.text('Chọn vị trí'), findsOneWidget); // nút trên top bar
      // Phần "Chọn món để lên kèo" vẫn còn bên dưới
      expect(find.text('Chọn món để lên kèo'), findsOneWidget);
    }, size: tall);

    phoneTest('nút "Chọn khu vực" trong thẻ mở bảng chọn khu vực', (
      tester,
    ) async {
      await pumpTables(tester, area: false);
      await tester.tap(find.widgetWithText(FilledButton, 'Chọn khu vực'));
      await tester.pumpAndSettle();
      expect(find.text('Vị trí của bạn'), findsOneWidget);
    }, size: tall);

    phoneTest('nút "Chọn vị trí" ở top bar mở bảng chọn khu vực', (
      tester,
    ) async {
      await pumpTables(tester, area: false);
      await tester.tap(find.text('Chọn vị trí'));
      await tester.pumpAndSettle();
      expect(find.text('Vị trí của bạn'), findsOneWidget);
    }, size: tall);

    phoneTest('nút "Chọn vị trí" cũng mở bảng ở tab Khám phá', (tester) async {
      final app = makeAppStateWithTables(standardTables());
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn vị trí'));
      await tester.pumpAndSettle();
      expect(find.text('Vị trí của bạn'), findsOneWidget);
    }, size: tall);
  });

  group('Bảng "Vị trí của bạn"', () {
    Future<AppState> openSheet(WidgetTester tester, {AppState? app}) async {
      final state = await pumpTables(tester, app: app, area: false);
      await tester.tap(
        find.text(
          state.selectedArea == null
              ? state.strings(StrKey.chooseLocation)
              : state.selectedArea!.district,
        ),
      );
      await tester.pumpAndSettle();
      return state;
    }

    phoneTest('có đủ nội dung gốc và 8 khu vực của mục 4.9 SPEC', (
      tester,
    ) async {
      await openSheet(tester);

      expect(find.text('Vị trí của bạn'), findsOneWidget);
      expect(
        find.text(
          'Cho phép vị trí để tìm điểm hẹn tại quán gần đây. Vị trí không được dùng để ghép người và không hiển thị cho người khác.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cho phép vị trí'), findsOneWidget);
      expect(find.text('Để sau'), findsOneWidget);
      expect(find.text('Hoặc chọn khu vực'), findsOneWidget);
      expect(
        find.text('Dùng tâm khu vực đã chọn để tìm kiếm.'),
        findsOneWidget,
      );

      // Thành phố và quận theo đúng SPEC
      const expected = {
        'Hồ Chí Minh': ['Quận 1', 'Bình Thạnh', 'Thủ Đức'],
        'Hà Nội': ['Hoàn Kiếm'],
        'Đà Nẵng': ['Hải Châu'],
        'Huế': ['Phú Hội'],
        'Hội An': ['Minh An'],
        'Cần Thơ': ['Ninh Kiều'],
      };
      var districts = 0;
      expected.forEach((city, list) {
        expect(find.text(city), findsOneWidget, reason: city);
        for (final district in list) {
          expect(find.text(district), findsOneWidget, reason: district);
          districts++;
        }
      });
      expect(districts, 8);
      expect(find.byType(ChoiceChip), findsNWidgets(8));
    }, size: tall);

    phoneTest(
      'chọn một khu vực: ghi vào AppState, đóng bảng, top bar đổi tên',
      (tester) async {
        final app = await openSheet(tester);

        await tester.tap(find.text('Hoàn Kiếm'));
        await tester.pumpAndSettle();

        expect(find.text('Vị trí của bạn'), findsNothing); // đã đóng
        expect(app.selectedAreaId, 'hn-hoan-kiem');
        expect(app.selectedArea?.label, 'Hà Nội · Hoàn Kiếm');
        expect(find.text('Chọn vị trí'), findsNothing);
        expect(
          find.text('Hoàn Kiếm'),
          findsWidgets,
        ); // tên khu vực trên top bar
        expect(
          find.byType(TableList),
          findsOneWidget,
        ); // chuyển sang danh sách bàn
        expect(
          find.text('Dùng vị trí để tìm điểm hẹn tại quán.'),
          findsNothing,
        );
      },
      size: tall,
    );

    phoneTest(
      '"Cho phép vị trí" chỉ báo sẽ có ở bản sau, không đóng bảng, không chọn khu vực',
      (tester) async {
        final app = await openSheet(tester);
        expect(find.text('Tính năng này sẽ có ở bản sau.'), findsNothing);

        await tester.tap(find.text('Cho phép vị trí'));
        await tester.pumpAndSettle();

        expect(find.text('Tính năng này sẽ có ở bản sau.'), findsOneWidget);
        expect(find.text('Vị trí của bạn'), findsOneWidget); // bảng vẫn mở
        expect(app.selectedAreaId, isNull);
        expect(
          app.settings.useDeviceLocation,
          isFalse,
        ); // chưa dùng vị trí thật
      },
      size: tall,
    );

    phoneTest('"Để sau" đóng bảng và không đổi gì', (tester) async {
      final app = await openSheet(tester);
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();

      expect(find.text('Vị trí của bạn'), findsNothing);
      expect(app.selectedAreaId, isNull);
      expect(find.text('Chọn vị trí'), findsOneWidget);
    }, size: tall);

    phoneTest(
      'mở lại: khu vực đang chọn được tô sáng; "Bỏ chọn khu vực" quay về thẻ ban đầu',
      (tester) async {
        final app = await openSheet(tester);
        await tester.tap(find.text('Quận 1'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Quận 1').first); // nút trên top bar
        await tester.pumpAndSettle();
        final chip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Quận 1'),
        );
        expect(chip.selected, isTrue);
        expect(find.text('Bỏ chọn khu vực'), findsOneWidget);

        await tester.tap(find.text('Bỏ chọn khu vực'));
        await tester.pumpAndSettle();
        expect(app.selectedAreaId, isNull);
        expect(find.text('Chọn vị trí'), findsOneWidget);
        expect(find.byType(TableList), findsNothing);
        expect(find.text('Chọn khu vực'), findsNWidgets(2));
      },
      size: tall,
    );

    phoneTest('chưa chọn khu vực thì không có nút "Bỏ chọn khu vực"', (
      tester,
    ) async {
      await openSheet(tester);
      expect(find.text('Bỏ chọn khu vực'), findsNothing);
    }, size: tall);

    phoneTest('hiện bằng tiếng Anh khi chọn EN', (tester) async {
      final app = makeAppStateWithTables(standardTables())
        ..setLanguage(AppLanguage.en);
      await pumpTables(tester, app: app, area: false);
      await tester.tap(find.text('Choose location'));
      await tester.pumpAndSettle();

      expect(find.text('Your location'), findsOneWidget);
      expect(find.text('Allow location'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      expect(find.text('Or choose an area'), findsOneWidget);
      expect(
        find.text("We'll search around the center of the area you pick."),
        findsOneWidget,
      );
      await tester.tap(find.text('Allow location'));
      await tester.pumpAndSettle();
      expect(
        find.text('This feature will be available in a later version.'),
        findsOneWidget,
      );
    }, size: tall);
  });

  group('Bàn ăn: danh sách bàn', () {
    phoneTest(
      'đã chọn khu vực: hiện đúng các bàn còn hiệu lực hôm nay, theo giờ',
      (tester) async {
        await pumpTables(tester);

        // te đã bắt đầu, th đã huỷ, tf là ngày mai nên đều không hiện
        expect(shown(tester), ['ta', 'tb', 'tc', 'td', 'tg']);
        expect(
          find.text('Chọn khu vực'),
          findsNothing,
        ); // thẻ chọn khu vực đã biến mất
        expect(
          find.text('Chọn món để lên kèo'),
          findsOneWidget,
        ); // phần món vẫn còn
      },
      size: tall,
    );

    phoneTest('thẻ bàn có món, quán, giờ, chỗ và nút', (tester) async {
      await pumpTables(tester);

      expect(inCard('ta', 'Phở'), findsOneWidget);
      expect(inCard('ta', 'Quán Nhà Lá'), findsOneWidget);
      expect(inCard('ta', '11:00–12:00 · Hôm nay · 05/10'), findsOneWidget);
      expect(inCard('ta', 'Còn 2/4 chỗ'), findsOneWidget);
      expect(inCard('ta', 'Tham gia'), findsOneWidget);

      expect(inCard('tb', 'Lẩu'), findsOneWidget);
      expect(inCard('tb', 'Đủ 2/2 chỗ'), findsOneWidget);
      expect(inCard('tb', 'Đã đầy'), findsOneWidget);
      expect(inCard('tb', 'Tham gia'), findsNothing);

      expect(
        inCard('tc', 'Chưa chọn món'),
        findsOneWidget,
      ); // bàn chưa chọn món
      expect(inCard('tc', 'Tiệm Hẻm Nhỏ'), findsOneWidget);
      expect(inCard('tc', '14:00–15:00 · Hôm nay · 05/10'), findsOneWidget);
    }, size: tall);

    phoneTest(
      'có ảnh đại diện thành viên ẩn danh (không lộ tên) và "+N" khi đông',
      (tester) async {
        await pumpTables(tester);

        // ta có 2 thành viên: 2 biểu tượng người, không có "+N"
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('ta')),
            matching: find.byIcon(Icons.person),
          ),
          findsNWidgets(2),
        );
        expect(inCard('ta', '+1'), findsNothing);
        // Khách không thấy tên thành viên
        expect(find.text('Minh Anh'), findsNothing);
        expect(find.text('Quốc Bảo'), findsNothing);
      },
      size: tall,
    );

    phoneTest('bàn đông hơn 3 người hiện tối đa 3 ảnh và "+N"', (tester) async {
      final big = makeTable(
        'tz',
        dishId: 'pho',
        start: DateTime(2026, 10, 5, 12, 0),
        capacity: 8,
        members: ['u1', 'u2', 'u3', 'u4', 'u5'],
      );
      await pumpTables(tester, app: makeAppStateWithTables([big]));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('tz')),
          matching: find.byIcon(Icons.person),
        ),
        findsNWidgets(3),
      );
      expect(inCard('tz', '+2'), findsOneWidget);
    }, size: tall);

    phoneTest('giờ và nhãn hiện theo tiếng Anh khi chọn EN', (tester) async {
      final app = makeAppStateWithTables(standardTables())
        ..setLanguage(AppLanguage.en);
      await pumpTables(tester, app: app);

      expect(inCard('ta', '11:00 AM–12:00 PM · Today · 05/10'), findsOneWidget);
      expect(inCard('ta', '2/4 seats left'), findsOneWidget);
      expect(inCard('ta', 'Join'), findsOneWidget);
      expect(inCard('tb', 'Full'), findsOneWidget);
      expect(inCard('tb', '2/2 seats taken'), findsOneWidget);
      expect(inCard('tc', 'No dish chosen yet'), findsOneWidget);
      expect(inCard('tc', '2:00 PM–3:00 PM · Today · 05/10'), findsOneWidget);
      expect(find.text('Tables with seats'), findsOneWidget);
    }, size: tall);

    phoneTest('đã đăng nhập: bàn mình ở trong hiện "Đã tham gia"', (
      tester,
    ) async {
      await pumpTables(tester, login: true); // u1 có trong tc
      expect(inCard('tc', 'Đã tham gia'), findsOneWidget);
      expect(inCard('tc', 'Tham gia'), findsNothing);
      expect(inCard('ta', 'Tham gia'), findsOneWidget);
      expect(inCard('tb', 'Đã đầy'), findsOneWidget);
    }, size: tall);

    phoneTest('bàn đã đầy mà mình ở trong thì vẫn là "Đã tham gia"', (
      tester,
    ) async {
      final tables = [
        makeTable(
          'tx',
          dishId: 'pho',
          start: DateTime(2026, 10, 5, 12, 0),
          capacity: 2,
          members: ['u1', 'u2'],
        ),
      ];
      await pumpTables(
        tester,
        app: makeAppStateWithTables(tables),
        login: true,
      );
      expect(inCard('tx', 'Đã tham gia'), findsOneWidget);
      expect(inCard('tx', 'Đã đầy'), findsNothing);
      expect(inCard('tx', 'Đủ 2/2 chỗ'), findsOneWidget);
    }, size: tall);

    phoneTest('thẻ tóm tắt: khu vực và bộ lọc đang dùng', (tester) async {
      final app = await pumpTables(tester);
      expect(find.text('Hồ Chí Minh · Quận 1'), findsOneWidget);
      expect(find.text('1 km · Hôm nay · 05/10'), findsOneWidget);

      app
        ..setMealTime(MealTime.noon)
        ..setTimeWindow(fromMinute: 12 * 60, toMinute: 15 * 60);
      await tester.pumpAndSettle();
      expect(
        find.text('1 km · Hôm nay · 05/10 · Trưa · 12:00–15:00'),
        findsOneWidget,
      );
    }, size: tall);

    phoneTest('nút "Đổi" mở bảng khu vực, nút lọc mở bảng "Bộ lọc & giờ ăn"', (
      tester,
    ) async {
      await pumpTables(tester);
      await tester.tap(find.text('Đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Vị trí của bạn'), findsOneWidget);
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Bộ lọc & giờ ăn'));
      await tester.pumpAndSettle();
      expect(find.text('Buổi ăn'), findsOneWidget);
    }, size: tall);
  });

  group('Bàn ăn: lọc theo AppState', () {
    phoneTest('bán kính: 100 m không có bàn nào, 500 m bỏ bàn ở quán xa hơn', (
      tester,
    ) async {
      final app = await pumpTables(tester);
      expect(shown(tester), ['ta', 'tb', 'tc', 'td', 'tg']); // 1 km

      app.setRadius(500); // quán q1-4 cách khoảng 660 m
      await tester.pumpAndSettle();
      expect(shown(tester), ['ta', 'tb', 'tc', 'td']);

      app.setRadius(100); // quán gần nhất cách khoảng 167 m
      await tester.pumpAndSettle();
      expect(shown(tester), isEmpty);
      expect(
        find.text('Chưa có bàn nào quanh đây. Mở bàn mới nhé?'),
        findsOneWidget,
      );

      app.setRadius(10000);
      await tester.pumpAndSettle();
      expect(shown(tester), ['ta', 'tb', 'tc', 'td', 'tg']);
    }, size: tall);

    phoneTest('buổi ăn: trưa, xế, tối', (tester) async {
      final app = await pumpTables(tester);

      app.setMealTime(MealTime.noon); // 11:00 và 12:00
      await tester.pumpAndSettle();
      expect(shown(tester), ['ta', 'tb']);

      app.setMealTime(MealTime.afternoon); // 14:00 và 14:30
      await tester.pumpAndSettle();
      expect(shown(tester), ['tc', 'td']);

      app.setMealTime(MealTime.evening); // 18:00
      await tester.pumpAndSettle();
      expect(shown(tester), ['tg']);

      app.setMealTime(
        MealTime.morning,
      ); // không có bàn buổi sáng hôm nay (còn hiệu lực)
      await tester.pumpAndSettle();
      expect(shown(tester), isEmpty);

      app.setMealTime(null);
      await tester.pumpAndSettle();
      expect(shown(tester), ['ta', 'tb', 'tc', 'td', 'tg']);
    }, size: tall);

    phoneTest('khung giờ Từ–Đến (gồm cả hai đầu)', (tester) async {
      final app = await pumpTables(tester);

      app.setTimeWindow(fromMinute: 12 * 60, toMinute: 15 * 60);
      await tester.pumpAndSettle();
      expect(shown(tester), ['tb', 'tc', 'td']);

      app.setTimeWindow(fromMinute: 17 * 60); // chỉ có đầu "từ"
      await tester.pumpAndSettle();
      expect(shown(tester), ['tg']);

      app.setTimeWindow(toMinute: 11 * 60); // chỉ có đầu "đến"
      await tester.pumpAndSettle();
      expect(shown(tester), ['ta']);
    }, size: tall);

    phoneTest('ngày: tab Hôm nay / Ngày mai đổi danh sách', (tester) async {
      final app = await pumpTables(tester);
      expect(find.text('Hôm nay · 05/10'), findsOneWidget);
      expect(find.text('Ngày mai · 06/10'), findsOneWidget);

      await tester.tap(find.text('Ngày mai · 06/10'));
      await tester.pumpAndSettle();
      expect(app.date, DateTime(2026, 10, 6));
      expect(shown(tester), ['tf']);
      expect(inCard('tf', 'Cơm tấm'), findsOneWidget);
      expect(inCard('tf', '08:00–09:00 · Ngày mai · 06/10'), findsOneWidget);

      await tester.tap(find.text('Hôm nay · 05/10'));
      await tester.pumpAndSettle();
      expect(app.isDateDefault, isTrue);
      expect(shown(tester), ['ta', 'tb', 'tc', 'td', 'tg']);
    }, size: tall);

    phoneTest(
      'ngày chọn trong bảng lọc: không tab nào được chọn nhưng danh sách đúng',
      (tester) async {
        final app = await pumpTables(tester);
        app.setDate(DateTime(2026, 10, 8));
        await tester.pumpAndSettle();
        expect(shown(tester), isEmpty); // không có bàn nào ngày 08/10
        expect(find.text('Xem hôm nay'), findsOneWidget);
      },
      size: tall,
    );

    phoneTest('đổi khu vực sang nơi không có bàn thì rỗng', (tester) async {
      final app = await pumpTables(tester);
      app.selectArea('ha-minh-an');
      await tester.pumpAndSettle();
      expect(shown(tester), isEmpty);
      expect(
        find.text('Chưa có bàn nào quanh đây. Mở bàn mới nhé?'),
        findsOneWidget,
      );
      expect(find.text('Hội An · Minh An'), findsOneWidget);
    }, size: tall);

    phoneTest(
      'lọc theo bàn mẫu ngẫu nhiên theo giờ cũng cho kết quả đúng với AppState',
      (tester) async {
        final app = makeAppState()..selectArea('hn-hoan-kiem');
        await pumpTables(tester, app: app);
        final expected = await tester.runAsync(
          () => app.tableRepository.getTables(app.tableQuery()),
        );
        expect(expected, isNotEmpty);
        expect(shown(tester), expected!.map((t) => t.id).toList());
      },
      size: const Size(412, 6000),
    );
  });

  group('Bàn ăn: tải, lỗi, rỗng', () {
    phoneTest('đang tải: có vòng xoay trong danh sách bàn', (tester) async {
      final app = makeAppStateWithTables(
        standardTables(),
        latency: () => const Duration(milliseconds: 500),
      );
      app.selectArea('hcm-q1');
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pump(const Duration(milliseconds: 600)); // MyApp.load() xong
      await tester.tap(find.text('Bàn ăn'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.descendant(
          of: find.byType(TableList),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(find.byType(TableCard), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byType(TableCard), findsNWidgets(5));
    }, size: tall);

    phoneTest('lỗi: có thông báo và nút Thử lại tải lại được', (tester) async {
      final repo = ThrowingTableRepository(failList: true);
      final app = makeAppStateWithTables([], tableRepository: repo);
      await pumpTables(tester, app: app);

      expect(
        find.text(
          'Không tải được danh sách bàn. Kiểm tra mạng rồi thử lại nhé.',
        ),
        findsOneWidget,
      );
      expect(repo.listCalls, 1);

      repo
        ..failList = false
        ..tables = standardTables().where((t) => t.id == 'ta').toList();
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(repo.listCalls, 2);
      expect(shown(tester), ['ta']);
      expect(find.text('Thử lại'), findsNothing);
    }, size: tall);

    phoneTest('rỗng: có nút "Xem ngày mai" và gợi ý nới bán kính', (
      tester,
    ) async {
      final app = makeAppStateWithTables(standardTables())..setRadius(100);
      await pumpTables(tester, app: app);

      expect(
        find.text('Chưa có bàn nào quanh đây. Mở bàn mới nhé?'),
        findsOneWidget,
      );
      expect(find.text('Xem ngày mai'), findsOneWidget);
      expect(find.text('Nới bán kính lên 500 m'), findsOneWidget);
      expect(find.byType(TableCard), findsNothing);
    }, size: tall);

    phoneTest(
      '"Xem ngày mai" đổi ngày lọc sang ngày mai; sau đó thành "Xem hôm nay"',
      (tester) async {
        final app = makeAppStateWithTables(standardTables())..setRadius(100);
        await pumpTables(tester, app: app);

        await tester.tap(find.text('Xem ngày mai'));
        await tester.pumpAndSettle();
        expect(app.date, DateTime(2026, 10, 6));
        expect(find.text('Xem ngày mai'), findsNothing);
        expect(find.text('Xem hôm nay'), findsOneWidget);

        await tester.tap(find.text('Xem hôm nay'));
        await tester.pumpAndSettle();
        expect(app.isDateDefault, isTrue);
        expect(find.text('Xem ngày mai'), findsOneWidget);
      },
      size: tall,
    );

    phoneTest('"Xem ngày mai" ra bàn của ngày mai khi có', (tester) async {
      // Bán kính 1 km nhưng buổi sáng hôm nay không có bàn nào; ngày mai 08:00 có tf
      final app = makeAppStateWithTables(standardTables())
        ..setMealTime(MealTime.morning);
      await pumpTables(tester, app: app);
      expect(shown(tester), isEmpty);

      await tester.tap(find.text('Xem ngày mai'));
      await tester.pumpAndSettle();
      expect(shown(tester), ['tf']);
    }, size: tall);

    phoneTest('"Nới bán kính" tăng lên mức kế tiếp và danh sách có bàn', (
      tester,
    ) async {
      final app = makeAppStateWithTables(standardTables())..setRadius(100);
      await pumpTables(tester, app: app);

      await tester.tap(find.text('Nới bán kính lên 500 m'));
      await tester.pumpAndSettle();
      expect(app.radiusM, 500);
      expect(shown(tester), ['ta', 'tb', 'tc', 'td']);
    }, size: tall);

    phoneTest('ở mức 10 km thì không còn gợi ý nới bán kính', (tester) async {
      final app = makeAppStateWithTables(standardTables())
        ..setRadius(10000)
        ..selectArea('ha-minh-an');
      await pumpTables(tester, app: app, area: false);
      expect(
        find.text('Chưa có bàn nào quanh đây. Mở bàn mới nhé?'),
        findsOneWidget,
      );
      expect(find.textContaining('Nới bán kính'), findsNothing);
      expect(find.text('Xem ngày mai'), findsOneWidget);
    }, size: tall);

    phoneTest('trạng thái rỗng bằng tiếng Anh', (tester) async {
      final app = makeAppStateWithTables(standardTables())
        ..setLanguage(AppLanguage.en)
        ..setRadius(100);
      await pumpTables(tester, app: app);
      expect(
        find.text('No tables around here yet. Why not open a new one?'),
        findsOneWidget,
      );
      expect(find.text('See tomorrow'), findsOneWidget);
      expect(find.text('Widen radius to 500 m'), findsOneWidget);
    }, size: tall);
  });

  group('Nút Tham gia', () {
    phoneTest(
      'khách bấm: mở bảng đăng nhập; đăng nhập xong ở lại đúng màn và KHÔNG tự tham gia',
      (tester) async {
        final app = await pumpTables(tester);
        expect(await membersOf(tester, app, 'ta'), ['u2', 'u3']);

        await tester.tap(inCard('ta', 'Tham gia'));
        await tester.pumpAndSettle();
        expect(find.text('Vào hội thôi!'), findsOneWidget);
        expect(await membersOf(tester, app, 'ta'), [
          'u2',
          'u3',
        ]); // chưa tham gia gì

        await tester.tap(find.text('Tiếp tục với Google'));
        await tester.pumpAndSettle();

        // Bảng đóng, vẫn ở màn Bàn ăn, đã đăng nhập
        expect(find.text('Vào hội thôi!'), findsNothing);
        expect(find.text('Bàn còn chỗ'), findsOneWidget);
        expect(app.isLoggedIn, isTrue);
        // KHÔNG tự tham gia: bàn ta vẫn còn 2 chỗ và nút vẫn là "Tham gia"
        expect(await membersOf(tester, app, 'ta'), ['u2', 'u3']);
        expect(inCard('ta', 'Còn 2/4 chỗ'), findsOneWidget);
        expect(inCard('ta', 'Tham gia'), findsOneWidget);
        expect(inCard('ta', 'Đã tham gia'), findsNothing);
        // Không có thông báo tham gia thành công
        expect(
          find.text('Đã tham gia bàn. Hẹn gặp bạn tại quán!'),
          findsNothing,
        );
        // Chỉ bàn mình vốn đã ở trong (tc) hiện "Đã tham gia"
        expect(inCard('tc', 'Đã tham gia'), findsOneWidget);
      },
      size: tall,
    );

    phoneTest(
      'khách bấm rồi đóng bảng đăng nhập: vẫn là khách, không có gì đổi',
      (tester) async {
        final app = await pumpTables(tester);
        await tester.tap(inCard('ta', 'Tham gia'));
        await tester.pumpAndSettle();
        await tester.fling(
          find.text('Vào hội thôi!'),
          const Offset(0, 800),
          2000,
        );
        await tester.pumpAndSettle();

        expect(find.text('Vào hội thôi!'), findsNothing);
        expect(app.isLoggedIn, isFalse);
        expect(await membersOf(tester, app, 'ta'), ['u2', 'u3']);
      },
      size: tall,
    );

    phoneTest(
      'thành viên bấm: tham gia thành công, báo thành công và cập nhật số chỗ ngay',
      (tester) async {
        final app = await pumpTables(tester, login: true);
        expect(inCard('ta', 'Còn 2/4 chỗ'), findsOneWidget);

        await tester.tap(inCard('ta', 'Tham gia'));
        await tester.pumpAndSettle();

        expect(
          find.text('Đã tham gia bàn. Hẹn gặp bạn tại quán!'),
          findsOneWidget,
        );
        expect(inCard('ta', 'Còn 1/4 chỗ'), findsOneWidget); // 3/4, còn 1
        expect(inCard('ta', 'Đã tham gia'), findsOneWidget);
        expect(inCard('ta', 'Tham gia'), findsNothing);
        expect(await membersOf(tester, app, 'ta'), ['u2', 'u3', 'u1']);
      },
      size: tall,
    );

    phoneTest(
      'chiếm chỗ cuối cùng thì thẻ thành "Đủ N/N chỗ" và "Đã tham gia"',
      (tester) async {
        final app = makeAppStateWithTables(standardTables());
        await tester.runAsync(() => app.tableRepository.joinTable('ta', 'u5'));
        await pumpTables(tester, app: app, login: true);
        expect(inCard('ta', 'Còn 1/4 chỗ'), findsOneWidget);

        await tester.tap(inCard('ta', 'Tham gia'));
        await tester.pumpAndSettle();
        expect(inCard('ta', 'Đủ 4/4 chỗ'), findsOneWidget);
        expect(inCard('ta', 'Đã tham gia'), findsOneWidget);
        expect(inCard('ta', 'Đã đầy'), findsNothing);
      },
      size: tall,
    );

    phoneTest(
      'đang gửi yêu cầu: nút có vòng xoay và không bấm được; xong thì cập nhật',
      (tester) async {
        final app = makeAppStateWithTables(
          standardTables(),
          latency: () => const Duration(milliseconds: 500),
        );
        app.selectArea('hcm-q1');
        await tester.pumpWidget(MyApp(appState: app));
        await tester.pumpAndSettle();
        await tester.runAsync(app.signIn); // chờ thật 500 ms
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bàn ăn'));
        await tester.pumpAndSettle();

        await tester.tap(inCard('ta', 'Tham gia'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('ta')),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
        expect(
          inCard('ta', 'Tham gia'),
          findsNothing,
        ); // chữ được thay bằng vòng xoay

        await tester.pumpAndSettle();
        expect(inCard('ta', 'Đã tham gia'), findsOneWidget);
      },
      size: tall,
    );

    phoneTest(
      'trùng giờ với bàn khác của mình: báo lỗi trùng giờ, số chỗ không đổi',
      (tester) async {
        final app = await pumpTables(
          tester,
          login: true,
        ); // u1 ở tc (14:00–15:00)
        await tester.tap(inCard('td', 'Tham gia')); // td 14:30–15:30
        await tester.pumpAndSettle();

        expect(
          find.text('Bạn đã có một bàn khác trùng khung giờ này.'),
          findsOneWidget,
        );
        expect(
          find.text('Đã tham gia bàn. Hẹn gặp bạn tại quán!'),
          findsNothing,
        );
        expect(inCard('td', 'Còn 3/4 chỗ'), findsOneWidget);
        expect(inCard('td', 'Tham gia'), findsOneWidget);
        expect(await membersOf(tester, app, 'td'), ['u4']);
      },
      size: tall,
    );

    phoneTest(
      'bàn vừa đầy trong lúc xem: báo "đầy" và làm mới thẻ thành "Đã đầy"',
      (tester) async {
        final app = await pumpTables(tester, login: true);
        // Hai người khác chiếm hết chỗ khi giao diện vẫn đang hiện "còn 2 chỗ"
        await tester.runAsync(() => app.tableRepository.joinTable('ta', 'u7'));
        await tester.runAsync(() => app.tableRepository.joinTable('ta', 'u8'));
        expect(inCard('ta', 'Còn 2/4 chỗ'), findsOneWidget); // thẻ còn cũ

        await tester.tap(inCard('ta', 'Tham gia'));
        await tester.pumpAndSettle();

        expect(find.text('Bàn này đã đầy.'), findsOneWidget);
        expect(inCard('ta', 'Đủ 4/4 chỗ'), findsOneWidget);
        expect(inCard('ta', 'Đã đầy'), findsOneWidget);
        expect(await membersOf(tester, app, 'ta'), ['u2', 'u3', 'u7', 'u8']);
      },
      size: tall,
    );

    phoneTest('bàn bị huỷ trong lúc xem: báo "đã huỷ" và thẻ biến mất', (
      tester,
    ) async {
      final app = await pumpTables(tester, login: true);
      await tester.runAsync(() => app.tableRepository.cancelTable('ta', 'u2'));

      await tester.tap(inCard('ta', 'Tham gia'));
      await tester.pumpAndSettle();

      expect(find.text('Bàn này đã bị huỷ.'), findsOneWidget);
      expect(shown(tester), ['tb', 'tc', 'td', 'tg']);
    }, size: tall);

    phoneTest(
      'bàn đã bắt đầu trong lúc xem: báo "đã bắt đầu" và thẻ biến mất',
      (tester) async {
        var current = testNow;
        final app = makeAppStateWithTables(
          standardTables(),
          now: () => current,
        );
        await pumpTables(tester, app: app, login: true);
        expect(shown(tester), contains('ta'));

        current = DateTime(2026, 10, 5, 11, 5); // bàn ta bắt đầu lúc 11:00
        await tester.tap(inCard('ta', 'Tham gia'));
        await tester.pumpAndSettle();

        expect(find.text('Bàn này đã bắt đầu rồi.'), findsOneWidget);
        expect(shown(tester), isNot(contains('ta')));
      },
      size: tall,
    );

    // Mỗi mã lỗi của TableError phải hiện đúng thông báo riêng, ở cả hai ngôn ngữ.
    for (final language in AppLanguage.values) {
      phoneTest(
        'mọi lỗi TableError hiện đúng thông báo riêng (${language.name})',
        (tester) async {
          final strings = Strings(language);
          final messages = <String>{};
          for (final error in TableError.values) {
            final repo = ThrowingTableRepository(
              tables: [standardTables().first],
              error: error,
            );
            final app = makeAppStateWithTables([], tableRepository: repo)
              ..setLanguage(language);
            await pumpTables(tester, app: app, login: true);

            await tester.tap(inCard('ta', strings(StrKey.joinTable)));
            await tester.pumpAndSettle();

            final expected = strings.tableError(error);
            expect(find.text(expected), findsOneWidget, reason: error.name);
            expect(repo.joinCalls, 1, reason: error.name);
            messages.add(expected);

            await tester.pumpWidget(
              const SizedBox(),
            ); // gỡ app để dựng lại vòng sau
          }
          // Mỗi lỗi một thông báo khác nhau
          expect(messages.length, TableError.values.length);
        },
        size: tall,
      );
    }

    phoneTest('lỗi bất ngờ (không phải TableException): báo lỗi chung', (
      tester,
    ) async {
      final repo = ThrowingTableRepository(tables: [standardTables().first]);
      final app = makeAppStateWithTables([], tableRepository: repo);
      await pumpTables(tester, app: app, login: true);

      await tester.tap(inCard('ta', 'Tham gia'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa tham gia được bàn. Thử lại nhé.'), findsOneWidget);
      expect(inCard('ta', 'Tham gia'), findsOneWidget); // vẫn bấm lại được
    }, size: tall);
  });

  // Kiểm tra không tràn dòng ở cả hai ngôn ngữ, khổ máy nhỏ và cỡ chữ hệ thống lớn.
  group('Bàn ăn: không tràn dòng', () {
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
            await pumpTables(tester, app: app, login: true);
            expect(find.byType(TableCard), findsNWidgets(5));

            // Mở rồi đóng các bảng, đổi sang trạng thái rỗng, để mọi bố cục được dựng
            final t = app.strings;
            await tester.tap(find.text(t(StrKey.changeArea)));
            await tester.pumpAndSettle();
            await tester.tap(find.text(t(StrKey.allowLocation)));
            await tester.pumpAndSettle();
            await tester.tap(find.text(t(StrKey.maybeLater)));
            await tester.pumpAndSettle();

            app.setRadius(100);
            await tester.pumpAndSettle();
            expect(find.byType(TableCard), findsNothing);
            expect(find.text(t.widenRadiusLabel(500)), findsOneWidget);
          }, size: Size(width, 3500));
        }
      }
    }
  });

  test('DiningTable trong bộ test có đúng trạng thái đầy/mở', () {
    final tables = {for (final t in standardTables()) t.id: t};
    expect(tables['tb']!.status, TableStatus.full);
    expect(tables['ta']!.status, TableStatus.open);
    expect(tables['th']!.status, TableStatus.cancelled);
    expect(
      tables.values.every((DiningTable t) => t.memberIds.isNotEmpty),
      isTrue,
    );
  });
}
