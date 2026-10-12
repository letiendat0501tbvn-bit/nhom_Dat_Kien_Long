import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/mock/mock_data.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/models/user.dart';
import 'package:giua_ki_app/data/repositories/auth_repository.dart';
import 'package:giua_ki_app/data/repositories/mock_auth_repository.dart';
import 'package:giua_ki_app/l10n/strings.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/state/app_state.dart';
import 'package:giua_ki_app/ui/screens/register_screen.dart';

import 'test_helpers.dart';

const tall = Size(412, 3500);

// AuthRepository bọc bản mock để đếm số lần đăng ký.
class CountingAuth implements AuthRepository {
  CountingAuth(this.inner);

  final MockAuthRepository inner;
  int registerCalls = 0;

  @override
  Future<User> register({
    required String displayName,
    required String email,
    required String password,
  }) {
    registerCalls++;
    return inner.register(
      displayName: displayName,
      email: email,
      password: password,
    );
  }

  @override
  Future<User?> getCurrentUser() => inner.getCurrentUser();
  @override
  Future<User> signIn() => inner.signIn();
  @override
  Future<User> signInWithPassword({
    required String email,
    required String password,
  }) => inner.signInWithPassword(email: email, password: password);
  @override
  Future<void> signOut() => inner.signOut();
  @override
  Future<User?> getUser(String id) => inner.getUser(id);
}

Finder field(String label) => find.widgetWithText(TextField, label);
Finder get registerButton => find.widgetWithText(FilledButton, 'Đăng ký');

