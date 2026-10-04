import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/logic/table_rules.dart';
import 'package:giua_ki_app/data/mock/mock_support.dart';
import 'package:giua_ki_app/data/models/block_entry.dart';
import 'package:giua_ki_app/data/models/chat_message.dart';
import 'package:giua_ki_app/data/models/dining_table.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/models/report.dart';
import 'package:giua_ki_app/data/models/user_feedback.dart';
import 'package:giua_ki_app/data/repositories/mock_chat_repository.dart';
import 'package:giua_ki_app/data/repositories/mock_safety_repository.dart';
import 'package:giua_ki_app/data/repositories/safety_repository.dart';
import 'package:giua_ki_app/data/repositories/table_repository.dart';
import 'package:giua_ki_app/l10n/strings.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/state/app_scope.dart';
import 'package:giua_ki_app/state/app_state.dart';
import 'package:giua_ki_app/ui/components/safety_actions.dart';
import 'package:giua_ki_app/ui/components/table_card.dart';
import 'package:giua_ki_app/ui/screens/dish_detail_screen.dart';
import 'package:giua_ki_app/ui/screens/table_detail_screen.dart';

import 'test_helpers.dart';

const tall = Size(412, 3500);
const vi = Strings(AppLanguage.vi);

// SafetyRepository bọc MockSafetyRepository: thêm cổng chờ, lỗi tải/gửi, đếm số lần gọi.
class GatedSafety implements SafetyRepository {
  GatedSafety(this.inner);

  final MockSafetyRepository inner;
  Completer<void>?
  gate; // nếu có: submitReport/blockUser/unblockUser chờ cổng mở
  bool failLoad = false;
  bool failAction = false;
  int submitCalls = 0;
  int blockCalls = 0;

  Future<void> _maybeWait() async {
    if (gate != null) await gate!.future;
  }

  @override
  Future<Report> submitReport({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
    String note = '',
  }) async {
    submitCalls++;
    await _maybeWait();
    if (failAction) throw Exception('Không có mạng');
    return inner.submitReport(
      reporterId: reporterId,
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      note: note,
    );
  }

  @override
  Future<List<Report>> getReports(String reporterId) async {
    if (failLoad) throw Exception('Không có mạng');
    return inner.getReports(reporterId);
  }

  @override
  Future<void> blockUser(String userId, String blockedUserId) async {
    blockCalls++;
    await _maybeWait();
    if (failAction) throw Exception('Không có mạng');
    return inner.blockUser(userId, blockedUserId);
  }

  @override
  Future<void> unblockUser(String userId, String blockedUserId) async {
    await _maybeWait();
    if (failAction) throw Exception('Không có mạng');
    return inner.unblockUser(userId, blockedUserId);
  }

  @override
  Future<List<BlockEntry>> getBlocks(String userId) async {
    if (failLoad) throw Exception('Không có mạng');
    return inner.getBlocks(userId);
  }

  @override
  Future<UserFeedback> submitFeedback({
    required String userId,
    required String text,
  }) => inner.submitFeedback(userId: userId, text: text);

  @override
  Future<List<UserFeedback>> getFeedbacks(String userId) =>
      inner.getFeedbacks(userId);
}

ChatMessage msg(
  String id,
  String table,
  String sender,
  String text,
  int minute,
) => ChatMessage(
  id: id,
  tableId: table,
  senderId: sender,
  text: text,
  sentAt: DateTime(2026, 10, 5, 9, minute),
);

DiningTable customTable(
  String id, {
  required DateTime start,
  required List<String> members,
  String? dishId,
}) => DiningTable(
  id: id,
  dishId: dishId,
  restaurantId: 'q1-1',
  hostId: members.first,
  startAt: start,
  durationMin: 60,
  capacity: 4,
  memberIds: members,
);

// Màn Chi tiết bàn của một bàn (u1 = Minh Anh nếu login).
Future<AppState> pumpDetail(
  WidgetTester tester,
  String id, {
  required AppState app,
  bool login = true,
}) async {
  await tester.runAsync(app.load);
  if (login) await tester.runAsync(app.signIn);
  await tester.pumpWidget(
    AppScope(
      state: app,
      child: MaterialApp(home: TableDetailScreen(tableId: id)),
    ),
  );
  await tester.pumpAndSettle();
  return app;
}

