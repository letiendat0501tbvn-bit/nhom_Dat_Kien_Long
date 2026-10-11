import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/logic/table_rules.dart';
import 'package:giua_ki_app/data/models/dining_table.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/l10n/strings.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/state/app_state.dart';
import 'package:giua_ki_app/ui/components/my_tables.dart';
import 'package:giua_ki_app/ui/components/table_card.dart';
import 'package:giua_ki_app/ui/screens/create_table_screen.dart';
import 'package:giua_ki_app/ui/screens/table_detail_screen.dart';

import 'test_helpers.dart';

const tall = Size(412, 3500);

DiningTable mine(
  String id,
  DateTime start, {
  TableStatus? status,
  List<String>? members,
  String? dishId,
}) => DiningTable(
  id: id,
  dishId: dishId,
  restaurantId: 'q1-1',
  hostId: (members ?? ['u1', 'u2']).first,
  startAt: start,
  durationMin: 60,
  capacity: 4,
  status: status ?? TableStatus.open,
  memberIds: members ?? ['u1', 'u2'],
);

// testNow = 10:00 thứ Hai 05/10/2026.
List<DiningTable> sample() => [
  mine('up1', DateTime(2026, 10, 5, 11), dishId: 'pho'),
  mine('up2', DateTime(2026, 10, 6, 8), dishId: 'lau'),
  mine('st', DateTime(2026, 10, 5, 9, 30), dishId: 'oc'), // đã bắt đầu
  mine('cn', DateTime(2026, 10, 5, 15), status: TableStatus.cancelled),
  mine('en', DateTime(2026, 10, 5, 8), status: TableStatus.ended),
  mine(
    'other',
    DateTime(2026, 10, 5, 16),
    members: ['u2', 'u3'],
  ), // không có u1
];

Future<void> flush(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  await tester.pumpAndSettle();
}

// Mở app, (đăng nhập), sang tab Lịch hẹn.
Future<AppState> pumpMyTables(
  WidgetTester tester, {
  AppState? app,
  bool login = true,
}) async {
  final state = app ?? makeAppStateWithTables(sample());
  await tester.pumpWidget(MyApp(appState: state));
  await tester.pumpAndSettle();
  if (login) {
    await tester.runAsync(state.signIn);
    await tester.pumpAndSettle();
  }
  // Mở tab Lịch hẹn ở thanh dưới
  await tester.tap(
    find.text(state.language == AppLanguage.vi ? 'Lịch hẹn' : 'Schedule').last,
  );
  await tester.pumpAndSettle();
  return state;
}

List<String> ids(WidgetTester tester) => tester
    .widgetList<TableCard>(find.byType(TableCard))
    .map((c) => c.table.id)
    .toList();

Finder inCard(String id, String text) =>
    find.descendant(of: find.byKey(ValueKey(id)), matching: find.text(text));

