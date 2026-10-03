import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/logic/table_rules.dart';
import 'package:giua_ki_app/data/mock/mock_support.dart';
import 'package:giua_ki_app/data/models/chat_message.dart';
import 'package:giua_ki_app/data/models/dining_table.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/repositories/chat_repository.dart';
import 'package:giua_ki_app/data/repositories/mock_chat_repository.dart';
import 'package:giua_ki_app/l10n/strings.dart';
import 'package:giua_ki_app/state/app_scope.dart';
import 'package:giua_ki_app/state/app_state.dart';
import 'package:giua_ki_app/ui/components/table_chat.dart';
import 'package:giua_ki_app/ui/screens/table_detail_screen.dart';

import 'test_helpers.dart';

const tall = Size(412, 3500);

// ChatRepository giả: điều khiển được lỗi gửi/tải, cổng chờ và tin đến từ người khác.
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({List<ChatMessage> messages = const []})
    : messages = List.of(messages);

  final List<ChatMessage> messages;
  final incomingController = StreamController<ChatMessage>.broadcast();
  bool failSend = false;
  bool failLoad = false;
  Completer<void>? gate; // nếu có, sendMessage chờ gate hoàn tất
  final sent = <String>[]; // nội dung các tin gửi thành công
  int sendCalls = 0;
  var _id = 5000;

  @override
  Future<List<ChatMessage>> getMessages(String tableId) async {
    if (failLoad) throw Exception('Không có mạng');
    return messages.where((m) => m.tableId == tableId).toList();
  }

  @override
  Stream<ChatMessage> incoming(String tableId) =>
      incomingController.stream.where((m) => m.tableId == tableId);

  @override
  Future<ChatMessage> sendMessage({
    required String tableId,
    required String senderId,
    required String text,
  }) async {
    sendCalls++;
    if (gate != null) await gate!.future;
    if (failSend) throw Exception('Không có mạng');
    sent.add(text);
    final m = ChatMessage(
      id: 'f${_id++}',
      tableId: tableId,
      senderId: senderId,
      text: text,
      sentAt: DateTime(2026, 10, 5, 10, 0),
    );
    messages.add(m);
    return m;
  }

  // Người khác gửi tin vào bàn (đến qua luồng incoming).
  void deliver(String tableId, String senderId, String text) {
    final m = ChatMessage(
      id: 'f${_id++}',
      tableId: tableId,
      senderId: senderId,
      text: text,
      sentAt: DateTime(2026, 10, 5, 10, 0),
    );
    messages.add(m);
    incomingController.add(m);
  }
}

ChatMessage msg(
  String id,
  String table,
  String sender,
  String text, {
  int hour = 9,
  int minute = 41,
}) => ChatMessage(
  id: id,
  tableId: table,
  senderId: sender,
  text: text,
  sentAt: DateTime(2026, 10, 5, hour, minute),
);

Future<AppState> pumpChat(
  WidgetTester tester,
  String tableId, {
  required FakeChatRepository chat,
  AppState? app,
  List<DiningTable>? tables,
  bool login = true,
}) async {
  final state =
      app ??
      makeAppStateWithTables(tables ?? standardTables(), chatRepository: chat);
  await tester.runAsync(state.load);
  if (login) await tester.runAsync(state.signIn);
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(home: TableDetailScreen(tableId: tableId)),
    ),
  );
  await tester.pumpAndSettle();
  return state;
}

Finder get inputField => find.descendant(
  of: find.byType(TableChat),
  matching: find.byType(TextField),
);

Finder get sendButton => find.byTooltip('Gửi');

// Chính nút IconButton (tooltip tìm ra RawTooltip nên không đọc được onPressed).
Finder get sendIconButton => find.descendant(
  of: find.byType(TableChat),
  matching: find.byType(IconButton),
);

Future<void> typeMessage(WidgetTester tester, String text) async {
  await tester.ensureVisible(inputField);
  await tester.pumpAndSettle();
  await tester.enterText(inputField, text);
  await tester.pump();
}