// Mở app ở tab Bàn ăn, đã chọn Quận 1.
Future<AppState> pumpTables(
  WidgetTester tester, {
  required AppState app,
  bool login = true,
}) async {
  app.selectArea('hcm-q1');
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

List<String> shownIds(WidgetTester tester) => tester
    .widgetList<TableCard>(find.byType(TableCard))
    .map((c) => c.table.id)
    .toList();

Future<List<Report>> reportsOf(WidgetTester tester, AppState app) async =>
    (await tester.runAsync(() => app.safetyRepository.getReports('u1')))!;

Future<List<BlockEntry>> blocksOf(WidgetTester tester, AppState app) async =>
    (await tester.runAsync(() => app.safetyRepository.getBlocks('u1')))!;

Future<void> openMenu(WidgetTester tester, String tooltip) async {
  final f = find.byTooltip(tooltip);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

// Chờ các lần tải lại âm thầm (không có khung hình nên pumpAndSettle không đủ).
Future<void> flush(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  await tester.pumpAndSettle();
}

Future<void> tapInDialog(WidgetTester tester, String text) async {
  await tester.tap(
    find.descendant(of: find.byType(AlertDialog), matching: find.text(text)),
  );
  await flush(tester);
}

Finder inSheet(String text) => find.text(text);

void main() {
  final now = DateTime(2026, 10, 5, 10);

  group('SafetyRepository (báo cáo và chặn)', () {
    MockSafetyRepository make() =>
        MockSafetyRepository(now: () => now, latency: noLatency);

    test(
      'báo cáo: lưu loại, đối tượng, lý do và ghi chú đã cắt khoảng trắng',
      () async {
        final repo = make();
        final r = await repo.submitReport(
          reporterId: 'u1',
          targetType: ReportTargetType.table,
          targetId: 'ta',
          reason: 'spam',
          note: '  nhiều quảng cáo  ',
        );
        expect(r.targetType, ReportTargetType.table);
        expect(r.targetId, 'ta');
        expect(r.reason, 'spam');
        expect(r.note, 'nhiều quảng cáo');
        expect(r.createdAt, now);
        expect((await repo.getReports('u1')).length, 1);
        expect(await repo.getReports('u2'), isEmpty);
      },
    );

    test(
      'báo cáo trùng (cùng người, đối tượng, lý do) không tạo bản ghi mới',
      () async {
        final repo = make();
        Future<Report> send({
          String reporter = 'u1',
          ReportTargetType type = ReportTargetType.user,
          String target = 'u2',
          String reason = 'spam',
        }) => repo.submitReport(
          reporterId: reporter,
          targetType: type,
          targetId: target,
          reason: reason,
        );
        await send();
        await expectLater(
          send(),
          throwsA(
            isA<SafetyException>().having(
              (e) => e.error,
              'error',
              SafetyError.alreadyReported,
            ),
          ),
        );
        expect((await repo.getReports('u1')).length, 1);
        // Khác lý do / khác đối tượng / khác loại / khác người báo cáo thì vẫn nhận
        await send(reason: 'harassment');
        await send(target: 'u3');
        await send(type: ReportTargetType.message, target: 'u2');
        await send(reporter: 'u3');
        expect((await repo.getReports('u1')).length, 4);
        expect((await repo.getReports('u3')).length, 1);
      },
    );

    test('không báo cáo chính mình', () async {
      final repo = make();
      await expectLater(
        repo.submitReport(
          reporterId: 'u1',
          targetType: ReportTargetType.user,
          targetId: 'u1',
          reason: 'spam',
        ),
        throwsA(
          isA<SafetyException>().having(
            (e) => e.error,
            'error',
            SafetyError.cannotTargetSelf,
          ),
        ),
      );
      expect(await repo.getReports('u1'), isEmpty);
    });

    test(
      'không chặn chính mình; chặn lặp lại không tạo thêm dòng; bỏ chặn',
      () async {
        final repo = make();
        await expectLater(
          repo.blockUser('u1', 'u1'),
          throwsA(isA<SafetyException>()),
        );
        expect(await repo.getBlocks('u1'), isEmpty);

        await repo.blockUser('u1', 'u2');
        await repo.blockUser('u1', 'u2');
        expect((await repo.getBlocks('u1')).length, 1);
        expect(repo.blockedIdsOf('u1'), {'u2'});
        expect(
          repo.blockedIdsOf('u3'),
          isEmpty,
        ); // chặn là của riêng từng người

        await repo.unblockUser('u1', 'u2');
        expect(await repo.getBlocks('u1'), isEmpty);
        expect(repo.blockedIdsOf('u1'), isEmpty);
      },
    );

    test(
      'mọi SafetyError/TableError.blockedHost đều có chuỗi cho cả hai ngôn ngữ',
      () {
        for (final lang in AppLanguage.values) {
          final t = Strings(lang);
          expect(t.tableError(TableError.blockedHost), isNotEmpty);
          for (final r in ReportReason.values) {
            expect(t.reportReasonLabel(r.name), isNot(r.name));
          }
          for (final type in ReportTargetType.values) {
            expect(t.reportTypeLabel(type), isNotEmpty);
          }
        }
      },
    );
  });

  group('Chặn thật sự ẩn ở repository', () {
    Future<List<String>> idsFor(
      WidgetTester? _,
      AppState app,
      String? viewer,
    ) async => (await app.tableRepository.getTables(
      TableQuery(areaId: 'hcm-q1', radiusM: 10000, viewerId: viewer),
    )).map((t) => t.id).toList();

    test(
      'filterTables thuần: ẩn bàn của chủ bị chặn, giữ bàn mình đã tham gia',
      () {
        final data = [
          makeTable(
            'a',
            start: DateTime(2026, 10, 5, 11),
            members: ['u2', 'u3'],
          ),
          makeTable('b', start: DateTime(2026, 10, 5, 12), members: ['u4']),
          makeTable(
            'c',
            start: DateTime(2026, 10, 5, 13),
            members: ['u2', 'u1'],
          ),
        ];
        List<String> run(Set<String> blocked, String? viewer) => filterTables(
          tables: data,
          query: const TableQuery(),
          restaurants: const {},
          areas: const {},
          now: now,
          viewerId: viewer,
          blockedHostIds: blocked,
        ).map((t) => t.id).toList();
        expect(run({}, 'u1'), ['a', 'b', 'c']);
        expect(run({'u2'}, 'u1'), [
          'b',
          'c',
        ]); // c: mình đã là thành viên nên giữ
        expect(run({'u2'}, 'u9'), ['b']);
        expect(run({'u4'}, 'u1'), ['a', 'c']);
      },
    );

    test('danh sách bàn: chặn chủ bàn thì bàn của họ biến mất, bỏ chặn thì hiện lại', () async {
      final app = makeAppStateWithTables(standardTables());
      addTearDown(app.dispose);
      expect(await idsFor(null, app, 'u1'), containsAll(['ta', 'tb', 'td']));

      await app.safetyRepository.blockUser('u1', 'u2'); // u2 là chủ bàn ta, tb
      final hidden = await idsFor(null, app, 'u1');
      expect(hidden, isNot(contains('ta')));
      expect(hidden, isNot(contains('tb')));
      expect(hidden, containsAll(['tc', 'td', 'tg'])); // bàn khác vẫn còn

      // Chặn là của riêng người chặn: khách và người khác vẫn thấy
      expect(await idsFor(null, app, null), containsAll(['ta', 'tb']));
      expect(await idsFor(null, app, 'u3'), containsAll(['ta', 'tb']));

      await app.safetyRepository.unblockUser('u1', 'u2');
      expect(await idsFor(null, app, 'u1'), containsAll(['ta', 'tb']));
    });

    test('lọc theo món cũng ẩn bàn của người bị chặn', () async {
      final app = makeAppStateWithTables(standardTables());
      addTearDown(app.dispose);
      await app.safetyRepository.blockUser('u1', 'u2');
      final r = await app.tableRepository.getTables(
        const TableQuery(
          areaId: 'hcm-q1',
          radiusM: 10000,
          dishId: 'pho',
          viewerId: 'u1',
        ),
      );
      expect(r, isEmpty);
    });

    test(
      'không tham gia được bàn của người bị chặn; bỏ chặn thì tham gia được',
      () async {
        final app = makeAppStateWithTables(standardTables());
        addTearDown(app.dispose);
        await app.safetyRepository.blockUser('u1', 'u2');
        await expectLater(
          app.tableRepository.joinTable('ta', 'u1'),
          throwsA(
            isA<TableException>().having(
              (e) => e.error,
              'error',
              TableError.blockedHost,
            ),
          ),
        );
        expect((await app.tableRepository.getTable('ta'))!.memberIds, [
          'u2',
          'u3',
        ]);
        // Người khác vẫn tham gia được
        await app.tableRepository.joinTable('ta', 'u4');

        await app.safetyRepository.unblockUser('u1', 'u2');
        final joined = await app.tableRepository.joinTable('ta', 'u1');
        expect(joined.memberIds, contains('u1'));
      },
    );

    test('(a) đã là thành viên bàn của người bị chặn: bàn vẫn hiện để còn rời được', () async {
      final app = makeAppStateWithTables([
        customTable(
          'mm',
          start: DateTime(2026, 10, 5, 12),
          members: ['u2', 'u1'],
        ),
        ...standardTables(),
      ]);
      addTearDown(app.dispose);
      await app.safetyRepository.blockUser('u1', 'u2');
      final ids = await idsFor(null, app, 'u1');
      expect(ids, contains('mm')); // mình là thành viên
      expect(ids, isNot(contains('ta'))); // chưa là thành viên: ẩn
      // Vẫn rời được
      final left = await app.tableRepository.leaveTable('mm', 'u1');
      expect(left.memberIds, ['u2']);
      // Sau khi rời, bàn bị ẩn như các bàn khác của u2
      expect(await idsFor(null, app, 'u1'), isNot(contains('mm')));
    });

    test(
      '(d) vẫn bị trùng giờ với bàn của người bị chặn nếu mình đang ở bàn đó',
      () async {
        final app = makeAppStateWithTables([
          customTable(
            'mm',
            start: DateTime(2026, 10, 5, 12),
            members: ['u2', 'u1'],
          ),
        ]);
        addTearDown(app.dispose);
        await app.safetyRepository.blockUser('u1', 'u2');
        await expectLater(
          app.tableRepository.createTable(
            hostId: 'u1',
            restaurantId: 'q1-1',
            startAt: DateTime(2026, 10, 5, 12, 30),
            durationMin: 60,
            capacity: 4,
          ),
          throwsA(
            isA<TableException>().having(
              (e) => e.error,
              'error',
              TableError.overlap,
            ),
          ),
        );
      },
    );

    test(
      'tin nhắn: getMessages lọc tin của người bị chặn, bỏ chặn thì hiện lại',
      () async {
        final app = makeAppStateWithTables(
          standardTables(),
          messages: [
            msg('c1', 'tc', 'u2', 'Chào từ Quốc Bảo', 1),
            msg('c2', 'tc', 'u1', 'Tin của mình', 2),
            msg('c3', 'tc', 'u3', 'Chào từ Thu Hà', 3),
          ],
        );
        addTearDown(app.dispose);
        List<String> texts(List<ChatMessage> l) =>
            l.map((m) => m.text).toList();

        expect(
          texts(await app.chatRepository.getMessages('tc', viewerId: 'u1'))
              .length,
          3,
        );
        await app.safetyRepository.blockUser('u1', 'u2');
        expect(
          texts(await app.chatRepository.getMessages('tc', viewerId: 'u1')),
          ['Tin của mình', 'Chào từ Thu Hà'],
        );
        // Người khác (và truy vấn không có người xem) vẫn thấy đủ
        expect(
          (await app.chatRepository.getMessages('tc', viewerId: 'u3')).length,
          3,
        );
        expect((await app.chatRepository.getMessages('tc')).length, 3);

        await app.safetyRepository.unblockUser('u1', 'u2');
        expect(
          (await app.chatRepository.getMessages('tc', viewerId: 'u1')).length,
          3,
        );
      },
    );

    test(
      'tin đến qua incoming: tin của người bị chặn không tới người chặn',
      () async {
        late final MockSafetyRepository safety;
        safety = MockSafetyRepository(now: () => now, latency: noLatency);
        final chat = MockChatRepository(
          messages: const [],
          now: () => now,
          latency: noLatency,
          blockedIdsOf: (id) async => safety.blockedIdsOf(id),
          autoReply: AutoReply(
            membersOf: (_) async => ['u1', 'u2'],
            delay: () => const Duration(milliseconds: 10),
          ),
        );
        await safety.blockUser('u1', 'u2');
        final forBlocker = <ChatMessage>[];
        final forOther = <ChatMessage>[];
        final s1 = chat.incoming('t', viewerId: 'u1').listen(forBlocker.add);
        final s2 = chat.incoming('t', viewerId: 'u3').listen(forOther.add);
        // u1 gửi, u2 trả lời (tin của u2 là tin "đến")
        await chat.sendMessage(tableId: 't', senderId: 'u1', text: 'hi');
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(forBlocker, isEmpty);
        expect(forOther.length, 1);
        await s1.cancel();
        await s2.cancel();
        chat.dispose();
      },
    );
  });

  group('Báo cáo bàn', () {
    phoneTest(
      'menu ⋯ → Báo cáo bàn: chọn lý do, ghi chú, gửi; có thông báo và bản ghi',
      (tester) async {
        final app = makeAppStateWithTables(standardTables());
        await pumpDetail(tester, 'ta', app: app);
        await openMenu(tester, 'Thêm tuỳ chọn');
        await tapText(tester, 'Báo cáo bàn');

        expect(find.text('Chọn lý do'), findsOneWidget);
        for (final r in [
          'Spam hoặc quảng cáo',
          'Quấy rối hoặc xúc phạm',
          'Nội dung không phù hợp',
          'Thông tin sai sự thật',
          'Khác',
        ]) {
          expect(find.text(r), findsOneWidget, reason: r);
        }

        // Chưa chọn lý do: báo lỗi tại chỗ, chưa gửi
        await tapText(tester, 'Gửi báo cáo');
        expect(find.text('Hãy chọn một lý do.'), findsOneWidget);
        expect(await reportsOf(tester, app), isEmpty);

        await tapText(tester, 'Spam hoặc quảng cáo');
        expect(find.text('Hãy chọn một lý do.'), findsNothing);
        await tester.enterText(find.byType(TextField), '  Toàn quảng cáo  ');
        await tester.pump();
        await tapText(tester, 'Gửi báo cáo');

        expect(find.text('Đã gửi báo cáo. Cảm ơn bạn!'), findsOneWidget);
        expect(find.text('Chọn lý do'), findsNothing); // hộp đã đóng
        final reports = await reportsOf(tester, app);
        expect(reports.length, 1);
        expect(reports.single.targetType, ReportTargetType.table);
        expect(reports.single.targetId, 'ta');
        expect(reports.single.reason, 'spam');
        expect(reports.single.note, 'Toàn quảng cáo');
        expect(reports.single.reporterId, 'u1');
      },
      size: tall,
    );

    phoneTest(
      'báo cáo trùng: hiện "Bạn đã báo cáo mục này." và không tạo bản ghi mới',
      (tester) async {
        final app = makeAppStateWithTables(standardTables());
        await pumpDetail(tester, 'ta', app: app);
        Future<void> report(String reason) async {
          await openMenu(tester, 'Thêm tuỳ chọn');
          await tapText(tester, 'Báo cáo bàn');
          await tapText(tester, reason);
          await tapText(tester, 'Gửi báo cáo');
        }

        await report('Khác');
        expect(find.text('Đã gửi báo cáo. Cảm ơn bạn!'), findsOneWidget);
        await report('Khác');
        expect(find.text('Bạn đã báo cáo mục này.'), findsOneWidget);
        expect((await reportsOf(tester, app)).length, 1);

        // Cùng bàn nhưng lý do khác thì nhận
        await report('Thông tin sai sự thật');
        expect((await reportsOf(tester, app)).length, 2);
      },
      size: tall,
    );

    phoneTest('chủ bàn không có menu báo cáo bàn của chính mình', (
      tester,
    ) async {
      final app = makeAppStateWithTables(standardTables());
      await pumpDetail(tester, 'tc', app: app); // u1 là chủ bàn tc
      expect(find.byTooltip('Thêm tuỳ chọn'), findsNothing);
    }, size: tall);

    phoneTest('khách: mở bảng đăng nhập, đăng nhập xong KHÔNG tự gửi báo cáo', (
      tester,
    ) async {
      final app = makeAppStateWithTables(standardTables());
      await pumpDetail(tester, 'ta', app: app, login: false);
      await openMenu(tester, 'Thêm tuỳ chọn');
      await tapText(tester, 'Báo cáo bàn');
      expect(find.text('Vào hội thôi!'), findsOneWidget);
      expect(find.text('Chọn lý do'), findsNothing); // chưa mở hộp báo cáo

      await tapText(tester, 'Tiếp tục với Google');
      expect(app.isLoggedIn, isTrue);
      expect(find.byType(TableDetailScreen), findsOneWidget);
      expect(find.text('Chọn lý do'), findsNothing);
      expect(await reportsOf(tester, app), isEmpty);
      expect(find.text('Đã gửi báo cáo. Cảm ơn bạn!'), findsNothing);
    }, size: tall);

    phoneTest('đang gửi: nút có vòng xoay, không gửi đúp', (tester) async {
      late GatedSafety gated;
      final app = makeAppStateWithTables(
        standardTables(),
        wrapSafety: (inner) => gated = GatedSafety(inner)..gate = Completer(),
      );
      await pumpDetail(tester, 'ta', app: app);
      await openMenu(tester, 'Thêm tuỳ chọn');
      await tapText(tester, 'Báo cáo bàn');
      await tapText(tester, 'Spam hoặc quảng cáo');
      await tester.tap(find.text('Gửi báo cáo'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
      expect(gated.submitCalls, 1);

      gated.gate!.complete();
      await tester.pumpAndSettle();
      expect(gated.submitCalls, 1);
      expect(find.text('Đã gửi báo cáo. Cảm ơn bạn!'), findsOneWidget);
    }, size: tall);

    phoneTest('gửi lỗi: báo ngay trong hộp, giữ hộp mở để gửi lại', (
      tester,
    ) async {
      late GatedSafety gated;
      final app = makeAppStateWithTables(
        standardTables(),
        wrapSafety: (inner) => gated = GatedSafety(inner)..failAction = true,
      );
      await pumpDetail(tester, 'ta', app: app);
      await openMenu(tester, 'Thêm tuỳ chọn');
      await tapText(tester, 'Báo cáo bàn');
      await tapText(tester, 'Khác');
      await tapText(tester, 'Gửi báo cáo');
      expect(find.text('Chưa gửi được báo cáo. Thử lại nhé.'), findsOneWidget);
      expect(find.text('Chọn lý do'), findsOneWidget);

      gated.failAction = false;
      await tapText(tester, 'Gửi báo cáo');
      expect(find.text('Đã gửi báo cáo. Cảm ơn bạn!'), findsOneWidget);
      expect((await reportsOf(tester, app)).length, 1);
    }, size: tall);

    phoneTest('ghi chú tối đa 280 ký tự', (tester) async {
      final app = makeAppStateWithTables(standardTables());
      await pumpDetail(tester, 'ta', app: app);
      await openMenu(tester, 'Thêm tuỳ chọn');
      await tapText(tester, 'Báo cáo bàn');
      await tester.enterText(find.byType(TextField), 'a' * 400);
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byType(TextField))
            .controller!
            .text
            .length,
        280,
      );
      expect(find.text('280/280'), findsOneWidget);
    }, size: tall);
  });

  group('Báo cáo người dùng và tin nhắn', () {
    phoneTest(
      'menu ⋯ của thành viên: báo cáo người dùng; không có menu cho chính mình',
      (tester) async {
        final app = makeAppStateWithTables(standardTables());
        await pumpDetail(tester, 'tc', app: app); // u1 (mình), u2
        expect(find.byTooltip('Thêm tuỳ chọn: Quốc Bảo'), findsOneWidget);
        expect(find.byTooltip('Thêm tuỳ chọn: Minh Anh'), findsNothing);

        await openMenu(tester, 'Thêm tuỳ chọn: Quốc Bảo');
        await tester.tap(find.text('Báo cáo người dùng').last);
        await tester.pumpAndSettle();
        expect(find.text('Báo cáo người dùng'), findsOneWidget); // tiêu đề hộp
        await tapText(tester, 'Quấy rối hoặc xúc phạm');
        await tapText(tester, 'Gửi báo cáo');

        final r = (await reportsOf(tester, app)).single;
        expect(r.targetType, ReportTargetType.user);
        expect(r.targetId, 'u2');
        expect(r.reason, 'harassment');
      },
      size: tall,
    );

    phoneTest('bấm giữ tin của người khác: báo cáo tin nhắn', (tester) async {
      final app = makeAppStateWithTables(
        standardTables(),
        messages: [
          msg('c1', 'tc', 'u2', 'Tin khó chịu', 1),
          msg('c2', 'tc', 'u1', 'Tin của mình', 2),
        ],
      );
      await pumpDetail(tester, 'tc', app: app);
      await tester.longPress(find.text('Tin khó chịu'));
      await tester.pumpAndSettle();
      expect(find.text('Báo cáo tin nhắn'), findsOneWidget);
      expect(find.text('Chặn người dùng'), findsOneWidget);
      await tapText(tester, 'Báo cáo tin nhắn');
      await tapText(tester, 'Nội dung không phù hợp');
      await tapText(tester, 'Gửi báo cáo');

      final r = (await reportsOf(tester, app)).single;
      expect(r.targetType, ReportTargetType.message);
      expect(r.targetId, 'c1');
      expect(r.reason, 'inappropriate');
      expect(find.text('Đã gửi báo cáo. Cảm ơn bạn!'), findsOneWidget);
    }, size: tall);

    phoneTest(
      'bấm giữ tin của chính mình: không có menu (không tự báo cáo/chặn)',
      (tester) async {
        final app = makeAppStateWithTables(
          standardTables(),
          messages: [msg('c2', 'tc', 'u1', 'Tin của mình', 2)],
        );
        await pumpDetail(tester, 'tc', app: app);
        await tester.longPress(find.text('Tin của mình'));
        await tester.pumpAndSettle();
        expect(find.text('Báo cáo tin nhắn'), findsNothing);
        expect(find.text('Chặn người dùng'), findsNothing);
      },
      size: tall,
    );

    phoneTest('chặn/báo cáo chính mình bị từ chối ở hàm dùng chung', (
      tester,
    ) async {
      final app = makeAppStateWithTables(standardTables());
      await pumpDetail(tester, 'tc', app: app);
      final ctx = tester.element(find.byType(TableDetailScreen));
      final blocked = await blockUserFlow(ctx, userId: 'u1', name: 'Minh Anh');
      await tester.pumpAndSettle();
      expect(blocked, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
      await reportTarget(
        ctx,
        type: ReportTargetType.user,
        targetId: 'u1',
        title: 'x',
      );
      await tester.pumpAndSettle();
      expect(find.text('Chọn lý do'), findsNothing);
      expect(await blocksOf(tester, app), isEmpty);
      expect(await reportsOf(tester, app), isEmpty);
    }, size: tall);
  });

  group('Chặn người dùng trong giao diện', () {
    phoneTest('hộp xác nhận nêu hậu quả; Huỷ không đổi gì', (tester) async {
      final app = makeAppStateWithTables(standardTables());
      await pumpDetail(tester, 'tc', app: app);
      await openMenu(tester, 'Thêm tuỳ chọn: Quốc Bảo');
      await tapText(tester, 'Chặn người dùng');
      expect(find.text('Chặn Quốc Bảo?'), findsOneWidget);
      expect(
        find.text(
          'Bạn sẽ không còn thấy bàn do người này mở và tin nhắn của họ, cũng không tham gia được bàn của họ. Bạn có thể bỏ chặn ở Hồ sơ → Tài khoản → Danh sách chặn.',
        ),
        findsOneWidget,
      );
      await tapInDialog(tester, 'Huỷ');
      expect(find.byType(AlertDialog), findsNothing);
      expect(await blocksOf(tester, app), isEmpty);
    }, size: tall);

    phoneTest(
      '(b) chặn thành viên cùng bàn: tên vẫn hiện kèm "Đã chặn", tin của họ biến mất, tin của mình còn',
      (tester) async {
        final app = makeAppStateWithTables(
          standardTables(),
          messages: [
            msg('c1', 'tc', 'u2', 'Tin của Quốc Bảo', 1),
            msg('c2', 'tc', 'u1', 'Tin của mình', 2),
          ],
        );
        await pumpDetail(tester, 'tc', app: app);
        expect(find.text('Tin của Quốc Bảo'), findsOneWidget);

        await openMenu(tester, 'Thêm tuỳ chọn: Quốc Bảo');
        await tapText(tester, 'Chặn người dùng');
        await tapInDialog(tester, 'Chặn');

        expect(find.text('Đã chặn Quốc Bảo.'), findsOneWidget);
        expect((await blocksOf(tester, app)).single.blockedUserId, 'u2');
        // Danh sách thành viên: vẫn thấy họ, có huy hiệu
        expect(find.text('Quốc Bảo'), findsOneWidget);
        expect(find.text('Đã chặn'), findsOneWidget);
        // Chat: tin của họ biến mất, tin của mình còn
        expect(find.text('Tin của Quốc Bảo'), findsNothing);
        expect(find.text('Tin của mình'), findsOneWidget);

        // Menu giờ là "Bỏ chặn"
        await openMenu(tester, 'Thêm tuỳ chọn: Quốc Bảo');
        expect(find.text('Bỏ chặn người dùng'), findsOneWidget);
        expect(find.text('Chặn người dùng'), findsNothing);
      },
      size: tall,
    );

    phoneTest(
      '(c) bỏ chặn từ menu thành viên: tin nhắn và trạng thái hiện lại ngay',
      (tester) async {
        final app = makeAppStateWithTables(
          standardTables(),
          messages: [msg('c1', 'tc', 'u2', 'Tin của Quốc Bảo', 1)],
        );
        await pumpDetail(tester, 'tc', app: app);
        await openMenu(tester, 'Thêm tuỳ chọn: Quốc Bảo');
        await tapText(tester, 'Chặn người dùng');
        await tapInDialog(tester, 'Chặn');
        expect(find.text('Tin của Quốc Bảo'), findsNothing);

        await openMenu(tester, 'Thêm tuỳ chọn: Quốc Bảo');
        await tapText(tester, 'Bỏ chặn người dùng');
        expect(find.text('Bỏ chặn Quốc Bảo?'), findsOneWidget);
        await tapInDialog(tester, 'Bỏ chặn');
        expect(find.text('Đã bỏ chặn Quốc Bảo.'), findsOneWidget);
        expect(find.text('Tin của Quốc Bảo'), findsOneWidget);
        expect(find.text('Đã chặn'), findsNothing);
        expect(await blocksOf(tester, app), isEmpty);
      },
      size: tall,
    );

    phoneTest('chặn từ tin nhắn (bấm giữ → Chặn người dùng)', (tester) async {
      final app = makeAppStateWithTables(
        standardTables(),
        messages: [msg('c1', 'tc', 'u2', 'Tin của Quốc Bảo', 1)],
      );
      await pumpDetail(tester, 'tc', app: app);
      await tester.longPress(find.text('Tin của Quốc Bảo'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Chặn người dùng');
      expect(find.text('Chặn Quốc Bảo?'), findsOneWidget);
      await tapInDialog(tester, 'Chặn');
      expect(find.text('Tin của Quốc Bảo'), findsNothing);
      expect((await blocksOf(tester, app)).single.blockedUserId, 'u2');
    }, size: tall);

    phoneTest('đang gửi: hộp có vòng xoay, hai nút bị khoá, chặn một lần', (
      tester,
    ) async {
      late GatedSafety gated;
      final app = makeAppStateWithTables(
        standardTables(),
        wrapSafety: (inner) => gated = GatedSafety(inner)..gate = Completer(),
      );
      await pumpDetail(tester, 'tc', app: app);
      await openMenu(tester, 'Thêm tuỳ chọn: Quốc Bảo');
      await tapText(tester, 'Chặn người dùng');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Chặn'),
        ),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Huỷ'))
            .onPressed,
        isNull,
      );
      expect(gated.blockCalls, 1);
      gated.gate!.complete();
      await tester.pumpAndSettle();
      expect(gated.blockCalls, 1);
      expect(find.byType(AlertDialog), findsNothing);
    }, size: tall);

    phoneTest('chặn lỗi: báo ngay trong hộp, không đóng', (tester) async {
      late GatedSafety gated;
      final app = makeAppStateWithTables(
        standardTables(),
        wrapSafety: (inner) => gated = GatedSafety(inner)..failAction = true,
      );
      await pumpDetail(tester, 'tc', app: app);
      await openMenu(tester, 'Thêm tuỳ chọn: Quốc Bảo');
      await tapText(tester, 'Chặn người dùng');
      await tapInDialog(tester, 'Chặn');
      expect(find.text('Chưa chặn được. Thử lại nhé.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(gated.blockCalls, 1);
    }, size: tall);
  });

  group('Chặn ẩn bàn khỏi các danh sách trong giao diện', () {
    phoneTest(
      'Bàn ăn: chặn chủ bàn thì bàn biến mất ngay, bỏ chặn thì hiện lại',
      (tester) async {
        final app = await pumpTables(
          tester,
          app: makeAppStateWithTables(standardTables()),
        );
        expect(shownIds(tester), containsAll(['ta', 'tb', 'tc', 'td']));

        await tester.runAsync(() => app.blockUser('u2')); // chủ bàn ta và tb
        await flush(tester);
        final hidden = shownIds(tester);
        expect(hidden, isNot(contains('ta')));
        expect(hidden, isNot(contains('tb')));
        expect(hidden, containsAll(['tc', 'td']));

        await tester.runAsync(() => app.unblockUser('u2'));
        await flush(tester);
        expect(shownIds(tester), containsAll(['ta', 'tb']));
      },
      size: tall,
    );

    phoneTest(
      'Chi tiết món: bàn của người bị chặn không còn trong danh sách của món',
      (tester) async {
        final app = makeAppStateWithTables(standardTables())
          ..selectArea('hcm-q1');
        await tester.runAsync(app.load);
        await tester.runAsync(app.signIn);
        final dish = (await tester.runAsync(
          () => app.dishRepository.getDish('pho'),
        ))!;
        await tester.pumpWidget(
          AppScope(
            state: app,
            child: MaterialApp(home: DishDetailScreen(dish: dish)),
          ),
        );
        await tester.pumpAndSettle();
        expect(shownIds(tester), ['ta']);
        await tester.runAsync(() => app.blockUser('u2'));
        await flush(tester);
        expect(shownIds(tester), isEmpty);
        await tester.runAsync(() => app.unblockUser('u2'));
        await flush(tester);
        expect(shownIds(tester), ['ta']);
      },
      size: tall,
    );

    phoneTest('khách vẫn thấy mọi bàn (chặn là của riêng người chặn)', (
      tester,
    ) async {
      final app = makeAppStateWithTables(standardTables());
      await tester.runAsync(() => app.safetyRepository.blockUser('u1', 'u2'));
      await pumpTables(tester, app: app, login: false);
      expect(shownIds(tester), contains('ta'));
    }, size: tall);

    phoneTest(
      'tham gia bàn của người đã chặn: báo thông báo riêng, không vào bàn',
      (tester) async {
        final app = makeAppStateWithTables(standardTables());
        await pumpDetail(tester, 'ta', app: app); // mở sẵn chi tiết bàn của u2
        await tester.runAsync(() => app.blockUser('u2'));
        await flush(tester);
        await tester.tap(
          find.descendant(
            of: find.byType(Scaffold),
            matching: find.text('Tham gia'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Bạn đã chặn chủ bàn này nên không tham gia được.'),
          findsOneWidget,
        );
        expect(
          (await tester.runAsync(() => app.tableRepository.getTable('ta')))!
              .memberIds,
          ['u2', 'u3'],
        );
      },
      size: tall,
    );

    phoneTest(
      '(a) đã là thành viên bàn của người bị chặn: bàn vẫn hiện và rời được',
      (tester) async {
        final app = makeAppStateWithTables([
          customTable(
            'mm',
            start: DateTime(2026, 10, 5, 12),
            members: ['u2', 'u1'],
          ),
        ]);
        await pumpTables(tester, app: app);
        await tester.runAsync(() => app.blockUser('u2'));
        await flush(tester);
        expect(shownIds(tester), ['mm']); // vẫn thấy vì mình đã là thành viên
        expect(find.text('Đã tham gia'), findsOneWidget);

        await tester.tap(find.byType(TableCard));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(Scaffold),
            matching: find.text('Rời bàn'),
          ),
        );
        await tester.pumpAndSettle();
        await tapInDialog(tester, 'Rời bàn');
        expect(
          (await tester.runAsync(() => app.tableRepository.getTable('mm')))!
              .memberIds,
          ['u2'],
        );
      },
      size: tall,
    );
  });

  group('Hồ sơ > Tài khoản', () {
    Future<AppState> pumpAccount(
      WidgetTester tester, {
      required AppState app,
    }) async {
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await tester.runAsync(app.signIn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      return app;
    }

    phoneTest(
      'Báo cáo đã gửi: rỗng → có danh sách (loại, lý do, ghi chú, giờ), mới nhất trước',
      (tester) async {
        var clock = testNow;
        final app = makeAppStateWithTables(standardTables(), now: () => clock);
        await pumpAccount(tester, app: app);
        await tester.tap(find.text('Báo cáo đã gửi'));
        await tester.pumpAndSettle();
        expect(find.text('Bạn chưa gửi báo cáo nào.'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Hai báo cáo ở hai thời điểm khác nhau
        await tester.runAsync(
          () => app.safetyRepository.submitReport(
            reporterId: 'u1',
            targetType: ReportTargetType.table,
            targetId: 'ta',
            reason: 'spam',
          ),
        );
        clock = DateTime(2026, 10, 5, 14, 30);
        await tester.runAsync(
          () => app.safetyRepository.submitReport(
            reporterId: 'u1',
            targetType: ReportTargetType.message,
            targetId: 'c1',
            reason: 'harassment',
            note: 'Lời lẽ khó nghe',
          ),
        );
        await tester.tap(find.text('Báo cáo đã gửi'));
        await tester.pumpAndSettle();

        expect(find.text('Bàn'), findsOneWidget);
        expect(find.text('Tin nhắn'), findsOneWidget);
        expect(find.text('Spam hoặc quảng cáo'), findsOneWidget);
        expect(find.text('Quấy rối hoặc xúc phạm'), findsOneWidget);
        expect(find.text('Lời lẽ khó nghe'), findsOneWidget);
        expect(find.text('05/10 · 14:30'), findsOneWidget);
        expect(find.text('05/10 · 10:00'), findsOneWidget);
        // Mới nhất ở trên
        expect(
          tester.getTopLeft(find.text('Tin nhắn')).dy,
          lessThan(tester.getTopLeft(find.text('Bàn')).dy),
        );
      },
      size: tall,
    );

    phoneTest('Báo cáo đã gửi: lỗi tải có nút Thử lại; đang tải có vòng xoay', (
      tester,
    ) async {
      late GatedSafety gated;
      final app = makeAppStateWithTables(
        standardTables(),
        wrapSafety: (inner) => gated = GatedSafety(inner)..failLoad = true,
      );
      await pumpAccount(tester, app: app);
      await tester.tap(find.text('Báo cáo đã gửi'));
      await tester.pumpAndSettle();
      expect(
        find.text('Không tải được báo cáo. Kiểm tra mạng rồi thử lại nhé.'),
        findsOneWidget,
      );
      gated.failLoad = false;
      await tapText(tester, 'Thử lại');
      expect(find.text('Bạn chưa gửi báo cáo nào.'), findsOneWidget);
    }, size: tall);

    phoneTest(
      'Danh sách chặn: rỗng; chặn rồi có tên + Bỏ chặn (xác nhận ngắn); bỏ chặn thì bàn hiện lại',
      (tester) async {
        final app = makeAppStateWithTables(standardTables())
          ..selectArea('hcm-q1');
        await pumpAccount(tester, app: app);
        await tester.tap(find.text('Danh sách chặn'));
        await tester.pumpAndSettle();
        expect(find.text('Bạn chưa chặn ai.'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();

        await tester.runAsync(() => app.blockUser('u2'));
        await tester.tap(find.text('Danh sách chặn'));
        await tester.pumpAndSettle();
        expect(find.text('Quốc Bảo'), findsOneWidget);

        // Huỷ hộp xác nhận: vẫn đang chặn
        await tapText(tester, 'Bỏ chặn');
        expect(find.text('Bỏ chặn Quốc Bảo?'), findsOneWidget);
        expect(
          find.text('Bàn và tin nhắn của người này sẽ hiện lại.'),
          findsOneWidget,
        );
        await tapInDialog(tester, 'Huỷ');
        expect((await blocksOf(tester, app)).length, 1);

        await tapText(tester, 'Bỏ chặn');
        await tapInDialog(tester, 'Bỏ chặn');
        expect(find.text('Đã bỏ chặn Quốc Bảo.'), findsOneWidget);
        expect(find.text('Bạn chưa chặn ai.'), findsOneWidget);
        expect(await blocksOf(tester, app), isEmpty);

        // Quay ra tab Bàn ăn: bàn của Quốc Bảo (ta) hiện lại ngay
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bàn ăn').first);
        await tester.pumpAndSettle();
        expect(shownIds(tester), contains('ta'));
      },
      size: tall,
    );

    phoneTest('Danh sách chặn: lỗi tải có nút Thử lại', (tester) async {
      late GatedSafety gated;
      final app = makeAppStateWithTables(
        standardTables(),
        wrapSafety: (inner) => gated = GatedSafety(inner)..failLoad = true,
      );
      await pumpAccount(tester, app: app);
      await tester.tap(find.text('Danh sách chặn'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Không tải được danh sách chặn. Kiểm tra mạng rồi thử lại nhé.',
        ),
        findsOneWidget,
      );
      gated.failLoad = false;
      await tapText(tester, 'Thử lại');
      expect(find.text('Bạn chưa chặn ai.'), findsOneWidget);
    }, size: tall);

    phoneTest('nút Bỏ chặn có nhãn kèm tên cho trình đọc màn hình', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final app = makeAppStateWithTables(standardTables());
      await pumpAccount(tester, app: app);
      await tester.runAsync(() => app.blockUser('u2'));
      await tester.tap(find.text('Danh sách chặn'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Bỏ chặn: Quốc Bảo'), findsOneWidget);
      handle.dispose();
    }, size: tall);
  });

  group('Tiếng Anh', () {
    phoneTest('báo cáo và chặn bằng tiếng Anh', (tester) async {
      final app = makeAppStateWithTables(standardTables())
        ..setLanguage(AppLanguage.en);
      await pumpDetail(tester, 'tc', app: app);
      await openMenu(tester, 'More options: Quốc Bảo');
      expect(find.text('Block user'), findsOneWidget);
      expect(find.text('Report user'), findsOneWidget);
      await tapText(tester, 'Report user');
      expect(find.text('Choose a reason'), findsOneWidget);
      expect(find.text('Spam or ads'), findsOneWidget);
      await tapText(tester, 'Send report');
      expect(find.text('Please choose a reason.'), findsOneWidget);
      await tapText(tester, 'Other');
      await tapText(tester, 'Send report');
      expect(find.text('Report sent. Thank you!'), findsOneWidget);
      await tapText(
        tester,
        'Report sent. Thank you!'.isEmpty ? '' : 'Report sent. Thank you!',
      );
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
            final app = makeAppStateWithTables(
              standardTables(),
              messages: [msg('c1', 'tc', 'u2', 'Tin dài ' * 20, 1)],
            )..setLanguage(language);
            final t = app.strings;
            await pumpDetail(tester, 'tc', app: app);

            // Hộp báo cáo với ghi chú dài
            await openMenu(tester, '${t(StrKey.tdMore)}: Quốc Bảo');
            await tester.tap(find.text(t(StrKey.tdReportUser)).last);
            await tester.pumpAndSettle();
            await tester.enterText(
              find.descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(TextField),
              ),
              'Ghi chú dài ' * 30,
            );
            await tester.pump();
            await tapText(tester, t(StrKey.reportSubmit)); // báo thiếu lý do
            expect(find.text(t(StrKey.reportNeedReason)), findsOneWidget);
            await tapText(tester, t.reportReasonLabel('inappropriate'));
            await tapText(tester, t(StrKey.reportSubmit));

            // Hộp chặn
            await openMenu(tester, '${t(StrKey.tdMore)}: Quốc Bảo');
            await tapText(tester, t(StrKey.tdBlockUser));
            expect(find.byType(AlertDialog), findsOneWidget);
            await tapInDialog(tester, t(StrKey.dialogCancel));
            expect(tester.takeException(), isNull);
          }, size: Size(width, 3500));
        }
      }
    }

    phoneTest(
      'Báo cáo đã gửi và Danh sách chặn (EN, chữ 1,3, rộng 360) không tràn',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final app = makeAppStateWithTables(standardTables())
          ..setLanguage(AppLanguage.en);
        await tester.pumpWidget(MyApp(appState: app));
        await tester.pumpAndSettle();
        await tester.runAsync(app.signIn);
        await tester.runAsync(
          () => app.safetyRepository.submitReport(
            reporterId: 'u1',
            targetType: ReportTargetType.user,
            targetId: 'u2',
            reason: 'misinformation',
            note: 'Ghi chú rất dài ' * 20,
          ),
        );
        await tester.runAsync(() => app.blockUser('u5'));
        await tester.tap(find.text('Me'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reports sent'));
        await tester.pumpAndSettle();
        expect(find.text('False information'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Block list'));
        await tester.pumpAndSettle();
        expect(find.text('Ngọc Lan'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      size: const Size(360, 3500),
    );
  });
}
