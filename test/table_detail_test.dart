import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/logic/table_rules.dart';
import 'package:giua_ki_app/data/models/dining_table.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/repositories/table_repository.dart';
import 'package:giua_ki_app/l10n/strings.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/state/app_scope.dart';
import 'package:giua_ki_app/state/app_state.dart';
import 'package:giua_ki_app/ui/components/table_card.dart';
import 'package:giua_ki_app/ui/screens/table_detail_screen.dart';

import 'test_helpers.dart';

const tall = Size(412, 3500);

// Người đăng nhập trong test là u1 (Minh Anh). Trong bộ bàn chuẩn:
//   ta  11:00 Phở      u2 (chủ), u3          -> u1 chưa tham gia
//   tc  14:00 chưa món u1 (chủ), u2          -> u1 là chủ bàn
//   tb  đã đầy, te đã bắt đầu, th đã huỷ
Future<AppState> pumpDetail(
  WidgetTester tester,
  String id, {
  AppState? app,
  bool login = false,
}) async {
  final state = app ?? makeAppStateWithTables(standardTables());
  await tester.runAsync(state.load);
  if (login) await tester.runAsync(state.signIn);
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(home: TableDetailScreen(tableId: id)),
    ),
  );
  await tester.pumpAndSettle();
  return state;
}

