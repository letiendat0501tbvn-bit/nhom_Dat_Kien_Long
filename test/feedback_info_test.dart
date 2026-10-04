import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/logic/feedback_rules.dart';
import 'package:giua_ki_app/data/models/block_entry.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/models/report.dart';
import 'package:giua_ki_app/data/models/user_feedback.dart';
import 'package:giua_ki_app/data/repositories/mock_safety_repository.dart';
import 'package:giua_ki_app/data/repositories/safety_repository.dart';
import 'package:giua_ki_app/l10n/strings.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/state/app_state.dart';
import 'package:giua_ki_app/ui/screens/feedback_screen.dart';
import 'package:giua_ki_app/ui/screens/static_page_screen.dart';

import 'test_helpers.dart';

const tall = Size(412, 3500);

// SafetyRepository bọc bản mock: có thể làm lỗi gửi/tải phản hồi.
class FlakySafety implements SafetyRepository {
  FlakySafety(this.inner);

  final MockSafetyRepository inner;
  bool failSubmit = false;
  bool failLoad = false;
  int submitCalls = 0;

  @override
  Future<UserFeedback> submitFeedback({
    required String userId,
    required String text,
  }) async {
    submitCalls++;
    if (failSubmit) throw Exception('Không có mạng');
    return inner.submitFeedback(userId: userId, text: text);
  }

  @override
  Future<List<UserFeedback>> getFeedbacks(String userId) async {
    if (failLoad) throw Exception('Không có mạng');
    return inner.getFeedbacks(userId);
  }

  @override
  Future<Report> submitReport({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
    String note = '',
  }) => inner.submitReport(
    reporterId: reporterId,
    targetType: targetType,
    targetId: targetId,
    reason: reason,
    note: note,
  );

  @override
  Future<List<Report>> getReports(String reporterId) =>
      inner.getReports(reporterId);

  @override
  Future<void> blockUser(String userId, String blockedUserId) =>
      inner.blockUser(userId, blockedUserId);

  @override
  Future<void> unblockUser(String userId, String blockedUserId) =>
      inner.unblockUser(userId, blockedUserId);

  @override
  Future<List<BlockEntry>> getBlocks(String userId) => inner.getBlocks(userId);
}

// Mở app và sang tab Tôi (Tài khoản).
Future<AppState> pumpAccount(
  WidgetTester tester, {
  AppState? app,
  bool login = true,
}) async {
  final state = app ?? makeAppStateWithTables(standardTables());
  await tester.pumpWidget(MyApp(appState: state));
  await tester.pumpAndSettle();
  if (login) {
    await tester.runAsync(state.signIn);
    await tester.pumpAndSettle();
  }
  await tester.tap(
    find.text(state.language == AppLanguage.vi ? 'Tôi' : 'Me').last,
  );
  await tester.pumpAndSettle();
  return state;
}

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

Finder get field => find.byType(TextField);

Finder button(String label) => find.widgetWithText(FilledButton, label);