Future<void> tapSend(WidgetTester tester) async {
  await tester.ensureVisible(sendButton);
  await tester.pumpAndSettle();
  await tester.tap(sendButton);
  await tester.pumpAndSettle();
}

ScrollableState listScroll(WidgetTester tester) =>
    tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(TableChat),
            matching: find.byType(Scrollable),
          )
          .first,
    );

// Tin của mình ở bàn tc (u1 là chủ bàn, u2 là thành viên).
void main() {
  group('Quy tắc thuần: quyền chat và tin hợp lệ', () {
    final now = testNow; // 10:00
    DiningTable at(int h, {TableStatus? s}) => makeTable(
      'x',
      start: DateTime(2026, 10, 5, h, 0),
      members: ['a', 'b'],
      status: s,
    );

    test('thành viên bàn còn hiệu lực: xem và gửi', () {
      expect(chatAccessOf(at(11), 'a', now), ChatAccess.write);
      expect(chatAccessOf(at(11), 'b', now), ChatAccess.write);
    });

    test('thành viên: bàn đã bắt đầu hoặc kết thúc thì chỉ xem', () {
      expect(chatAccessOf(at(9), 'a', now), ChatAccess.readOnly);
      expect(chatAccessOf(at(10), 'a', now), ChatAccess.readOnly);
      expect(
        chatAccessOf(at(9, s: TableStatus.ended), 'a', now),
        ChatAccess.readOnly,
      );
    });

    test('bàn đã huỷ: mất quyền xem ngay, kể cả chủ bàn', () {
      for (final u in [null, 'a', 'b', 'z']) {
        expect(
          chatAccessOf(at(11, s: TableStatus.cancelled), u, now),
          ChatAccess.none,
        );
      }
    });

    test(
      'khách và người chưa tham gia: chỉ có lời mời, không có quyền xem',
      () {
        expect(chatAccessOf(at(11), null, now), ChatAccess.joinToChat);
        expect(chatAccessOf(at(11), 'z', now), ChatAccess.joinToChat);
        // Bàn đã bắt đầu thì không còn lời mời
        expect(chatAccessOf(at(9), null, now), ChatAccess.none);
        expect(chatAccessOf(at(9), 'z', now), ChatAccess.none);
      },
    );

    test('isValidChatText', () {
      expect(isValidChatText(''), isFalse);
      expect(isValidChatText('   \n\t '), isFalse);
      expect(isValidChatText('a'), isTrue);
      expect(isValidChatText('a' * 500), isTrue);
      expect(isValidChatText('a' * 501), isFalse);
    });
  });

  group('MockChatRepository: phản hồi giả lập (chỉ để demo)', () {
    final fixed = DateTime(2026, 10, 5, 10);

    test('tắt (mặc định): không có phản hồi nào', () async {
      final repo = MockChatRepository(
        messages: const [],
        now: () => fixed,
        latency: noLatency,
      );
      final got = <ChatMessage>[];
      final sub = repo.incoming('t').listen(got.add);
      await repo.sendMessage(tableId: 't', senderId: 'u1', text: 'hi');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(got, isEmpty);
      await sub.cancel();
      repo.dispose();
    });

    test('bật: một thành viên KHÁC người gửi trả lời, tin vào kho và luồng incoming', () async {
      final repo = MockChatRepository(
        messages: const [],
        now: () => fixed,
        latency: noLatency,
        autoReply: AutoReply(
          membersOf: (_) async => ['u1', 'u2'],
          delay: () => const Duration(milliseconds: 20),
        ),
      );
      final got = <ChatMessage>[];
      final sub = repo.incoming('t').listen(got.add);
      await repo.sendMessage(tableId: 't', senderId: 'u1', text: 'hi');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(got.length, 1);
      expect(got.single.senderId, 'u2'); // không phải người gửi
      expect((await repo.getMessages('t')).length, 2);
      await sub.cancel();
      repo.dispose();
    });

    test('bàn chỉ có người gửi: không ai trả lời', () async {
      final repo = MockChatRepository(
        messages: const [],
        now: () => fixed,
        latency: noLatency,
        autoReply: AutoReply(
          membersOf: (_) async => ['u1'],
          delay: () => const Duration(milliseconds: 10),
        ),
      );
      final got = <ChatMessage>[];
      final sub = repo.incoming('t').listen(got.add);
      await repo.sendMessage(tableId: 't', senderId: 'u1', text: 'hi');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(got, isEmpty);
      await sub.cancel();
      repo.dispose();
    });

    test('luồng incoming chỉ có tin của đúng bàn', () async {
      final repo = MockChatRepository(
        messages: const [],
        now: () => fixed,
        latency: noLatency,
        autoReply: AutoReply(
          membersOf: (_) async => ['u1', 'u2'],
          delay: () => const Duration(milliseconds: 10),
        ),
      );
      final other = <ChatMessage>[];
      final sub = repo.incoming('khac').listen(other.add);
      await repo.sendMessage(tableId: 't', senderId: 'u1', text: 'hi');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(other, isEmpty);
      await sub.cancel();
      repo.dispose();
    });

    test('AppState.mock mặc định tắt phản hồi giả lập', () async {
      final app = AppState.mock(now: () => testNow, latency: noLatency);
      addTearDown(app.dispose);
      final got = <ChatMessage>[];
      final sub = app.chatRepository.incoming('t2').listen(got.add);
      await app.chatRepository.sendMessage(
        tableId: 't2',
        senderId: 'u2',
        text: 'hi',
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(got, isEmpty);
      await sub.cancel();
    });
  });

  group('Ai thấy chat', () {
    phoneTest('khách: không đọc được nội dung; có lời mời và nút đăng nhập', (
      tester,
    ) async {
      final chat = FakeChatRepository(
        messages: [msg('1', 'ta', 'u2', 'Bí mật của thành viên')],
      );
      await pumpChat(tester, 'ta', chat: chat, login: false);
      expect(find.text('Trò chuyện'), findsOneWidget);
      expect(find.text('Tham gia bàn để trò chuyện.'), findsOneWidget);
      expect(find.text('Bí mật của thành viên'), findsNothing);
      expect(find.byType(TableChat), findsNothing);
      expect(find.byType(TextField), findsNothing);
      // Nút đăng nhập ở khối chat (và ở khối thành viên)
      expect(find.text('Đăng nhập'), findsNWidgets(2));
    }, size: tall);

    phoneTest(
      'khách đăng nhập từ khối chat: ở lại màn, chưa tham gia nên vẫn không đọc được',
      (tester) async {
        final chat = FakeChatRepository(
          messages: [msg('1', 'ta', 'u2', 'Bí mật của thành viên')],
        );
        final app = await pumpChat(tester, 'ta', chat: chat, login: false);
        await tester.tap(find.text('Đăng nhập').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tiếp tục với Google'));
        await tester.pumpAndSettle();
        expect(app.isLoggedIn, isTrue);
        expect(find.text('Tham gia bàn để trò chuyện.'), findsOneWidget);
        expect(find.text('Bí mật của thành viên'), findsNothing);
        expect(
          find.text('Đăng nhập'),
          findsNothing,
        ); // đã đăng nhập: không còn nút
      },
      size: tall,
    );

    phoneTest(
      'đã đăng nhập nhưng chưa tham gia: chỉ lời mời, không có ô nhập',
      (tester) async {
        final chat = FakeChatRepository(
          messages: [msg('1', 'ta', 'u2', 'Bí mật của thành viên')],
        );
        await pumpChat(tester, 'ta', chat: chat); // u1 không ở bàn ta
        expect(find.text('Tham gia bàn để trò chuyện.'), findsOneWidget);
        expect(find.text('Bí mật của thành viên'), findsNothing);
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Đăng nhập'), findsNothing);
      },
      size: tall,
    );

    phoneTest(
      'thành viên thấy tin cũ: tin mình căn phải, tin người khác căn trái kèm tên và giờ',
      (tester) async {
        final chat = FakeChatRepository(
          messages: [
            msg('1', 'tc', 'u2', 'Mình tới trước nhé', minute: 41),
            msg('2', 'tc', 'u1', 'Ok bạn', hour: 9, minute: 45),
          ],
        );
        await pumpChat(tester, 'tc', chat: chat);
        expect(find.text('Mình tới trước nhé'), findsOneWidget);
        expect(find.text('Ok bạn'), findsOneWidget);
        expect(
          find.text('Quốc Bảo'),
          findsWidgets,
        ); // tên người gửi (cũng ở danh sách thành viên)
        expect(find.text('09:41'), findsOneWidget);
        expect(find.text('09:45'), findsOneWidget);

        final screenWidth = tester.view.physicalSize.width;
        final others = tester.getCenter(find.text('Mình tới trước nhé')).dx;
        final mine = tester.getCenter(find.text('Ok bạn')).dx;
        expect(others, lessThan(screenWidth / 2)); // căn trái
        expect(mine, greaterThan(screenWidth / 2)); // căn phải
        // Tin của mình ghi "Bạn" chứ không kèm tên người khác
        expect(
          find.descendant(
            of: find.byType(TableChat),
            matching: find.text('Quốc Bảo'),
          ),
          findsOneWidget,
        );
      },
      size: tall,
    );

    phoneTest('giờ tin nhắn theo ngôn ngữ (EN: AM/PM)', (tester) async {
      final chat = FakeChatRepository(
        messages: [msg('1', 'tc', 'u2', 'Hello', hour: 14, minute: 5)],
      );
      final app = makeAppStateWithTables(standardTables(), chatRepository: chat)
        ..setLanguage(AppLanguage.en);
      await pumpChat(tester, 'tc', chat: chat, app: app);
      expect(find.text('2:05 PM'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.byTooltip('Send'), findsOneWidget);
    }, size: tall);

    phoneTest('chưa có tin nào: câu mời nhắn lời chào', (tester) async {
      await pumpChat(tester, 'tc', chat: FakeChatRepository());
      expect(
        find.text('Chưa có tin nhắn nào. Nhắn lời chào đầu tiên nhé!'),
        findsOneWidget,
      );
    }, size: tall);

    phoneTest('tải lỗi: có nút Thử lại và thử lại được', (tester) async {
      final chat = FakeChatRepository(
        messages: [msg('1', 'tc', 'u2', 'Chào cả nhà')],
      )..failLoad = true;
      await pumpChat(tester, 'tc', chat: chat);
      expect(
        find.text('Không tải được tin nhắn. Kiểm tra mạng rồi thử lại nhé.'),
        findsOneWidget,
      );
      chat.failLoad = false;
      await tester.ensureVisible(find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Chào cả nhà'), findsOneWidget);
    }, size: tall);
  });

  group('Gửi tin', () {
    phoneTest('thành viên gửi được: tin hiện ngay bên phải, ô nhập được xoá', (
      tester,
    ) async {
      final chat = FakeChatRepository();
      await pumpChat(tester, 'tc', chat: chat);
      await typeMessage(tester, '  Xin chào mọi người  ');
      await tapSend(tester);

      expect(chat.sent, ['Xin chào mọi người']); // đã cắt khoảng trắng hai đầu
      expect(find.text('Xin chào mọi người'), findsOneWidget);
      expect(tester.widget<TextField>(inputField).controller!.text, isEmpty);
      final dx = tester.getCenter(find.text('Xin chào mọi người')).dx;
      expect(dx, greaterThan(tester.view.physicalSize.width / 2));
    }, size: tall);

    phoneTest('tin rỗng hoặc toàn khoảng trắng bị chặn', (tester) async {
      final chat = FakeChatRepository();
      await pumpChat(tester, 'tc', chat: chat);
      expect(tester.widget<IconButton>(sendIconButton).onPressed, isNull);

      await typeMessage(tester, '     ');
      expect(tester.widget<IconButton>(sendIconButton).onPressed, isNull);
      // Enter cũng không gửi
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(chat.sendCalls, 0);

      await typeMessage(tester, 'a');
      expect(tester.widget<IconButton>(sendIconButton).onPressed, isNotNull);
    }, size: tall);

    phoneTest('Enter gửi tin', (tester) async {
      final chat = FakeChatRepository();
      await pumpChat(tester, 'tc', chat: chat);
      await typeMessage(tester, 'Gửi bằng Enter');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(chat.sent, ['Gửi bằng Enter']);
      expect(find.text('Gửi bằng Enter'), findsOneWidget);
    }, size: tall);

    phoneTest(
      'tối đa 500 ký tự: gõ quá bị cắt; bộ đếm chỉ hiện khi gần giới hạn',
      (tester) async {
        final chat = FakeChatRepository();
        await pumpChat(tester, 'tc', chat: chat);

        await typeMessage(tester, 'a' * 100);
        expect(find.textContaining('/500'), findsNothing);

        await typeMessage(tester, 'a' * 460);
        expect(find.text('460/500'), findsOneWidget);

        await typeMessage(tester, 'b' * 650);
        final text = tester.widget<TextField>(inputField).controller!.text;
        expect(text.length, 500); // không vượt giới hạn
        expect(find.text('500/500'), findsOneWidget);

        await tapSend(tester);
        expect(chat.sent.single.length, 500); // gửi đúng 500 ký tự
      },
      size: tall,
    );

    phoneTest('tin dài xuống dòng, không tràn', (tester) async {
      final chat = FakeChatRepository(
        messages: [
          msg(
            '1',
            'tc',
            'u2',
            'x' * 300,
          ), // một "từ" rất dài, không có khoảng trắng
          msg('2', 'tc', 'u1', 'Nhiều từ ngắn ' * 20),
        ],
      );
      await pumpChat(tester, 'tc', chat: chat);
      expect(tester.takeException(), isNull);
      listScroll(tester).position.jumpTo(0); // tin đầu đang ở trên cùng
      await tester.pumpAndSettle();
      final bubble = tester.getSize(find.text('x' * 300));
      expect(bubble.width, lessThanOrEqualTo(412 * 0.8));
      expect(bubble.height, greaterThan(40)); // đã xuống nhiều dòng
    }, size: tall);

    phoneTest(
      'đang gửi: nút có vòng xoay, không gửi đúp, xong thì tin hiện ra',
      (tester) async {
        final chat = FakeChatRepository()..gate = Completer<void>();
        await pumpChat(tester, 'tc', chat: chat);
        await typeMessage(tester, 'Một lần thôi');
        await tester.tap(sendButton);
        await tester.pump();

        expect(tester.widget<IconButton>(sendIconButton).onPressed, isNull);
        expect(
          find.descendant(
            of: find.byType(IconButton),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
        await tester.testTextInput.receiveAction(
          TextInputAction.send,
        ); // Enter lúc đang gửi
        await tester.tap(sendButton, warnIfMissed: false);
        await tester.pump();
        expect(chat.sendCalls, 1);

        chat.gate!.complete();
        await tester.pumpAndSettle();
        expect(chat.sendCalls, 1);
        expect(find.text('Một lần thôi'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
      size: tall,
    );

    phoneTest('gửi lỗi: báo lỗi kèm "Gửi lại", giữ nguyên chữ; gửi lại được', (
      tester,
    ) async {
      final chat = FakeChatRepository()..failSend = true;
      await pumpChat(tester, 'tc', chat: chat);
      await typeMessage(tester, 'Tin sẽ lỗi');
      await tapSend(tester);

      expect(find.text('Không gửi được tin nhắn.'), findsOneWidget);
      expect(find.text('Gửi lại'), findsOneWidget);
      expect(
        tester.widget<TextField>(inputField).controller!.text,
        'Tin sẽ lỗi',
      );
      expect(
        find.text('Tin sẽ lỗi'),
        findsOneWidget,
      ); // chỉ trong ô nhập, chưa thành tin

      chat.failSend = false;
      await tester.tap(find.text('Gửi lại'));
      await tester.pumpAndSettle();
      expect(chat.sent, ['Tin sẽ lỗi']);
      expect(find.text('Không gửi được tin nhắn.'), findsNothing);
      expect(find.text('Gửi lại'), findsNothing);
      expect(tester.widget<TextField>(inputField).controller!.text, isEmpty);
    }, size: tall);

    phoneTest('"Gửi lại" khi ô nhập đã bị xoá: gửi lại đúng nội dung lỗi', (
      tester,
    ) async {
      final chat = FakeChatRepository()..failSend = true;
      await pumpChat(tester, 'tc', chat: chat);
      await typeMessage(tester, 'Giữ giùm mình');
      await tapSend(tester);
      await tester.enterText(inputField, '');
      await tester.pump();
      chat.failSend = false;
      await tester.tap(find.text('Gửi lại'));
      await tester.pumpAndSettle();
      expect(chat.sent, ['Giữ giùm mình']);
    }, size: tall);
  });

  group('Cuộn', () {
    List<ChatMessage> many() => [
      for (var i = 0; i < 40; i++)
        msg('m$i', 'tc', i.isEven ? 'u2' : 'u1', 'Tin số $i', minute: i),
    ];

    phoneTest('mở chat: cuộn tới tin mới nhất', (tester) async {
      await pumpChat(tester, 'tc', chat: FakeChatRepository(messages: many()));
      final s = listScroll(tester);
      expect(s.position.maxScrollExtent, greaterThan(0));
      expect(s.position.pixels, s.position.maxScrollExtent);
      expect(find.text('Tin số 39'), findsOneWidget);
    }, size: tall);

    phoneTest('có tin mới khi đang ở cuối: tự cuộn theo', (tester) async {
      final chat = FakeChatRepository(messages: many());
      await pumpChat(tester, 'tc', chat: chat);
      final before = listScroll(tester).position.maxScrollExtent;
      chat.deliver('tc', 'u2', 'Tin mới của người khác');
      await tester.pumpAndSettle();
      final s = listScroll(tester);
      expect(s.position.maxScrollExtent, greaterThan(before));
      expect(s.position.pixels, s.position.maxScrollExtent);
      expect(find.text('Tin mới của người khác'), findsOneWidget);
    }, size: tall);

    phoneTest('đang đọc tin cũ: tin mới KHÔNG kéo màn xuống', (tester) async {
      final chat = FakeChatRepository(messages: many());
      await pumpChat(tester, 'tc', chat: chat);
      listScroll(tester).position.jumpTo(0);
      await tester.pumpAndSettle();
      chat.deliver('tc', 'u2', 'Tin mới của người khác');
      await tester.pumpAndSettle();
      expect(listScroll(tester).position.pixels, 0);
    }, size: tall);

    phoneTest('tin của chính mình luôn cuộn xuống, kể cả khi đang đọc tin cũ', (
      tester,
    ) async {
      final chat = FakeChatRepository(messages: many());
      await pumpChat(tester, 'tc', chat: chat);
      listScroll(tester).position.jumpTo(0);
      await tester.pumpAndSettle();
      await typeMessage(tester, 'Tin của mình');
      await tapSend(tester);
      final s = listScroll(tester);
      expect(s.position.pixels, s.position.maxScrollExtent);
    }, size: tall);
  });

  group('Chỉ đọc và mất quyền xem', () {
    phoneTest(
      'bàn đã bắt đầu: xem được tin cũ, ô nhập thay bằng dòng thông báo',
      (tester) async {
        final chat = FakeChatRepository(
          messages: [msg('1', 'st', 'u2', 'Tin cũ của bàn')],
        );
        await pumpChat(
          tester,
          'st',
          chat: chat,
          tables: [
            makeTable(
              'st',
              start: DateTime(2026, 10, 5, 9, 30),
              members: ['u1', 'u2'],
            ),
          ],
        );
        expect(find.text('Tin cũ của bàn'), findsOneWidget);
        expect(
          find.text('Trò chuyện chỉ để xem vì bàn đã bắt đầu hoặc kết thúc.'),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsNothing);
        expect(sendButton, findsNothing);
      },
      size: tall,
    );

    phoneTest('bàn đã kết thúc: cũng chỉ đọc', (tester) async {
      final chat = FakeChatRepository(
        messages: [msg('1', 'en', 'u2', 'Tin cũ')],
      );
      await pumpChat(
        tester,
        'en',
        chat: chat,
        tables: [
          makeTable(
            'en',
            start: DateTime(2026, 10, 5, 8, 0),
            members: ['u1', 'u2'],
            status: TableStatus.ended,
          ),
        ],
      );
      expect(find.text('Tin cũ'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    }, size: tall);

    phoneTest('bàn đã huỷ: mất quyền xem, không còn khối chat', (tester) async {
      final chat = FakeChatRepository(
        messages: [msg('1', 'th', 'u7', 'Tin của bàn đã huỷ')],
      );
      await pumpChat(
        tester,
        'th',
        chat: chat,
        tables: [
          makeTable(
            'th',
            start: DateTime(2026, 10, 5, 13, 0),
            members: ['u1', 'u7'],
            status: TableStatus.cancelled,
          ),
        ],
      );
      expect(find.text('Trò chuyện'), findsNothing);
      expect(find.text('Tin của bàn đã huỷ'), findsNothing);
      expect(find.byType(TableChat), findsNothing);
    }, size: tall);

    phoneTest('rời bàn: mất quyền xem chat ngay, giao diện cập nhật', (
      tester,
    ) async {
      final chat = FakeChatRepository(
        messages: [msg('1', 'tc', 'u2', 'Tin riêng của bàn')],
      );
      final app = await pumpChat(tester, 'tc', chat: chat);
      expect(find.text('Tin riêng của bàn'), findsOneWidget);

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

      expect(app.isLoggedIn, isTrue);
      expect(find.text('Tin riêng của bàn'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Tham gia bàn để trò chuyện.'), findsOneWidget);
    }, size: tall);

    phoneTest('chủ bàn huỷ bàn: chat biến mất ngay', (tester) async {
      final chat = FakeChatRepository(
        messages: [msg('1', 'tc', 'u2', 'Tin riêng của bàn')],
      );
      await pumpChat(tester, 'tc', chat: chat);
      expect(find.byType(TableChat), findsOneWidget);
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
      expect(find.byType(TableChat), findsNothing);
      expect(find.text('Tin riêng của bàn'), findsNothing);
      expect(find.text('Trò chuyện'), findsNothing);
    }, size: tall);

    phoneTest('tham gia bàn thì có chat ngay', (tester) async {
      final chat = FakeChatRepository(
        messages: [msg('1', 'ta', 'u2', 'Chào người mới')],
      );
      await pumpChat(tester, 'ta', chat: chat);
      expect(find.byType(TableChat), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(Scaffold),
          matching: find.text('Tham gia'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TableChat), findsOneWidget);
      expect(find.text('Chào người mới'), findsOneWidget);
    }, size: tall);
  });

  group('Phản hồi giả lập trong giao diện', () {
    phoneTest('bật: sau khi gửi, thành viên khác tự trả lời sau 1–2 giây', (
      tester,
    ) async {
      late AppState app;
      final chat = MockChatRepository(
        messages: const [],
        now: () => testNow,
        latency: noLatency,
        autoReply: AutoReply(
          membersOf: (id) async =>
              (await app.tableRepository.getTable(id))?.memberIds ?? const [],
          delay: () => const Duration(seconds: 1),
        ),
      );
      app = makeAppStateWithTables(standardTables(), chatRepository: chat);
      await pumpChat(tester, 'tc', chat: FakeChatRepository(), app: app);
      await typeMessage(tester, 'Mọi người ơi');
      await tapSend(tester);
      expect(find.text('Mọi người ơi'), findsOneWidget);
      expect(find.text('Ok bạn, hẹn gặp ở quán nhé!'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Ok bạn, hẹn gặp ở quán nhé!'), findsOneWidget);
      // Người trả lời là thành viên khác (Quốc Bảo), không phải mình
      expect(
        find.descendant(
          of: find.byType(TableChat),
          matching: find.text('Quốc Bảo'),
        ),
        findsOneWidget,
      );
    }, size: tall);

    phoneTest('tắt (mặc định trong test): không có phản hồi nào', (
      tester,
    ) async {
      final chat = FakeChatRepository();
      await pumpChat(tester, 'tc', chat: chat);
      await typeMessage(tester, 'Có ai không');
      await tapSend(tester);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(chat.messages.length, 1);
    }, size: tall);
  });

  group('Nhãn ngữ nghĩa', () {
    phoneTest('ô nhập, nút gửi và từng tin nhắn có nhãn đọc được', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final chat = FakeChatRepository(
        messages: [
          msg('1', 'tc', 'u2', 'Mình tới trước', minute: 41),
          msg('2', 'tc', 'u1', 'Ok bạn', minute: 45),
        ],
      );
      await pumpChat(tester, 'tc', chat: chat);
      expect(find.bySemanticsLabel('Nhập tin nhắn…'), findsWidgets);
      expect(
        tester.getSemantics(sendButton).getSemanticsData().tooltip,
        contains('Gửi'),
      );
      expect(
        find.bySemanticsLabel('Quốc Bảo, 09:41: Mình tới trước'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Bạn, 09:45: Ok bạn'), findsOneWidget);
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
            final chat = FakeChatRepository(
              messages: [
                msg('1', 'tc', 'u2', 'Tin rất dài ' * 30),
                msg('2', 'tc', 'u1', 'y' * 200),
                msg('3', 'tc', 'u2', 'Ngắn'),
              ],
            );
            final app = makeAppStateWithTables(
              standardTables(),
              chatRepository: chat,
            )..setLanguage(language);
            final t = app.strings;
            await pumpChat(tester, 'tc', chat: chat, app: app);

            // Bộ đếm, lỗi gửi + nút gửi lại, rồi tới chỉ đọc
            await typeMessage(tester, 'z' * 480);
            chat.failSend = true;
            await tester.ensureVisible(find.byTooltip(t(StrKey.chatSend)));
            await tester.tap(find.byTooltip(t(StrKey.chatSend)));
            await tester.pumpAndSettle();
            expect(find.text(t(StrKey.chatSendFailed)), findsOneWidget);
            expect(find.text(t(StrKey.chatResend)), findsOneWidget);
            expect(tester.takeException(), isNull);
          }, size: Size(width, 3500));
        }
      }
    }

    phoneTest('chỉ đọc (EN, chữ 1,3, rộng 360) không tràn', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final chat = FakeChatRepository(
        messages: [msg('1', 'st', 'u2', 'Hello')],
      );
      final app = makeAppStateWithTables([
        makeTable(
          'st',
          start: DateTime(2026, 10, 5, 9, 30),
          members: ['u1', 'u2'],
        ),
      ], chatRepository: chat)..setLanguage(AppLanguage.en);
      await pumpChat(tester, 'st', chat: chat, app: app);
      expect(
        find.text('Chat is read-only because the table has started or ended.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }, size: const Size(360, 3500));
  });
}