Future<void> tapDialog(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(AlertDialog), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Finder button(String label) => find.ancestor(
  of: find.descendant(of: find.byType(Scaffold), matching: find.text(label)),
  matching: find.bySubtype<ButtonStyleButton>(),
);

Future<DiningTable?> stored(
  WidgetTester tester,
  AppState app,
  String id,
) async {
  final t = await tester.runAsync<DiningTable?>(
    () => app.tableRepository.getTable(id),
  );
  return t;
}

DiningTable customTable(
  String id, {
  required DateTime start,
  required List<String> members,
  int capacity = 4,
  String note = '',
  TableStatus? status,
  String? dishId,
}) => DiningTable(
  id: id,
  dishId: dishId,
  restaurantId: 'q1-1',
  hostId: members.first,
  startAt: start,
  durationMin: 60,
  capacity: capacity,
  note: note,
  status:
      status ??
      (members.length >= capacity ? TableStatus.full : TableStatus.open),
  memberIds: members,
);

void main() {
  const vi = Strings(AppLanguage.vi);

  group('Quy tắc thuần: trạng thái và thao tác', () {
    final now = testNow; // 10:00
    DiningTable at(
      int h, {
      List<String>? members,
      int cap = 4,
      TableStatus? s,
    }) => makeTable(
      'x',
      start: DateTime(2026, 10, 5, h, 0),
      members: members ?? ['a', 'b'],
      capacity: cap,
      status: s,
    );

    test('displayStatusOf', () {
      expect(displayStatusOf(at(11), now), TableDisplayStatus.upcoming);
      expect(
        displayStatusOf(at(11, members: ['a', 'b'], cap: 2), now),
        TableDisplayStatus.full,
      );
      expect(displayStatusOf(at(9), now), TableDisplayStatus.started);
      expect(
        displayStatusOf(at(10), now),
        TableDisplayStatus.started,
      ); // đúng giờ
      expect(
        displayStatusOf(at(11, s: TableStatus.cancelled), now),
        TableDisplayStatus.cancelled,
      );
      expect(
        displayStatusOf(at(9, s: TableStatus.ended), now),
        TableDisplayStatus.ended,
      );
      // Đã huỷ thì giữ "đã huỷ" dù đã quá giờ
      expect(
        displayStatusOf(at(9, s: TableStatus.cancelled), now),
        TableDisplayStatus.cancelled,
      );
    });

    test('khách: còn chỗ thì được "Tham gia", đầy thì "Đã đầy"', () {
      final open = tableActionsOf(at(11), null, now);
      expect(open.canJoin, isTrue);
      expect(open.canLeave || open.canCancel || open.showFull, isFalse);
      final full = tableActionsOf(at(11, cap: 2), null, now);
      expect(full.showFull, isTrue);
      expect(full.canJoin, isFalse);
    });

    test('thành viên thường: chỉ Rời bàn, không có Huỷ bàn', () {
      final a = tableActionsOf(at(11), 'b', now);
      expect(a.canLeave, isTrue);
      expect(a.canCancel, isFalse);
      expect(a.canJoin || a.showFull, isFalse);
    });

    test('chủ bàn: Rời bàn và Huỷ bàn, kể cả khi bàn đã đầy', () {
      for (final cap in [4, 2]) {
        final a = tableActionsOf(at(11, cap: cap), 'a', now);
        expect(a.canLeave, isTrue, reason: 'cap $cap');
        expect(a.canCancel, isTrue, reason: 'cap $cap');
        expect(a.showFull, isFalse);
      }
    });

    test('đã bắt đầu / huỷ / kết thúc: không có thao tác nào', () {
      for (final t in [
        at(9),
        at(10),
        at(11, s: TableStatus.cancelled),
        at(11, s: TableStatus.ended),
      ]) {
        for (final user in [null, 'a', 'b', 'zzz']) {
          expect(tableActionsOf(t, user, now).none, isTrue);
        }
      }
    });
  });

  group('Nội dung', () {
    phoneTest('đủ thông tin bàn (VI)', (tester) async {
      final tables = [
        customTable(
          'n1',
          start: DateTime(2026, 10, 5, 11, 15),
          members: ['u2', 'u3'],
          note: 'Mình ngồi gần cửa sổ',
          dishId: 'pho',
        ),
      ];
      final app = makeAppStateWithTables(tables);
      await pumpDetail(tester, 'n1', app: app);
      final r = (await tester.runAsync(
        () => app.locationRepository.getRestaurants(areaId: 'hcm-q1'),
      ))!.firstWhere((x) => x.id == 'q1-1');

      expect(find.text('Chi tiết bàn'), findsOneWidget);
      expect(find.text('Phở'), findsOneWidget);
      expect(find.text('Sắp diễn ra'), findsOneWidget);
      expect(find.text(r.name), findsOneWidget);
      expect(find.text(r.address), findsOneWidget);
      expect(find.text('11:15–12:15'), findsOneWidget);
      expect(find.text('Hôm nay · 05/10'), findsOneWidget);
      expect(find.text('60 phút'), findsOneWidget);
      expect(find.text('Còn 2/4 chỗ'), findsOneWidget);
      expect(find.text('Ghi chú của chủ bàn'), findsOneWidget);
      expect(find.text('Mình ngồi gần cửa sổ'), findsOneWidget);
    }, size: tall);

    phoneTest('đúng ngôn ngữ (EN) và bàn ngày mai', (tester) async {
      final app = makeAppStateWithTables([
        customTable(
          'n1',
          start: DateTime(2026, 10, 6, 13, 30),
          members: ['u2'],
          dishId: 'lau',
        ),
      ])..setLanguage(AppLanguage.en);
      await pumpDetail(tester, 'n1', app: app);
      expect(find.text('Table details'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('1:30 PM–2:30 PM'), findsOneWidget);
      expect(find.text('Tomorrow · 06/10'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
      expect(find.text('3/4 seats left'), findsOneWidget);
      expect(find.text('Host\'s note'), findsNothing); // không có ghi chú
    }, size: tall);

    phoneTest('bàn chưa có món và không có ghi chú', (tester) async {
      await pumpDetail(tester, 'tc');
      expect(find.text('Chưa chọn món'), findsOneWidget);
      expect(find.text('Ghi chú của chủ bàn'), findsNothing);
    }, size: tall);

    for (final c in {
      'tb': 'Đã đầy',
      'te': 'Đã bắt đầu',
      'th': 'Đã huỷ',
    }.entries) {
      phoneTest('trạng thái ${c.key}: "${c.value}"', (tester) async {
        await pumpDetail(tester, c.key);
        expect(find.text(c.value), findsWidgets);
      }, size: tall);
    }

    phoneTest('bàn đã kết thúc: "Đã kết thúc" và không có thao tác', (
      tester,
    ) async {
      final app = makeAppStateWithTables([
        customTable(
          'en',
          start: DateTime(2026, 10, 5, 8, 0),
          members: ['u1', 'u2'],
          status: TableStatus.ended,
        ),
      ]);
      await pumpDetail(tester, 'en', app: app, login: true);
      expect(find.text('Đã kết thúc'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    }, size: tall);

    phoneTest('bàn không còn tồn tại: báo rõ, Back về màn trước', (
      tester,
    ) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();
      openTableDetail(tester.element(find.byType(Scaffold).first), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Bàn này không còn tồn tại.'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(TableDetailScreen), findsNothing);
    }, size: tall);

    phoneTest('lỗi tải: có nút Thử lại và thử lại được', (tester) async {
      final repo = ThrowingTableRepository(
        tables: [standardTables().first],
        failList: true,
      );
      final app = makeAppStateWithTables(const [], tableRepository: repo);
      await pumpDetail(tester, 'ta', app: app);
      expect(
        find.text(
          'Không tải được danh sách bàn. Kiểm tra mạng rồi thử lại nhé.',
        ),
        findsOneWidget,
      );
      repo.failList = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Phở'), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
    }, size: tall);

    phoneTest('đang tải: hiện vòng xoay', (tester) async {
      final app = makeAppStateWithTables(
        standardTables(),
        latency: () => const Duration(milliseconds: 500),
      );
      await tester.pumpWidget(
        AppScope(
          state: app,
          child: const MaterialApp(home: TableDetailScreen(tableId: 'ta')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(find.text('Phở'), findsOneWidget);
    }, size: tall);
  });

  group('Khách và danh sách thành viên', () {
    phoneTest('khách: lời mời đăng nhập, KHÔNG thấy tên thành viên', (
      tester,
    ) async {
      await pumpDetail(tester, 'ta');
      expect(find.text('Đăng nhập để xem thành viên.'), findsOneWidget);
      expect(
        find.text('Đăng nhập'),
        findsNWidgets(2),
      ); // ở thành viên và ở trò chuyện
      expect(find.text('Quốc Bảo'), findsNothing);
      expect(find.text('Thu Hà'), findsNothing);
      expect(find.text('Chủ bàn'), findsNothing);
      expect(find.textContaining('Thành viên'), findsNothing);
      // Số chỗ vẫn cho khách xem
      expect(find.text('Còn 2/4 chỗ'), findsOneWidget);
    }, size: tall);

    phoneTest(
      'đăng nhập từ bàn: ở lại đúng màn, thấy thành viên, KHÔNG tự tham gia',
      (tester) async {
        final app = await pumpDetail(tester, 'ta');
        await tester.tap(find.text('Đăng nhập').first);
        await tester.pumpAndSettle();
        expect(find.text('Vào hội thôi!'), findsOneWidget);
        await tester.tap(find.text('Tiếp tục với Google'));
        await tester.pumpAndSettle();

        expect(find.byType(TableDetailScreen), findsOneWidget);
        expect(app.isLoggedIn, isTrue);
        expect(find.text('Đăng nhập để xem thành viên.'), findsNothing);
        expect(find.text('Quốc Bảo'), findsOneWidget);
        expect(find.text('Thu Hà'), findsOneWidget);
        expect(find.text('Thành viên (2/4)'), findsOneWidget);
        expect((await stored(tester, app, 'ta'))!.memberIds, ['u2', 'u3']);
        expect(button('Tham gia'), findsOneWidget); // vẫn chưa tham gia
        expect(find.text('Đã mở bàn! Bạn là chủ bàn.'), findsNothing);
      },
      size: tall,
    );

    phoneTest('khách bấm "Tham gia": mở bảng đăng nhập, chưa tham gia', (
      tester,
    ) async {
      final app = await pumpDetail(tester, 'ta');
      await tester.tap(button('Tham gia'));
      await tester.pumpAndSettle();
      expect(find.text('Vào hội thôi!'), findsOneWidget);
      expect((await stored(tester, app, 'ta'))!.memberIds, ['u2', 'u3']);
    }, size: tall);

    phoneTest('thành viên thấy tên và huy hiệu "Chủ bàn" đúng người', (
      tester,
    ) async {
      await pumpDetail(tester, 'ta', login: true);
      expect(find.text('Quốc Bảo'), findsOneWidget);
      expect(find.text('Thu Hà'), findsOneWidget);
      expect(find.text('Chủ bàn'), findsOneWidget);
      // Huy hiệu nằm cùng hàng với chủ bàn (u2)
      final hostRow = find.byKey(const ValueKey('member-u2'));
      expect(
        find.descendant(of: hostRow, matching: find.text('Chủ bàn')),
        findsOneWidget,
      );
      final other = find.byKey(const ValueKey('member-u3'));
      expect(
        find.descendant(of: other, matching: find.text('Chủ bàn')),
        findsNothing,
      );
    }, size: tall);
  });

  group('Nút theo trạng thái', () {
    phoneTest(
      'chưa tham gia: chỉ có "Tham gia" (không Rời/Huỷ), chưa có khối trò chuyện',
      (tester) async {
        await pumpDetail(tester, 'ta', login: true);
        expect(button('Tham gia'), findsOneWidget);
        expect(find.text('Rời bàn'), findsNothing);
        expect(find.text('Huỷ bàn'), findsNothing);
        expect(find.text('Tham gia bàn để trò chuyện.'), findsOneWidget);
        expect(find.byType(TextField), findsNothing); // không có nội dung chat
      },
      size: tall,
    );

    phoneTest('bàn đầy, chưa tham gia: nút "Đã đầy" bị khoá', (tester) async {
      await pumpDetail(tester, 'tb', login: true);
      final b = tester.widget<ButtonStyleButton>(button('Đã đầy'));
      expect(b.onPressed, isNull);
      expect(button('Tham gia'), findsNothing);
    }, size: tall);

    phoneTest('chủ bàn thấy cả "Rời bàn" và "Huỷ bàn"', (tester) async {
      await pumpDetail(tester, 'tc', login: true);
      expect(button('Rời bàn'), findsOneWidget);
      expect(button('Huỷ bàn'), findsOneWidget);
      expect(button('Tham gia'), findsNothing);
    }, size: tall);

    phoneTest('thành viên thường KHÔNG thấy nút "Huỷ bàn"', (tester) async {
      // u1 vào bàn ta (chủ bàn là u2)
      final app = makeAppStateWithTables(standardTables());
      await tester.runAsync(() => app.tableRepository.joinTable('ta', 'u1'));
      await pumpDetail(tester, 'ta', app: app, login: true);
      expect(button('Rời bàn'), findsOneWidget);
      expect(find.text('Huỷ bàn'), findsNothing);
      expect(
        find.text('Trò chuyện'),
        findsOneWidget,
      ); // thành viên có khối chat dành sẵn
      expect(
        find.byType(TextField),
        findsOneWidget,
      ); // thành viên có ô nhập chat
    }, size: tall);

    phoneTest(
      'bàn đã bắt đầu: ai cũng không có nút thao tác (kể cả thành viên)',
      (tester) async {
        final app = makeAppStateWithTables([
          customTable(
            'st',
            start: DateTime(2026, 10, 5, 9, 30),
            members: ['u1', 'u2'],
          ),
        ]);
        await pumpDetail(tester, 'st', app: app, login: true);
        expect(find.text('Đã bắt đầu'), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing);
        expect(find.byType(OutlinedButton), findsNothing);
        expect(find.text('Rời bàn'), findsNothing);
        expect(find.text('Huỷ bàn'), findsNothing);
      },
      size: tall,
    );

    phoneTest('bàn đã huỷ: không có nút thao tác', (tester) async {
      await pumpDetail(tester, 'th', login: true);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    }, size: tall);
  });

  group('Tham gia', () {
    phoneTest(
      'thành viên bấm "Tham gia": thành công, thành viên và nút cập nhật',
      (tester) async {
        final app = await pumpDetail(tester, 'ta', login: true);
        await tester.tap(button('Tham gia'));
        await tester.pumpAndSettle();
        expect(
          find.text('Đã tham gia bàn. Hẹn gặp bạn tại quán!'),
          findsOneWidget,
        );
        expect(find.text('Còn 1/4 chỗ'), findsOneWidget);
        expect(find.text('Minh Anh'), findsOneWidget);
        expect(find.text('Thành viên (3/4)'), findsOneWidget);
        expect(button('Rời bàn'), findsOneWidget);
        expect(button('Tham gia'), findsNothing);
        expect((await stored(tester, app, 'ta'))!.memberIds, [
          'u2',
          'u3',
          'u1',
        ]);
      },
      size: tall,
    );

    phoneTest('đang gửi: vòng xoay, không bấm đúp, xong thì cập nhật', (
      tester,
    ) async {
      final app = makeAppStateWithTables(
        standardTables(),
        latency: () => const Duration(milliseconds: 500),
      );
      await tester.runAsync(app.load);
      await tester.runAsync(app.signIn);
      await tester.pumpWidget(
        AppScope(
          state: app,
          child: const MaterialApp(home: TableDetailScreen(tableId: 'ta')),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      await tester.tap(button('Tham gia'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final b = tester.widget<ButtonStyleButton>(find.byType(FilledButton));
      expect(b.onPressed, isNull);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect((await stored(tester, app, 'ta'))!.memberIds, ['u2', 'u3', 'u1']);
      expect(button('Rời bàn'), findsOneWidget);
    }, size: tall);

    for (final e in TableError.values) {
      phoneTest('lỗi ${e.name}: thông báo riêng, không đổi dữ liệu', (
        tester,
      ) async {
        final repo = ThrowingTableRepository(
          tables: [standardTables().first],
          error: e,
        );
        final app = makeAppStateWithTables(const [], tableRepository: repo);
        await pumpDetail(tester, 'ta', app: app, login: true);
        await tester.tap(button('Tham gia'));
        await tester.pumpAndSettle();
        expect(find.text(vi.tableError(e)), findsOneWidget);
        expect(repo.joinCalls, 1);
        expect(button('Tham gia'), findsOneWidget); // bấm lại được
      }, size: tall);
    }

    phoneTest('lỗi bất ngờ: báo lỗi chung', (tester) async {
      final repo = ThrowingTableRepository(tables: [standardTables().first]);
      final app = makeAppStateWithTables(const [], tableRepository: repo);
      await pumpDetail(tester, 'ta', app: app, login: true);
      await tester.tap(button('Tham gia'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa thực hiện được. Thử lại nhé.'), findsOneWidget);
    }, size: tall);
  });

  group('Rời bàn', () {
    phoneTest(
      'thành viên thường: hộp xác nhận nói rõ hậu quả; "Ở lại" không đổi gì',
      (tester) async {
        final app = makeAppStateWithTables(standardTables());
        await tester.runAsync(() => app.tableRepository.joinTable('ta', 'u1'));
        await pumpDetail(tester, 'ta', app: app, login: true);

        await tester.tap(button('Rời bàn'));
        await tester.pumpAndSettle();
        expect(find.text('Rời bàn này?'), findsOneWidget);
        expect(
          find.text(
            'Bạn sẽ trả lại chỗ của mình. Nếu bàn còn chỗ, bạn có thể tham gia lại sau.',
          ),
          findsOneWidget,
        );
        await tapDialog(tester, 'Ở lại');
        expect(find.byType(AlertDialog), findsNothing);
        expect((await stored(tester, app, 'ta'))!.memberIds, [
          'u2',
          'u3',
          'u1',
        ]);
        expect(button('Rời bàn'), findsOneWidget);
      },
      size: tall,
    );

    phoneTest('thành viên thường rời bàn: trả chỗ, nút về "Tham gia"', (
      tester,
    ) async {
      final app = makeAppStateWithTables(standardTables());
      await tester.runAsync(() => app.tableRepository.joinTable('ta', 'u1'));
      await pumpDetail(tester, 'ta', app: app, login: true);
      await tester.tap(button('Rời bàn'));
      await tester.pumpAndSettle();
      await tapDialog(tester, 'Rời bàn');

      expect(find.text('Đã rời bàn.'), findsOneWidget);
      expect((await stored(tester, app, 'ta'))!.memberIds, ['u2', 'u3']);
      expect(find.text('Còn 2/4 chỗ'), findsOneWidget);
      expect(button('Tham gia'), findsOneWidget);
      expect(find.text('Minh Anh'), findsNothing);
    }, size: tall);

    phoneTest(
      'chủ bàn còn người khác: hộp nói rõ ai nhận quyền; rời xong quyền chuyển cho người vào sớm nhất',
      (tester) async {
        // tc: chủ bàn u1 (Minh Anh), thành viên u2 (Quốc Bảo)
        final app = await pumpDetail(tester, 'tc', login: true);
        await tester.tap(button('Rời bàn'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Bạn là chủ bàn. Khi bạn rời, quyền chủ bàn sẽ chuyển cho Quốc Bảo, người vào bàn sớm nhất.',
          ),
          findsOneWidget,
        );
        await tapDialog(tester, 'Rời bàn');

        expect(
          find.text('Đã rời bàn. Quyền chủ bàn đã chuyển cho Quốc Bảo.'),
          findsOneWidget,
        );
        final t = (await stored(tester, app, 'tc'))!;
        expect(t.hostId, 'u2');
        expect(t.memberIds, ['u2']);
        expect(t.status, TableStatus.open);
        // Minh Anh không còn là thành viên: chỉ còn "Tham gia"
        expect(button('Tham gia'), findsOneWidget);
        expect(find.text('Huỷ bàn'), findsNothing);
        expect(find.text('Đã huỷ'), findsNothing);
      },
      size: tall,
    );

    phoneTest(
      'chủ bàn nhiều người: người vào SỚM NHẤT nhận quyền, không phải người cuối',
      (tester) async {
        final app = makeAppStateWithTables([
          customTable(
            'm',
            start: DateTime(2026, 10, 5, 15, 0),
            members: ['u1', 'u5', 'u3', 'u4'],
          ),
        ]);
        await pumpDetail(tester, 'm', app: app, login: true);
        await tester.tap(button('Rời bàn'));
        await tester.pumpAndSettle();
        expect(find.textContaining('chuyển cho Ngọc Lan'), findsOneWidget);
        await tapDialog(tester, 'Rời bàn');
        final t = (await stored(tester, app, 'm'))!;
        expect(t.hostId, 'u5');
        expect(t.memberIds, ['u5', 'u3', 'u4']);
      },
      size: tall,
    );

    phoneTest('chủ bàn chỉ còn một mình: hộp báo sẽ huỷ; rời xong bàn tự huỷ', (
      tester,
    ) async {
      final app = makeAppStateWithTables([
        customTable(
          'solo',
          start: DateTime(2026, 10, 5, 16, 0),
          members: ['u1'],
        ),
      ]);
      await pumpDetail(tester, 'solo', app: app, login: true);
      await tester.tap(button('Rời bàn'));
      await tester.pumpAndSettle();
      expect(
        find.text('Bạn là người duy nhất trong bàn. Rời bàn sẽ huỷ bàn này.'),
        findsOneWidget,
      );
      await tapDialog(tester, 'Rời bàn');

      expect(
        find.text('Bạn là người cuối cùng nên bàn đã được huỷ.'),
        findsOneWidget,
      );
      expect(
        (await stored(tester, app, 'solo'))!.status,
        TableStatus.cancelled,
      );
      expect(find.text('Đã huỷ'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    }, size: tall);

    phoneTest(
      'bàn vừa bắt đầu trong lúc xem: rời bị từ chối bằng thông báo riêng',
      (tester) async {
        // Giờ chạy theo biến: lúc mở màn còn 11:00 chưa tới, sau đó đồng hồ nhảy qua 11:00
        var clock = testNow;
        final app = makeAppStateWithTables([
          customTable(
            'late',
            start: DateTime(2026, 10, 5, 11, 0),
            members: ['u1', 'u2'],
          ),
        ], now: () => clock);
        await pumpDetail(tester, 'late', app: app, login: true);
        expect(button('Rời bàn'), findsOneWidget);
        clock = DateTime(2026, 10, 5, 11, 5);

        await tester.tap(button('Rời bàn'));
        await tester.pumpAndSettle();
        await tapDialog(tester, 'Rời bàn');
        expect(
          find.text(vi.tableError(TableError.alreadyStarted)),
          findsOneWidget,
        );
        expect((await stored(tester, app, 'late'))!.memberIds, ['u1', 'u2']);
      },
      size: tall,
    );
  });

  group('Huỷ bàn', () {
    phoneTest(
      'chủ bàn: hộp nói rõ hậu quả (có người khác); "Giữ bàn" không đổi gì',
      (tester) async {
        final app = await pumpDetail(tester, 'tc', login: true);
        await tester.tap(button('Huỷ bàn'));
        await tester.pumpAndSettle();
        expect(find.text('Huỷ bàn này?'), findsOneWidget);
        expect(
          find.text(
            'Bàn sẽ đóng lại, 1 thành viên khác sẽ mất chỗ và không ai tham gia được nữa. Thao tác này không hoàn tác được.',
          ),
          findsOneWidget,
        );
        await tapDialog(tester, 'Giữ bàn');
        expect((await stored(tester, app, 'tc'))!.status, TableStatus.open);
        expect(find.text('Sắp diễn ra'), findsOneWidget);
      },
      size: tall,
    );

    phoneTest(
      'chủ bàn huỷ: bàn thành "Đã huỷ", hết nút thao tác, có thông báo',
      (tester) async {
        final app = await pumpDetail(tester, 'tc', login: true);
        await tester.tap(button('Huỷ bàn'));
        await tester.pumpAndSettle();
        await tapDialog(tester, 'Huỷ bàn');

        expect(find.text('Đã huỷ bàn.'), findsOneWidget);
        expect(
          (await stored(tester, app, 'tc'))!.status,
          TableStatus.cancelled,
        );
        expect(find.text('Đã huỷ'), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing);
        expect(find.byType(OutlinedButton), findsNothing);
      },
      size: tall,
    );

    phoneTest(
      'một mình trong bàn: hộp huỷ dùng câu không nhắc thành viên khác',
      (tester) async {
        final app = makeAppStateWithTables([
          customTable(
            'solo',
            start: DateTime(2026, 10, 5, 16, 0),
            members: ['u1'],
          ),
        ]);
        await pumpDetail(tester, 'solo', app: app, login: true);
        await tester.tap(button('Huỷ bàn'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Bàn sẽ đóng lại và không ai tham gia được nữa. Thao tác này không hoàn tác được.',
          ),
          findsOneWidget,
        );
      },
      size: tall,
    );

    phoneTest('huỷ bị từ chối (lỗi riêng): hiện đúng thông báo', (
      tester,
    ) async {
      final app = makeAppStateWithTables([
        customTable(
          'late',
          start: DateTime(2026, 10, 5, 11, 0),
          members: ['u1', 'u2'],
        ),
      ], now: () => clock);
      clock = testNow;
      await pumpDetail(tester, 'late', app: app, login: true);
      clock = DateTime(2026, 10, 5, 11, 30);
      await tester.tap(button('Huỷ bàn'));
      await tester.pumpAndSettle();
      await tapDialog(tester, 'Huỷ bàn');
      expect(
        find.text(vi.tableError(TableError.alreadyStarted)),
        findsOneWidget,
      );
      expect((await stored(tester, app, 'late'))!.status, TableStatus.open);
    }, size: tall);
  });

  group('Mở từ thẻ bàn và làm mới các màn khác', () {
    Future<AppState> pumpTables(
      WidgetTester tester, {
      bool login = true,
    }) async {
      final app = makeAppStateWithTables(standardTables())
        ..selectArea('hcm-q1');
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      if (login) {
        await tester.runAsync(app.signIn);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Bàn ăn').first);
      await tester.pumpAndSettle();
      return app;
    }

    Finder inCard(String id, String text) => find.descendant(
      of: find.byKey(ValueKey(id)),
      matching: find.text(text),
    );

    phoneTest('bấm cả thẻ mở chi tiết bàn đúng bàn; Back về danh sách', (
      tester,
    ) async {
      await pumpTables(tester, login: false);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('ta')),
          matching: find.text('Phở'),
        ),
      );
      await tester.pumpAndSettle();
      final screen = tester.widget<TableDetailScreen>(
        find.byType(TableDetailScreen),
      );
      expect(screen.tableId, 'ta');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(TableDetailScreen), findsNothing);
      expect(find.byType(TableCard), findsWidgets);
    }, size: tall);

    phoneTest('nút Tham gia trên thẻ vẫn là nút riêng, không mở chi tiết', (
      tester,
    ) async {
      await pumpTables(tester);
      await tester.tap(inCard('ta', 'Tham gia'));
      await tester.pumpAndSettle();
      expect(find.byType(TableDetailScreen), findsNothing);
      expect(inCard('ta', 'Đã tham gia'), findsOneWidget);
    }, size: tall);

    phoneTest(
      'thẻ đã tham gia có gợi ý chạm để xem/rời bàn; thẻ chưa tham gia thì không',
      (tester) async {
        await pumpTables(tester);
        expect(
          inCard('tc', 'Chạm để xem chi tiết hoặc rời bàn'),
          findsOneWidget,
        );
        expect(inCard('ta', 'Chạm để xem chi tiết hoặc rời bàn'), findsNothing);
      },
      size: tall,
    );

    phoneTest(
      'tham gia trong chi tiết bàn: Back về thì thẻ ở danh sách đã cập nhật',
      (tester) async {
        await pumpTables(tester);
        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('ta')),
            matching: find.text('Phở'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(button('Tham gia'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(inCard('ta', 'Đã tham gia'), findsOneWidget);
        expect(inCard('ta', 'Còn 1/4 chỗ'), findsOneWidget);
      },
      size: tall,
    );

    phoneTest(
      'chủ bàn huỷ trong chi tiết: Back về thì bàn biến khỏi danh sách',
      (tester) async {
        await pumpTables(tester);
        expect(find.byKey(const ValueKey('tc')), findsOneWidget);
        await tester.tap(inCard('tc', 'Chạm để xem chi tiết hoặc rời bàn'));
        await tester.pumpAndSettle();
        await tester.tap(button('Huỷ bàn'));
        await tester.pumpAndSettle();
        await tapDialog(tester, 'Huỷ bàn');
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('tc')), findsNothing);
      },
      size: tall,
    );

    phoneTest('rời bàn trong chi tiết: thẻ ở danh sách trả lại chỗ', (
      tester,
    ) async {
      await pumpTables(tester);
      await tester.tap(inCard('tc', 'Chạm để xem chi tiết hoặc rời bàn'));
      await tester.pumpAndSettle();
      await tester.tap(button('Rời bàn'));
      await tester.pumpAndSettle();
      await tapDialog(tester, 'Rời bàn');
      await tester.pageBack();
      await tester.pumpAndSettle();
      // u1 không còn trong bàn: thẻ quay lại "Tham gia", còn 3/4 chỗ
      expect(inCard('tc', 'Tham gia'), findsOneWidget);
      expect(inCard('tc', 'Còn 3/4 chỗ'), findsOneWidget);
    }, size: tall);

    phoneTest('mở từ chi tiết món cũng làm mới danh sách bàn của món', (
      tester,
    ) async {
      final app = makeAppStateWithTables(standardTables())
        ..selectArea('hcm-q1');
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await tester.runAsync(app.signIn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bàn ăn').first);
      await tester.pumpAndSettle();
      // Mở chi tiết bàn rồi tham gia, danh sách ở màn dưới cùng cập nhật (kiểm tra tablesVersion)
      final before = app.tablesVersion;
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('ta')),
          matching: find.text('Phở'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(button('Tham gia'));
      await tester.pumpAndSettle();
      expect(app.tablesVersion, greaterThan(before));
    }, size: tall);
  });

  group('Nhãn ngữ nghĩa', () {
    phoneTest('nút, trạng thái và thành viên có nhãn đọc được', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDetail(tester, 'tc', login: true);
      expect(find.bySemanticsLabel('Rời bàn'), findsOneWidget);
      expect(find.bySemanticsLabel('Huỷ bàn'), findsOneWidget);
      expect(find.bySemanticsLabel('Sắp diễn ra'), findsOneWidget);
      expect(find.bySemanticsLabel('Minh Anh'), findsOneWidget);
      expect(find.bySemanticsLabel('Chủ bàn'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Chi tiết bàn')), findsWidgets);
      handle.dispose();
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
            final app = makeAppStateWithTables([
              customTable(
                'long',
                start: DateTime(2026, 10, 6, 13, 30),
                members: ['u1', 'u2', 'u3', 'u4', 'u5'],
                capacity: 8,
                dishId: 'bun-bo-hue',
                note: 'Ghi chú khá dài để thử xuống dòng ' * 4,
              ),
            ])..setLanguage(language);
            final t = app.strings;
            await pumpDetail(tester, 'long', app: app);
            // Khách: lời mời đăng nhập
            expect(find.text(t(StrKey.tdMembersGuest)), findsOneWidget);
            // Thành viên (chủ bàn): đủ hai nút + hộp xác nhận
            await tester.runAsync(app.signIn);
            await tester.pumpAndSettle();
            await tester.tap(button(t(StrKey.tdLeave)));
            await tester.pumpAndSettle();
            expect(find.byType(AlertDialog), findsOneWidget);
            await tapDialog(tester, t(StrKey.tdLeaveStay));
            await tester.tap(button(t(StrKey.tdCancel)));
            await tester.pumpAndSettle();
            await tapDialog(tester, t(StrKey.tdCancelKeep));
            expect(tester.takeException(), isNull);
          }, size: Size(width, 3500));
        }
      }
    }
  });
}

// Đồng hồ biến đổi dùng chung cho vài test (khai báo ở đầu file để đóng gói trong closure).
var clock = testNow;