void main() {
  group('Quy tắc thuần', () {
    test('isValidFeedback: rỗng, toàn khoảng trắng, tối đa 500', () {
      expect(isValidFeedback(''), isFalse);
      expect(isValidFeedback(' \n\t  '), isFalse);
      expect(isValidFeedback('a'), isTrue);
      expect(isValidFeedback('a' * 500), isTrue);
      expect(isValidFeedback('a' * 501), isFalse);
    });

    test('mọi trang tĩnh có tiêu đề và nội dung ở cả hai ngôn ngữ', () {
      for (final lang in AppLanguage.values) {
        final t = Strings(lang);
        for (final page in StaticPage.values) {
          expect(t.staticPageTitle(page), isNotEmpty);
          final paragraphs = t.staticPageParagraphs(page);
          expect(paragraphs.length, greaterThanOrEqualTo(4), reason: page.name);
          expect(paragraphs.first.startsWith('## '), isTrue);
        }
      }
      // Nội dung VI và EN khác nhau
      for (final page in StaticPage.values) {
        expect(
          const Strings(AppLanguage.vi).staticPageParagraphs(page),
          isNot(const Strings(AppLanguage.en).staticPageParagraphs(page)),
        );
      }
    });

    test(
      'trang Giới thiệu nêu đúng ý SPEC: không giao đồ ăn, vị trí riêng tư',
      () {
        final text = const Strings(AppLanguage.vi)
            .staticPageParagraphs(StaticPage.about)
            .join(' ');
        expect(text, contains('không giao đồ ăn'));
        expect(text, contains('10 m'));
        expect(text, contains('không hiển thị cho người khác'));
      },
    );
  });

  group('Phản hồi ở repository: riêng tư', () {
    test('phản hồi của người này không xuất hiện ở người khác', () async {
      final app = makeAppStateWithTables(const []);
      addTearDown(app.dispose);
      await app.safetyRepository.submitFeedback(userId: 'u1', text: 'Của u1');
      await app.safetyRepository.submitFeedback(userId: 'u2', text: 'Của u2');
      final a = await app.safetyRepository.getFeedbacks('u1');
      final b = await app.safetyRepository.getFeedbacks('u2');
      expect(a.map((f) => f.text), ['Của u1']);
      expect(b.map((f) => f.text), ['Của u2']);
      expect(await app.safetyRepository.getFeedbacks('u3'), isEmpty);
    });
  });

  group('Lối vào', () {
    phoneTest(
      'khách: KHÔNG thấy Phản hồi riêng tư, thấy "Thông tin" dưới thẻ Khách ghé chơi',
      (tester) async {
        await pumpAccount(tester, login: false);
        expect(find.text('Khách ghé chơi'), findsOneWidget);
        expect(find.text('Phản hồi riêng tư'), findsNothing);
        expect(find.text('Báo cáo đã gửi'), findsNothing);
        expect(find.text('Thông tin'), findsOneWidget);
        // Thông tin nằm dưới thẻ khách
        expect(
          tester.getTopLeft(find.text('Thông tin')).dy,
          greaterThan(tester.getTopLeft(find.text('Khách ghé chơi')).dy),
        );
      },
      size: tall,
    );

    phoneTest(
      'thành viên: Phản hồi riêng tư đầu, "Thông tin" ở cuối danh sách mục',
      (tester) async {
        await pumpAccount(tester);
        double y(String s) => tester.getTopLeft(find.text(s)).dy;
        expect(y('Phản hồi riêng tư'), lessThan(y('Báo cáo đã gửi')));
        expect(y('Báo cáo đã gửi'), lessThan(y('Danh sách chặn')));
        expect(y('Danh sách chặn'), lessThan(y('Thông tin')));
        expect(y('Thông tin'), lessThan(y('Đăng xuất')));
      },
      size: tall,
    );
  });

  group('Gửi phản hồi riêng tư', () {
    Future<AppState> openFeedbackScreen(
      WidgetTester tester, {
      AppState? app,
    }) async {
      final state = await pumpAccount(tester, app: app);
      await tapText(tester, 'Phản hồi riêng tư');
      return state;
    }

    phoneTest('màn có ghi chú riêng tư, ô nhập, nút gửi và trạng thái rỗng', (
      tester,
    ) async {
      await openFeedbackScreen(tester);
      expect(find.byType(FeedbackScreen), findsOneWidget);
      expect(
        find.text(
          'Phản hồi này là riêng tư: chỉ đội ngũ đọc, không hiện cho người khác.',
        ),
        findsOneWidget,
      );
      expect(find.text('Phản hồi đã gửi'), findsOneWidget);
      expect(find.text('Bạn chưa gửi phản hồi nào.'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(button('Gửi phản hồi')).onPressed,
        isNull,
      );
    }, size: tall);

    phoneTest('rỗng hoặc toàn khoảng trắng: nút gửi bị khoá', (tester) async {
      final app = await openFeedbackScreen(tester);
      await tester.enterText(field, '     \n  ');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(button('Gửi phản hồi')).onPressed,
        isNull,
      );
      await tester.enterText(field, 'a');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(button('Gửi phản hồi')).onPressed,
        isNotNull,
      );
      expect(
        await tester.runAsync(() => app.safetyRepository.getFeedbacks('u1')),
        isEmpty,
      );
    }, size: tall);

    phoneTest(
      'gửi được: có thông báo, ô được xoá, phản hồi hiện đầu danh sách (mới nhất trước)',
      (tester) async {
        var clock = testNow;
        final app = makeAppStateWithTables(standardTables(), now: () => clock);
        await openFeedbackScreen(tester, app: app);

        await tester.enterText(field, '  Ứng dụng rất dễ dùng  ');
        await tester.pump();
        await tester.tap(button('Gửi phản hồi'));
        await tester.pumpAndSettle();
        expect(
          find.text('Cảm ơn bạn! Đã gửi phản hồi riêng tư.'),
          findsOneWidget,
        );
        expect(tester.widget<TextField>(field).controller!.text, isEmpty);
        expect(find.text('Ứng dụng rất dễ dùng'), findsOneWidget);
        expect(find.text('Bạn chưa gửi phản hồi nào.'), findsNothing);
        expect(find.text('05/10 · 10:00'), findsOneWidget);

        clock = DateTime(2026, 10, 5, 15, 45);
        await tester.enterText(field, 'Thêm nhiều món hơn nhé');
        await tester.pump();
        await tester.tap(button('Gửi phản hồi'));
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.text('Thêm nhiều món hơn nhé')).dy,
          lessThan(tester.getTopLeft(find.text('Ứng dụng rất dễ dùng')).dy),
        );
        expect(find.text('05/10 · 15:45'), findsOneWidget);
        final stored = (await tester.runAsync(
          () => app.safetyRepository.getFeedbacks('u1'),
        ))!;
        expect(stored.map((f) => f.text), [
          'Ứng dụng rất dễ dùng',
          'Thêm nhiều món hơn nhé',
        ]);
      },
      size: tall,
    );

    phoneTest(
      'tối đa 500 ký tự: gõ quá bị cắt; bộ đếm chỉ hiện khi gần giới hạn',
      (tester) async {
        final app = await openFeedbackScreen(tester);
        await tester.enterText(field, 'a' * 100);
        await tester.pump();
        expect(find.textContaining('/500'), findsNothing);
        await tester.enterText(field, 'a' * 470);
        await tester.pump();
        expect(find.text('470/500'), findsOneWidget);
        await tester.enterText(field, 'b' * 700);
        await tester.pump();
        expect(tester.widget<TextField>(field).controller!.text.length, 500);
        expect(find.text('500/500'), findsOneWidget);

        await tester.tap(button('Gửi phản hồi'));
        await tester.pumpAndSettle();
        final stored = (await tester.runAsync(
          () => app.safetyRepository.getFeedbacks('u1'),
        ))!;
        expect(stored.single.text.length, 500);
      },
      size: tall,
    );

    phoneTest('đang gửi: vòng xoay, nút khoá, không gửi đúp', (tester) async {
      final app = makeAppStateWithTables(
        standardTables(),
        latency: () => const Duration(milliseconds: 500),
      );
      await tester.pumpWidget(MyApp(appState: app));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      await tester.runAsync(app.signIn);
      await tester.tap(find.text('Tôi').last);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(find.text('Phản hồi riêng tư'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      await tester.enterText(field, 'Gửi một lần');
      await tester.pump();
      await tester.tap(button('Gửi phản hồi'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      final stored = (await tester.runAsync(
        () => app.safetyRepository.getFeedbacks('u1'),
      ))!;
      expect(stored.length, 1);
      expect(find.text('Gửi một lần'), findsOneWidget);
    }, size: tall);

    phoneTest('gửi lỗi: giữ nguyên chữ, báo lỗi kèm "Gửi lại"; gửi lại được', (
      tester,
    ) async {
      late FlakySafety flaky;
      final app = makeAppStateWithTables(
        standardTables(),
        wrapSafety: (inner) => flaky = FlakySafety(inner)..failSubmit = true,
      );
      await openFeedbackScreen(tester, app: app);
      await tester.enterText(field, 'Tin sẽ lỗi');
      await tester.pump();
      await tester.tap(button('Gửi phản hồi'));
      await tester.pumpAndSettle();

      expect(find.text('Không gửi được phản hồi.'), findsOneWidget);
      expect(find.text('Gửi lại'), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, 'Tin sẽ lỗi');
      expect(flaky.submitCalls, 1);

      flaky.failSubmit = false;
      await tester.tap(find.text('Gửi lại'));
      await tester.pumpAndSettle();
      expect(find.text('Không gửi được phản hồi.'), findsNothing);
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(
        find.text('Tin sẽ lỗi'),
        findsOneWidget,
      ); // giờ nằm trong danh sách
      expect(flaky.submitCalls, 2);
    }, size: tall);

    phoneTest('"Gửi lại" khi ô đã bị xoá: gửi đúng nội dung đã lỗi', (
      tester,
    ) async {
      late FlakySafety flaky;
      final app = makeAppStateWithTables(
        standardTables(),
        wrapSafety: (inner) => flaky = FlakySafety(inner)..failSubmit = true,
      );
      await openFeedbackScreen(tester, app: app);
      await tester.enterText(field, 'Giữ giùm mình');
      await tester.pump();
      await tester.tap(button('Gửi phản hồi'));
      await tester.pumpAndSettle();
      await tester.enterText(field, '');
      await tester.pump();
      flaky.failSubmit = false;
      await tester.tap(find.text('Gửi lại'));
      await tester.pumpAndSettle();
      final stored = (await tester.runAsync(
        () => app.safetyRepository.getFeedbacks('u1'),
      ))!;
      expect(stored.map((f) => f.text), ['Giữ giùm mình']);
    }, size: tall);

    phoneTest(
      'xem lại: danh sách có sẵn hiện đúng, phản hồi của người khác thì không',
      (tester) async {
        var clock = testNow;
        final app = makeAppStateWithTables(standardTables(), now: () => clock);
        await tester.runAsync(() async {
          await app.safetyRepository.submitFeedback(
            userId: 'u1',
            text: 'Cũ của mình',
          );
          clock = DateTime(2026, 10, 5, 12);
          await app.safetyRepository.submitFeedback(
            userId: 'u1',
            text: 'Mới của mình',
          );
          await app.safetyRepository.submitFeedback(
            userId: 'u2',
            text: 'Của người khác',
          );
        });
        await openFeedbackScreen(tester, app: app);
        expect(find.text('Mới của mình'), findsOneWidget);
        expect(find.text('Cũ của mình'), findsOneWidget);
        expect(find.text('Của người khác'), findsNothing);
        expect(
          tester.getTopLeft(find.text('Mới của mình')).dy,
          lessThan(tester.getTopLeft(find.text('Cũ của mình')).dy),
        );
      },
      size: tall,
    );

    phoneTest('lỗi tải danh sách: có nút Thử lại', (tester) async {
      late FlakySafety flaky;
      final app = makeAppStateWithTables(
        standardTables(),
        wrapSafety: (inner) => flaky = FlakySafety(inner)..failLoad = true,
      );
      await openFeedbackScreen(tester, app: app);
      expect(
        find.text('Không tải được phản hồi. Kiểm tra mạng rồi thử lại nhé.'),
        findsOneWidget,
      );
      flaky.failLoad = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn chưa gửi phản hồi nào.'), findsOneWidget);
    }, size: tall);

    phoneTest('EN: màn phản hồi bằng tiếng Anh', (tester) async {
      final app = makeAppStateWithTables(standardTables())
        ..setLanguage(AppLanguage.en);
      await pumpAccount(tester, app: app);
      await tapText(tester, 'Private feedback');
      expect(
        find.text(
          'This feedback is private: only the team reads it, and nobody else can see it.',
        ),
        findsOneWidget,
      );
      expect(find.text('Send feedback'), findsOneWidget);
      expect(find.text("You haven't sent any feedback yet."), findsOneWidget);
    }, size: tall);

    phoneTest('nhãn ngữ nghĩa: ô nhập, nút gửi, tiêu đề mục là heading', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openFeedbackScreen(tester);
      expect(find.bySemanticsLabel(RegExp('Bạn muốn góp ý')), findsWidgets);
      expect(find.bySemanticsLabel('Gửi phản hồi'), findsOneWidget);
      final headers = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.header == true,
      );
      expect(headers, findsWidgets);
      handle.dispose();
    }, size: tall);
  });

  group('Trang tĩnh', () {
    final pages = {
      StaticPage.about: ('Góc "Ăn Gì Đây Ta?"', 'Gặp nhau qua món ăn'),
      StaticPage.contact: ('Liên hệ', 'Góp ý và hỗ trợ'),
      StaticPage.privacy: (
        'Chính sách quyền riêng tư',
        'Dữ liệu chúng mình dùng',
      ),
      StaticPage.terms: ('Điều khoản sử dụng', 'Dùng đúng mục đích'),
    };

    Future<void> expectPage(
      WidgetTester tester,
      String title,
      String firstHeading,
      String note,
    ) async {
      expect(find.byType(StaticPageScreen), findsOneWidget);
      expect(find.text(title), findsWidgets);
      expect(find.text(firstHeading), findsOneWidget);
      expect(find.text(note), findsOneWidget); // ghi chú "nội dung mẫu"
    }

    for (final login in [false, true]) {
      phoneTest(
        'mở đủ 4 trang từ Thông tin (${login ? 'thành viên' : 'khách'}); Back về đúng nơi',
        (tester) async {
          await pumpAccount(tester, login: login);
          await tapText(tester, 'Thông tin');
          expect(find.byType(InfoScreen), findsOneWidget);
          for (final e in pages.entries) {
            await tester.tap(find.byKey(ValueKey('info-${e.key.name}')));
            await tester.pumpAndSettle();
            await expectPage(
              tester,
              e.value.$1,
              e.value.$2,
              'Nội dung mẫu: chỉ phục vụ đồ án, chưa phải nội dung chính thức.',
            );
            await tester.pageBack();
            await tester.pumpAndSettle();
            expect(
              find.byType(InfoScreen),
              findsOneWidget,
            ); // về danh sách Thông tin
          }
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(find.byType(InfoScreen), findsNothing);
          expect(find.text('Hồ sơ của bạn'), findsOneWidget);
        },
        size: tall,
      );
    }

    phoneTest('EN: bốn trang bằng tiếng Anh', (tester) async {
      final app = makeAppStateWithTables(standardTables())
        ..setLanguage(AppLanguage.en);
      await pumpAccount(tester, app: app, login: false);
      await tapText(tester, 'Info');
      final expected = {
        StaticPage.about: ('The "Ăn Gì Đây Ta?" corner', 'Meeting over food'),
        StaticPage.contact: ('Contact', 'Feedback and support'),
        StaticPage.privacy: ('Privacy Policy', 'Data we use'),
        StaticPage.terms: ('Terms of Use', 'Use it as intended'),
      };
      for (final e in expected.entries) {
        await tester.tap(find.byKey(ValueKey('info-${e.key.name}')));
        await tester.pumpAndSettle();
        await expectPage(
          tester,
          e.value.$1,
          e.value.$2,
          'Sample content: for the course project only, not official text.',
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    }, size: tall);

    phoneTest(
      'Liên hệ: nhóm Facebook/Threads chỉ là chữ, không có liên kết bấm được',
      (tester) async {
        await pumpAccount(tester, login: false);
        await tapText(tester, 'Thông tin');
        await tester.tap(find.byKey(const ValueKey('info-contact')));
        await tester.pumpAndSettle();
        expect(find.text('Nhóm Facebook "Ăn Gì Đây Ta?"'), findsOneWidget);
        expect(find.text('Threads "Ăn Gì Đây Ta?"'), findsOneWidget);
        final body = find.byType(SingleChildScrollView);
        expect(
          find.descendant(of: body, matching: find.byType(InkWell)),
          findsNothing,
        );
        expect(find.byType(TextButton), findsNothing);
      },
      size: tall,
    );

    phoneTest('Giới thiệu nêu: không phải giao đồ ăn, vị trí riêng tư', (
      tester,
    ) async {
      await pumpAccount(tester, login: false);
      await tapText(tester, 'Thông tin');
      await tester.tap(find.byKey(const ValueKey('info-about')));
      await tester.pumpAndSettle();
      expect(find.text('Không phải giao đồ ăn'), findsOneWidget);
      expect(find.textContaining('không giao đồ ăn'), findsOneWidget);
      expect(find.text('Vị trí riêng tư'), findsOneWidget);
    }, size: tall);

    phoneTest('tiêu đề trang và các mục là heading cho trình đọc màn hình', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpAccount(tester, login: false);
      await tapText(tester, 'Thông tin');
      await tester.tap(find.byKey(const ValueKey('info-privacy')));
      await tester.pumpAndSettle();
      final headers = find.descendant(
        of: find.byType(StaticPageScreen),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.header == true,
        ),
      );
      // Thanh trên + tiêu đề trang + 4 tiêu đề mục
      expect(headers, findsNWidgets(6));
      handle.dispose();
    }, size: tall);

    phoneTest(
      'từ bảng đăng nhập: Chính sách và Điều khoản mở đúng trang; Back về bảng đăng nhập',
      (tester) async {
        await pumpAccount(tester, login: false);
        await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
        await tester.pumpAndSettle();
        expect(find.text('Vào hội thôi!'), findsOneWidget);

        await tester.tap(find.text('Chính sách quyền riêng tư'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<StaticPageScreen>(find.byType(StaticPageScreen)).page,
          StaticPage.privacy,
        );
        expect(find.text('Dữ liệu chúng mình dùng'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(StaticPageScreen), findsNothing);
        expect(
          find.text('Vào hội thôi!'),
          findsOneWidget,
        ); // bảng đăng nhập vẫn mở

        await tester.tap(find.text('Điều khoản sử dụng'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<StaticPageScreen>(find.byType(StaticPageScreen)).page,
          StaticPage.terms,
        );
        expect(find.text('Dùng đúng mục đích'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Vào hội thôi!'), findsOneWidget);
        expect(find.text('Tính năng này chưa làm.'), findsNothing);
      },
      size: tall,
    );

    phoneTest('bảng đăng nhập EN: liên kết mở trang tiếng Anh', (tester) async {
      final app = makeAppStateWithTables(standardTables())
        ..setLanguage(AppLanguage.en);
      await pumpAccount(tester, app: app, login: false);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();
      expect(find.text('Data we use'), findsOneWidget);
    }, size: tall);

    phoneTest('đăng nhập vẫn được sau khi xem trang từ bảng đăng nhập', (
      tester,
    ) async {
      final app = await pumpAccount(tester, login: false);
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Điều khoản sử dụng'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục với Google'));
      await tester.pumpAndSettle();
      expect(app.isLoggedIn, isTrue);
      expect(find.text('Phản hồi riêng tư'), findsOneWidget);
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
            final app = makeAppStateWithTables(standardTables())
              ..setLanguage(language);
            final t = app.strings;
            await pumpAccount(tester, app: app);

            // Thông tin và bốn trang
            await tapText(tester, t(StrKey.infoTitle));
            for (final page in StaticPage.values) {
              await tester.tap(find.byKey(ValueKey('info-${page.name}')));
              await tester.pumpAndSettle();
              await tester.pageBack();
              await tester.pumpAndSettle();
            }
            await tester.pageBack();
            await tester.pumpAndSettle();

            // Phản hồi: nhiều chữ, bộ đếm, lỗi gửi
            await tapText(tester, t(StrKey.privateFeedback));
            await tester.enterText(field, 'Phản hồi khá dài ' * 28);
            await tester.pump();
            await tester.tap(button(t(StrKey.fbSend)));
            await tester.pumpAndSettle();
            expect(find.textContaining('Phản hồi khá dài'), findsWidgets);
            expect(tester.takeException(), isNull);
          }, size: Size(width, 3500));
        }
      }
    }
  });
}