void main() {
  final now = DateTime(2026, 10, 5, 10);

  group('splitMyTables (thuần)', () {
    test('chia Sắp tới (gần nhất trước) và Đã qua (mới nhất trước)', () {
      final r = splitMyTables(sample(), now);
      expect(r.upcoming.map((t) => t.id), ['up1', 'other', 'up2']);
      expect(r.past.map((t) => t.id), ['cn', 'st', 'en']);
    });

    test('đúng giờ bắt đầu là đã qua; bàn đầy chưa bắt đầu vẫn là sắp tới', () {
      final exactly = mine('x', now);
      final full = mine(
        'y',
        DateTime(2026, 10, 5, 12),
        status: TableStatus.full,
      );
      final r = splitMyTables([exactly, full], now);
      expect(r.upcoming.map((t) => t.id), ['y']);
      expect(r.past.map((t) => t.id), ['x']);
    });

    test('danh sách rỗng', () {
      final r = splitMyTables(const [], now);
      expect(r.upcoming, isEmpty);
      expect(r.past, isEmpty);
    });
  });

  group('getMyTables trả cả bàn đã qua/huỷ', () {
    test(
      'mock repository: đủ bàn của người đó, kể cả huỷ/kết thúc/đã bắt đầu',
      () async {
        final app = makeAppStateWithTables(sample());
        addTearDown(app.dispose);
        final mineIds = (await app.tableRepository.getMyTables('u1'))
            .map((t) => t.id)
            .toSet();
        expect(mineIds, {'up1', 'up2', 'st', 'cn', 'en'});
        expect(mineIds, isNot(contains('other')));
      },
    );

    test('không bị lọc bởi chặn: bàn của người bị chặn mà mình là thành viên vẫn có', () async {
      final app = makeAppStateWithTables(sample());
      addTearDown(app.dispose);
      await app.safetyRepository.blockUser(
        'u1',
        'u2',
      ); // u2 là chủ các bàn trên? (u1 là chủ)
      expect((await app.tableRepository.getMyTables('u1')).length, 5);
    });
  });

  group('Khách', () {
    phoneTest('thấy đúng như ảnh: "Bàn ăn của bạn" + lời mời đăng nhập', (
      tester,
    ) async {
      await pumpMyTables(tester, login: false);
      expect(find.text('Hồ sơ của bạn'), findsOneWidget);
      expect(find.text('Bàn ăn của bạn'), findsOneWidget);
      expect(
        find.text('Đăng nhập để xem những bàn ăn của bạn.'),
        findsOneWidget,
      );
      expect(find.byType(TableCard), findsNothing);
      expect(find.byType(MyTables), findsNothing);
    }, size: tall);
  });

  group('Thành viên', () {
    phoneTest('chia Sắp tới / Đã qua đúng, đúng thứ tự, đúng nhãn', (
      tester,
    ) async {
      await pumpMyTables(tester);
      expect(find.text('Sắp tới'), findsOneWidget);
      expect(find.text('Đã qua'), findsOneWidget);
      // Chỉ bàn có u1; 'other' không hiện
      expect(ids(tester), ['up1', 'up2', 'cn', 'st', 'en']);
      // Sắp tới: nút "Đã tham gia" + gợi ý chạm
      expect(inCard('up1', 'Đã tham gia'), findsOneWidget);
      expect(
        inCard('up1', 'Chạm để xem chi tiết hoặc rời bàn'),
        findsOneWidget,
      );
      // Đã qua: nhãn trạng thái, không có gợi ý rời bàn
      expect(inCard('cn', 'Đã huỷ'), findsOneWidget);
      expect(inCard('st', 'Đã bắt đầu'), findsOneWidget);
      expect(inCard('en', 'Đã kết thúc'), findsOneWidget);
      expect(inCard('cn', 'Chạm để xem chi tiết hoặc rời bàn'), findsNothing);
      // Tên món
      expect(inCard('up1', 'Phở'), findsOneWidget);
    }, size: tall);

    phoneTest('chỉ có bàn đã qua: Sắp tới ghi "Chưa có bàn sắp tới."', (
      tester,
    ) async {
      final app = makeAppStateWithTables([
        mine('st', DateTime(2026, 10, 5, 9, 30)),
      ]);
      await pumpMyTables(tester, app: app);
      expect(find.text('Chưa có bàn sắp tới.'), findsOneWidget);
      expect(ids(tester), ['st']);
    }, size: tall);

    phoneTest('chưa có bàn nào: câu gợi ý + "Mở bàn mới" và "Tìm bàn ăn"', (
      tester,
    ) async {
      final app = makeAppStateWithTables([
        mine('other', DateTime(2026, 10, 5, 16), members: ['u2', 'u3']),
      ]);
      await pumpMyTables(tester, app: app);
      expect(
        find.text(
          'Bạn chưa có bàn nào. Mở bàn mới hoặc tìm một bàn để tham gia nhé!',
        ),
        findsOneWidget,
      );
      expect(find.text('Sắp tới'), findsNothing);

      await tester.tap(find.text('Mở bàn mới'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateTableScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Tìm bàn ăn'));
      await tester.pumpAndSettle();
      expect(find.text('Bàn còn chỗ'), findsOneWidget); // sang tab Bàn ăn
    }, size: tall);

    phoneTest('lỗi tải: có nút Thử lại và thử lại được', (tester) async {
      final repo = ThrowingTableRepository(tables: sample(), failList: true);
      final app = makeAppStateWithTables(const [], tableRepository: repo);
      await pumpMyTables(tester, app: app);
      expect(
        find.text(
          'Không tải được danh sách bàn. Kiểm tra mạng rồi thử lại nhé.',
        ),
        findsOneWidget,
      );
      repo.failList = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(ids(tester), contains('up1'));
    }, size: tall);

    phoneTest('đang tải hiện vòng xoay', (tester) async {
      final app = makeAppStateWithTables(
        sample(),
        latency: () => const Duration(milliseconds: 500),
      );
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(app.signIn);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      await tester.tap(find.text('Lịch hẹn').last);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(ids(tester), contains('up1'));
    }, size: tall);

    phoneTest('bấm thẻ mở chi tiết đúng bàn', (tester) async {
      await pumpMyTables(tester);
      await tester.tap(inCard('up1', 'Phở'));
      await tester.pumpAndSettle();
      final s = tester.widget<TableDetailScreen>(
        find.byType(TableDetailScreen),
      );
      expect(s.tableId, 'up1');
    }, size: tall);
  });

  group('Danh sách tự cập nhật', () {
    phoneTest('rời bàn trong chi tiết: Back về thì bàn biến khỏi danh sách', (
      tester,
    ) async {
      await pumpMyTables(tester);
      await tester.tap(inCard('up1', 'Phở'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(Scaffold),
          matching: find.text('Rời bàn'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Rời bàn'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pageBack();
      await flush(tester);
      expect(ids(tester), isNot(contains('up1')));
      expect(ids(tester), contains('up2'));
    }, size: tall);

    phoneTest('chủ bàn huỷ bàn: bàn chuyển sang "Đã qua" với nhãn "Đã huỷ"', (
      tester,
    ) async {
      await pumpMyTables(tester);
      await tester.tap(inCard('up1', 'Phở'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(Scaffold),
          matching: find.text('Huỷ bàn'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Huỷ bàn'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pageBack();
      await flush(tester);
      expect(ids(tester), ['up2', 'cn', 'up1', 'st', 'en']);
      expect(inCard('up1', 'Đã huỷ'), findsOneWidget);
    }, size: tall);

    phoneTest(
      'có bàn mới (mở ở nơi khác): hiện ở "Sắp tới" mà không cần mở lại',
      (tester) async {
        final app = makeAppStateWithTables(sample());
        await pumpMyTables(tester, app: app);
        expect(ids(tester), isNot(contains('t1000')));
        await tester.runAsync(
          () => app.tableRepository.createTable(
            hostId: 'u1',
            restaurantId: 'q1-1',
            startAt: DateTime(2026, 10, 5, 19),
            durationMin: 60,
            capacity: 4,
          ),
        );
        app.notifyTablesChanged();
        await flush(tester);
        expect(ids(tester), ['up1', 't1000', 'up2', 'cn', 'st', 'en']);
        expect(inCard('t1000', 'Đã tham gia'), findsOneWidget);
      },
      size: tall,
    );
  });

  group('Dữ liệu mẫu mặc định', () {
    phoneTest(
      'đăng nhập giả lập vào Lịch hẹn: đúng 1 bàn Sắp tới và 1 bàn Đã kết thúc',
      (tester) async {
        await pumpMyTables(tester, app: makeAppState());
        expect(find.text('Sắp tới'), findsOneWidget);
        expect(find.text('Đã qua'), findsOneWidget);
        final cards = tester
            .widgetList<TableCard>(find.byType(TableCard))
            .toList();
        expect(cards.length, 2);
        expect(cards.first.table.hostId, 'u1'); // Sắp tới: Minh Anh là chủ bàn
        expect(cards.last.table.status, TableStatus.ended);
        expect(inCard(cards.last.table.id, 'Đã kết thúc'), findsOneWidget);
      },
      size: tall,
    );
  });

  group('Đăng xuất', () {
    phoneTest('có hộp xác nhận; Huỷ giữ nguyên; xác nhận về trạng thái khách', (
      tester,
    ) async {
      final app = await pumpMyTables(tester);
      await tester.tap(find.text('Tôi').last);
      await tester.pumpAndSettle();
      expect(find.text('Minh Anh'), findsOneWidget);
      expect(find.text('minhanh@example.com'), findsOneWidget);

      await tester.ensureVisible(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng xuất?'), findsOneWidget);
      expect(
        find.text(
          'Bạn sẽ trở lại là khách ghé chơi. Bạn có thể đăng nhập lại bất cứ lúc nào.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Huỷ'));
      await tester.pumpAndSettle();
      expect(app.isLoggedIn, isTrue);
      expect(find.text('Minh Anh'), findsOneWidget);

      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Đăng xuất'),
        ),
      );
      await tester.pumpAndSettle();
      expect(app.isLoggedIn, isFalse);
      // Đúng như ảnh toi.jpg
      expect(find.text('Khách ghé chơi'), findsOneWidget);
      expect(
        find.text(
          'Đăng nhập để xem lại bàn, trò chuyện và quản lý phản hồi riêng tư.',
        ),
        findsOneWidget,
      );
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Món ngon • Bạn mới • Kết nối thật'), findsOneWidget);

      // Tab Bàn của tôi cũng về trạng thái khách (đúng như lich-hen.jpg)
      await tester.tap(find.text('Lịch hẹn').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Đăng nhập để xem những bàn ăn của bạn.'),
        findsOneWidget,
      );
      expect(find.byType(TableCard), findsNothing);
    }, size: tall);

    phoneTest('EN: hộp xác nhận đăng xuất bằng tiếng Anh', (tester) async {
      final app = makeAppStateWithTables(sample())..setLanguage(AppLanguage.en);
      await pumpMyTables(tester, app: app);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);
      await tester.tap(find.text('Me').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    }, size: tall);
  });

  group('Không tràn dòng', () {
    for (final language in AppLanguage.values) {
      for (final scale in [1.0, 1.3]) {
        for (final width in [360.0, 412.0]) {
          phoneTest('${language.name}, chữ x$scale, rộng ${width.toInt()}', (
            tester,
          ) async {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.platformDispatcher.clearAllTestValues);
            final app = makeAppStateWithTables(sample())..setLanguage(language);
            await pumpMyTables(tester, app: app);
            expect(find.byType(TableCard), findsNWidgets(5));
            expect(tester.takeException(), isNull);
          }, size: Size(width, 3500));
        }
      }
    }

    for (final language in AppLanguage.values) {
      for (final scale in [1.0, 1.3]) {
        phoneTest('trạng thái rỗng ${language.name}, chữ x$scale, rộng 360', (
          tester,
        ) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          final app = makeAppStateWithTables(const [])..setLanguage(language);
          await pumpMyTables(tester, app: app);
          expect(find.text(app.strings(StrKey.myTablesEmpty)), findsOneWidget);
          expect(tester.takeException(), isNull);
        }, size: const Size(360, 3500));
      }
    }
  });
}