Future<void> tapText(
  WidgetTester tester,
  String text, {
  bool last = false,
}) async {
  final f = last ? find.text(text).last : find.text(text).first;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

// Mở app (khách) và sang tab Tôi.
Future<AppState> pumpAccount(WidgetTester tester, {AppState? app}) async {
  final state = app ?? makeAppState();
  await tester.pumpWidget(MyApp(appState: state));
  await tester.pumpAndSettle();
  await tester.tap(
    find.text(state.language == AppLanguage.vi ? 'Tôi' : 'Me').last,
  );
  await tester.pumpAndSettle();
  return state;
}

// Mở màn Đăng ký từ tab Tôi.
Future<AppState> openRegisterFromAccount(
  WidgetTester tester, {
  AppState? app,
}) async {
  final state = await pumpAccount(tester, app: app);
  await tapText(tester, state.strings(StrKey.loginNoAccount));
  return state;
}

Future<void> fill(
  WidgetTester tester, {
  String name = 'Trần Văn A',
  String email = 'New.User@Example.com',
  String password = 'matkhau1',
  String? confirm,
}) async {
  await tester.enterText(field('Họ tên'), name);
  await tester.enterText(field('Email'), email);
  await tester.enterText(field('Mật khẩu'), password);
  await tester.enterText(field('Nhập lại mật khẩu'), confirm ?? password);
  await tester.pump();
}

Future<void> submit(WidgetTester tester) async {
  await tester.ensureVisible(registerButton);
  await tester.pumpAndSettle();
  await tester.tap(registerButton);
  await tester.pumpAndSettle();
}

void main() {
  group('Lối vào màn Đăng ký', () {
    phoneTest('từ tab Tôi khi chưa đăng nhập', (tester) async {
      await openRegisterFromAccount(tester);
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('Tạo tài khoản'), findsOneWidget);
      for (final l in ['Họ tên', 'Email', 'Mật khẩu', 'Nhập lại mật khẩu']) {
        expect(field(l), findsOneWidget, reason: l);
      }
      expect(registerButton, findsOneWidget);
      expect(find.text('Đã có tài khoản? Đăng nhập'), findsOneWidget);
    }, size: tall);

    phoneTest('từ bảng đăng nhập (liên kết "Chưa có tài khoản? Đăng ký")', (
      tester,
    ) async {
      await pumpAccount(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.text('Vào hội thôi!'), findsOneWidget);
      await tapText(tester, 'Chưa có tài khoản? Đăng ký', last: true);
      expect(find.byType(RegisterScreen), findsOneWidget);
    }, size: tall);

    phoneTest('thành viên đã đăng nhập không thấy liên kết đăng ký ở tab Tôi', (
      tester,
    ) async {
      final app = makeAppState();
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await tester.runAsync(app.signIn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tôi').last);
      await tester.pumpAndSettle();
      expect(find.text('Chưa có tài khoản? Đăng ký'), findsNothing);
    }, size: tall);

    phoneTest('Back về tab Tôi, vẫn là khách', (tester) async {
      final app = await openRegisterFromAccount(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.text('Khách ghé chơi'), findsOneWidget);
      expect(app.isLoggedIn, isFalse);
    }, size: tall);
  });

  group('Kiểm tra hợp lệ ngay dưới từng ô', () {
    phoneTest('bấm Đăng ký khi chưa điền: báo lỗi cả bốn ô, chưa tạo gì', (
      tester,
    ) async {
      await openRegisterFromAccount(tester);
      await submit(tester);
      expect(find.text('Nhập họ tên của bạn.'), findsOneWidget);
      expect(find.text('Nhập email của bạn.'), findsOneWidget);
      expect(find.text('Nhập mật khẩu.'), findsOneWidget);
      expect(find.text('Nhập lại mật khẩu.'), findsWidgets); // nhãn ô + lỗi
      expect(find.byType(RegisterScreen), findsOneWidget);
    }, size: tall);

    phoneTest('từng lỗi nằm ngay dưới ô tương ứng', (tester) async {
      await openRegisterFromAccount(tester);
      await fill(
        tester,
        name: 'A',
        email: 'khong-phai-email',
        password: '123',
        confirm: '456',
      );
      await submit(tester);

      double errorY(String text) => tester.getTopLeft(find.text(text)).dy;
      double fieldBottom(String label) => tester.getBottomLeft(field(label)).dy;
      expect(find.text('Họ tên từ 2 đến 40 ký tự.'), findsOneWidget);
      expect(find.text('Email chưa đúng định dạng.'), findsOneWidget);
      expect(find.text('Mật khẩu tối thiểu 6 ký tự.'), findsOneWidget);
      expect(find.text('Mật khẩu nhập lại chưa khớp.'), findsOneWidget);
      // Lỗi nằm trong ô (ngay dưới đường viền nhập) của đúng ô đó
      expect(
        errorY('Họ tên từ 2 đến 40 ký tự.'),
        greaterThan(tester.getTopLeft(field('Họ tên')).dy),
      );
      expect(
        errorY('Họ tên từ 2 đến 40 ký tự.'),
        lessThanOrEqualTo(fieldBottom('Họ tên')),
      );
      expect(
        errorY('Email chưa đúng định dạng.'),
        greaterThan(tester.getTopLeft(field('Email')).dy),
      );
      expect(
        errorY('Email chưa đúng định dạng.'),
        lessThanOrEqualTo(fieldBottom('Email')),
      );
    }, size: tall);

    phoneTest('sau lần thử đầu, sửa ô nào thì lỗi ô đó biến mất ngay', (
      tester,
    ) async {
      await openRegisterFromAccount(tester);
      await submit(tester);
      expect(find.text('Nhập họ tên của bạn.'), findsOneWidget);
      await tester.enterText(field('Họ tên'), 'Trần Văn A');
      await tester.pump();
      expect(find.text('Nhập họ tên của bạn.'), findsNothing);
      expect(
        find.text('Nhập email của bạn.'),
        findsOneWidget,
      ); // ô khác vẫn lỗi
    }, size: tall);

    phoneTest('họ tên: cắt khoảng trắng hai đầu trước khi tính độ dài', (
      tester,
    ) async {
      await openRegisterFromAccount(tester);
      await fill(tester, name: '   A   ');
      await submit(tester);
      expect(find.text('Họ tên từ 2 đến 40 ký tự.'), findsOneWidget);
      await tester.enterText(field('Họ tên'), '   An   ');
      await tester.pump();
      expect(find.text('Họ tên từ 2 đến 40 ký tự.'), findsNothing);
    }, size: tall);

    phoneTest(
      'email trùng tài khoản mẫu (khác hoa thường): "Email đã được sử dụng."',
      (tester) async {
        final app = await openRegisterFromAccount(tester);
        await fill(tester, email: 'MINHANH@Example.com');
        await submit(tester);
        expect(find.text('Email đã được sử dụng.'), findsOneWidget);
        expect(find.byType(RegisterScreen), findsOneWidget);
        expect(app.isLoggedIn, isFalse);

        // Đổi email là hết lỗi và đăng ký được
        await tester.enterText(field('Email'), 'khac@example.com');
        await tester.pump();
        expect(find.text('Email đã được sử dụng.'), findsNothing);
        await submit(tester);
        expect(find.byType(RegisterScreen), findsNothing);
      },
      size: tall,
    );

    phoneTest('nút bật/tắt hiện mật khẩu áp dụng cho cả hai ô mật khẩu', (
      tester,
    ) async {
      await openRegisterFromAccount(tester);
      bool obscured(String label) =>
          tester.widget<TextField>(field(label)).obscureText;
      expect(obscured('Mật khẩu'), isTrue);
      expect(obscured('Nhập lại mật khẩu'), isTrue);
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pump();
      expect(obscured('Mật khẩu'), isFalse);
      expect(obscured('Nhập lại mật khẩu'), isFalse);
      expect(find.byTooltip('Ẩn mật khẩu'), findsWidgets);
      await tester.tap(find.byTooltip('Ẩn mật khẩu').first);
      await tester.pump();
      expect(obscured('Mật khẩu'), isTrue);
    }, size: tall);
  });

  group('Đang xử lý', () {
    phoneTest(
      'nút có vòng quay, các ô bị khoá, bấm hai lần chỉ đăng ký một lần',
      (tester) async {
        final data = MockData.build(testNow);
        final counting = CountingAuth(
          MockAuthRepository(
            users: data.users,
            latency: () => const Duration(milliseconds: 500),
            now: () => testNow,
          ),
        );
        final app = makeAppStateWithTables(const [], authRepository: counting);
        await openRegisterFromAccount(tester, app: app);
        await fill(tester);
        await tester.ensureVisible(registerButton);
        await tester.pump();
        await tester.tap(registerButton);
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
        expect(tester.widget<TextField>(field('Email')).enabled, isFalse);
        await tester.tap(find.byType(FilledButton), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 100));

        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 600));
        }
        expect(counting.registerCalls, 1);
        expect(find.byType(RegisterScreen), findsNothing);
      },
      size: tall,
    );
  });

  group('Đăng ký thành công', () {
    phoneTest('quay về bảng đăng nhập với email điền sẵn, KHÔNG tự đăng nhập', (
      tester,
    ) async {
      final app = await openRegisterFromAccount(tester);
      await fill(tester);
      await submit(tester);

      expect(find.byType(RegisterScreen), findsNothing);
      expect(
        find.text('Đăng ký thành công! Hãy đăng nhập bằng tài khoản mới.'),
        findsOneWidget,
      );
      expect(find.text('Vào hội thôi!'), findsOneWidget);
      // Email đã được chuẩn hoá thành chữ thường và điền sẵn
      expect(
        tester.widget<TextField>(field('Email')).controller!.text,
        'new.user@example.com',
      );
      expect(
        tester.widget<TextField>(field('Mật khẩu')).controller!.text,
        isEmpty,
      );
      expect(app.isLoggedIn, isFalse);
    }, size: tall);

    phoneTest('đăng ký từ bảng đăng nhập: quay lại đúng bảng, email điền sẵn', (
      tester,
    ) async {
      final app = await pumpAccount(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Chưa có tài khoản? Đăng ký', last: true);
      await fill(tester);
      await submit(tester);
      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.text('Vào hội thôi!'), findsOneWidget);
      expect(
        tester.widget<TextField>(field('Email')).controller!.text,
        'new.user@example.com',
      );
      expect(app.isLoggedIn, isFalse);
    }, size: tall);

    phoneTest(
      'đăng nhập bằng tài khoản mới: tab Tài khoản đúng tên và email; Bàn của tôi rỗng thân thiện',
      (tester) async {
        final app = await openRegisterFromAccount(tester);
        await fill(tester, name: '  Trần   Văn A ');
        await submit(tester);
        await tester.enterText(field('Mật khẩu'), 'matkhau1');
        await tapText(tester, 'Đăng nhập bằng email');

        expect(app.isLoggedIn, isTrue);
        expect(app.currentUser!.displayName, 'Trần Văn A');
        expect(find.text('Vào hội thôi!'), findsNothing);
        expect(find.text('Trần Văn A'), findsOneWidget);
        expect(find.text('new.user@example.com'), findsOneWidget);

        await tester.tap(find.text('Lịch hẹn').last);
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Bạn chưa có bàn nào. Mở bàn mới hoặc tìm một bàn để tham gia nhé!',
          ),
          findsOneWidget,
        );
        expect(find.text('Mở bàn mới'), findsOneWidget);
        expect(find.text('Tìm bàn ăn'), findsOneWidget);
        expect(find.text('Sắp tới'), findsNothing); // chưa tham gia bàn nào
      },
      size: tall,
    );

    phoneTest('đăng xuất rồi đăng nhập lại vẫn thấy tài khoản mới', (
      tester,
    ) async {
      final app = await openRegisterFromAccount(tester);
      await fill(tester);
      await submit(tester);
      await tester.enterText(field('Mật khẩu'), 'matkhau1');
      await tapText(tester, 'Đăng nhập bằng email');
      expect(app.isLoggedIn, isTrue);

      // Đăng xuất qua hộp xác nhận
      await tapText(tester, 'Đăng xuất');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Đăng xuất'),
        ),
      );
      await tester.pumpAndSettle();
      expect(app.isLoggedIn, isFalse);
      expect(find.text('Khách ghé chơi'), findsOneWidget);

      // Đăng nhập lại bằng email và mật khẩu
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Email'), 'NEW.user@example.COM');
      await tester.enterText(field('Mật khẩu'), 'matkhau1');
      await tapText(tester, 'Đăng nhập bằng email');
      expect(app.isLoggedIn, isTrue);
      expect(find.text('new.user@example.com'), findsOneWidget);
    }, size: tall);

    phoneTest(
      '"Đã có tài khoản? Đăng nhập" về bảng đăng nhập (giữ email đã gõ)',
      (tester) async {
        final app = await openRegisterFromAccount(tester);
        await tester.enterText(field('Email'), 'toi@example.com');
        await tapText(tester, 'Đã có tài khoản? Đăng nhập');
        expect(find.byType(RegisterScreen), findsNothing);
        expect(find.text('Vào hội thôi!'), findsOneWidget);
        expect(
          tester.widget<TextField>(field('Email')).controller!.text,
          'toi@example.com',
        );
        expect(app.isLoggedIn, isFalse);
      },
      size: tall,
    );
  });

  group('Đăng nhập bằng email trong bảng đăng nhập', () {
    Future<AppState> openSheetWithAccount(WidgetTester tester) async {
      final app = await openRegisterFromAccount(tester);
      await fill(tester);
      await submit(tester);
      return app;
    }

    phoneTest(
      'sai mật khẩu: báo "Sai mật khẩu." dưới ô mật khẩu, vẫn là khách',
      (tester) async {
        final app = await openSheetWithAccount(tester);
        await tester.enterText(field('Mật khẩu'), 'sai-roi-nhe');
        await tapText(tester, 'Đăng nhập bằng email');
        expect(find.text('Sai mật khẩu.'), findsOneWidget);
        expect(find.text('Vào hội thôi!'), findsOneWidget);
        expect(app.isLoggedIn, isFalse);
        // Gõ lại thì lỗi biến mất
        await tester.enterText(field('Mật khẩu'), 'matkhau1');
        await tester.pump();
        expect(find.text('Sai mật khẩu.'), findsNothing);
      },
      size: tall,
    );

    phoneTest('email không tồn tại: báo dưới ô email', (tester) async {
      final app = await openSheetWithAccount(tester);
      await tester.enterText(field('Email'), 'khong-co@example.com');
      await tester.enterText(field('Mật khẩu'), 'matkhau1');
      await tapText(tester, 'Đăng nhập bằng email');
      expect(find.text('Không có tài khoản với email này.'), findsOneWidget);
      expect(app.isLoggedIn, isFalse);
    }, size: tall);

    phoneTest(
      'để trống hoặc email sai định dạng: báo lỗi tại ô, chưa gọi đăng nhập',
      (tester) async {
        await pumpAccount(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
        await tester.pumpAndSettle();
        await tapText(tester, 'Đăng nhập bằng email');
        expect(find.text('Nhập email của bạn.'), findsOneWidget);
        expect(find.text('Nhập mật khẩu.'), findsOneWidget);
        await tester.enterText(field('Email'), 'abc');
        await tapText(tester, 'Đăng nhập bằng email');
        expect(find.text('Email chưa đúng định dạng.'), findsOneWidget);
      },
      size: tall,
    );

    phoneTest(
      'tài khoản mẫu không có mật khẩu: vào bằng email báo sai mật khẩu; nút Google vẫn vào',
      (tester) async {
        final app = await pumpAccount(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
        await tester.pumpAndSettle();
        await tester.enterText(field('Email'), 'minhanh@example.com');
        await tester.enterText(field('Mật khẩu'), 'abcdef');
        await tapText(tester, 'Đăng nhập bằng email');
        expect(find.text('Sai mật khẩu.'), findsOneWidget);
        expect(app.isLoggedIn, isFalse);
        await tapText(tester, 'Tiếp tục với Google');
        expect(app.isLoggedIn, isTrue);
        expect(app.currentUser!.id, 'u1');
      },
      size: tall,
    );

    phoneTest('đăng nhập xong KHÔNG tự tham gia hay mở bàn nào', (
      tester,
    ) async {
      final app = await openSheetWithAccount(tester);
      await tester.enterText(field('Mật khẩu'), 'matkhau1');
      await tapText(tester, 'Đăng nhập bằng email');
      final user = app.currentUser!;
      final mine = (await tester.runAsync(
        () => app.tableRepository.getMyTables(user.id),
      ))!;
      expect(mine, isEmpty);
    }, size: tall);
  });

  group('Tiếng Anh', () {
    phoneTest('màn Đăng ký và lỗi bằng tiếng Anh', (tester) async {
      final app = makeAppState()..setLanguage(AppLanguage.en);
      await openRegisterFromAccount(tester, app: app);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Full name'), findsOneWidget);
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign up'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your name.'), findsOneWidget);
      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Enter a password.'), findsOneWidget);
      expect(find.text('Already have an account? Sign in'), findsOneWidget);
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
            final app = makeAppState()..setLanguage(language);
            final t = app.strings;
            await openRegisterFromAccount(tester, app: app);
            expect(tester.takeException(), isNull);

            // Bấm Đăng ký khi trống: cả bốn lỗi hiện ra
            final button = find.widgetWithText(
              FilledButton,
              t(StrKey.registerButton),
            );
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            await tester.tap(button);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            // Lỗi dài hơn: sai định dạng, mật khẩu ngắn, không khớp; bật hiện mật khẩu
            await tester.enterText(
              find.widgetWithText(TextField, t(StrKey.fieldEmail)),
              'khong-hop-le',
            );
            await tester.enterText(
              find.widgetWithText(TextField, t(StrKey.fieldPassword)),
              '123',
            );
            await tester.enterText(
              find.widgetWithText(TextField, t(StrKey.fieldConfirm)),
              '456',
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byTooltip(t(StrKey.showPassword)));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            // Bảng đăng nhập có thêm form email + mật khẩu
            await tester.pageBack();
            await tester.pumpAndSettle();
            await tester.tap(
              find.widgetWithText(FilledButton, t(StrKey.signIn)),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.text(t(StrKey.loginEmailButton)));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }, size: Size(width, 3500));
        }
      }
    }
  });
}
