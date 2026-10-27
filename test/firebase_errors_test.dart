import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/models/user.dart';
import 'package:giua_ki_app/data/repositories/auth_repository.dart';
import 'package:giua_ki_app/data/repositories/firebase_errors.dart';
import 'package:giua_ki_app/data/repositories/table_repository.dart';
import 'package:giua_ki_app/l10n/strings.dart';
import 'package:giua_ki_app/main.dart';

import 'test_helpers.dart';

// AuthRepository luôn ném một AuthError cho trước (để thử thông báo trên giao diện).
class ThrowingAuth implements AuthRepository {
  ThrowingAuth(this.error);

  final AuthError error;

  @override
  Future<User?> getCurrentUser() async => null;
  @override
  Future<User> signIn() async => throw AuthException(error);
  @override
  Future<User> register({
    required String displayName,
    required String email,
    required String password,
  }) async => throw AuthException(error);
  @override
  Future<User> signInWithPassword({
    required String email,
    required String password,
  }) async => throw AuthException(error);
  @override
  Future<void> signOut() async {}
  @override
  Future<User?> getUser(String id) async => null;
}

void main() {
  group('authErrorFromCode (mã lỗi Firebase Auth -> AuthError)', () {
    const expected = {
      'email-already-in-use': AuthError.emailTaken,
      'weak-password': AuthError.weakPassword,
      'invalid-email': AuthError.invalidEmail,
      'user-not-found': AuthError.emailNotFound,
      'wrong-password': AuthError.wrongPassword,
      'invalid-credential': AuthError.invalidCredential,
      'invalid-login-credentials': AuthError.invalidCredential,
      'network-request-failed': AuthError.network,
      'unavailable': AuthError.network,
      'deadline-exceeded': AuthError.network,
      'too-many-requests': AuthError.tooManyRequests,
      'user-disabled': AuthError.userDisabled,
      'operation-not-allowed': AuthError.notAllowed,
      'permission-denied': AuthError.permissionDenied,
    };
    for (final e in expected.entries) {
      test('${e.key} -> ${e.value.name}', () {
        expect(authErrorFromCode(e.key), e.value);
      });
    }

    test('mã lạ hoặc rỗng -> unknown', () {
      expect(authErrorFromCode('khong-biet'), AuthError.unknown);
      expect(authErrorFromCode(''), AuthError.unknown);
    });
  });

  group('thông báo đã Việt hoá cho mọi AuthError', () {
    test(
      'mỗi lỗi có thông báo VI và EN khác rỗng, khác nhau và không lộ tên khoá',
      () {
        const vi = Strings(AppLanguage.vi);
        const en = Strings(AppLanguage.en);
        final viMessages = <String>{};
        for (final e in AuthError.values) {
          final v = vi.authError(e);
          final x = en.authError(e);
          expect(v, isNotEmpty, reason: e.name);
          expect(x, isNotEmpty, reason: e.name);
          expect(v, isNot(x), reason: e.name);
          expect(v, isNot(e.name), reason: e.name);
          viMessages.add(v);
        }
        expect(
          viMessages.length,
          AuthError.values.length,
        ); // mỗi lỗi một câu riêng
      },
    );

    test('các câu quan trọng đúng nội dung tiếng Việt', () {
      const vi = Strings(AppLanguage.vi);
      expect(vi.authError(AuthError.emailTaken), 'Email đã được sử dụng.');
      expect(vi.authError(AuthError.weakPassword), contains('quá yếu'));
      expect(
        vi.authError(AuthError.invalidCredential),
        'Email hoặc mật khẩu không đúng.',
      );
      expect(vi.authError(AuthError.network), contains('kết nối mạng'));
      expect(
        vi.authError(AuthError.tooManyRequests),
        contains('quá nhiều lần'),
      );
    });
  });

  group('guardFirebase / guardData', () {
    test('FirebaseAuthException thành AuthException đã phân loại', () async {
      await expectLater(
        guardFirebase<void>(
          () async => throw FirebaseAuthException(code: 'email-already-in-use'),
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.error,
            'error',
            AuthError.emailTaken,
          ),
        ),
      );
      await expectLater(
        guardFirebase<void>(
          () async =>
              throw FirebaseAuthException(code: 'network-request-failed'),
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.error,
            'error',
            AuthError.network,
          ),
        ),
      );
    });

    test(
      'FirebaseException (Firestore) và lỗi lạ thành AuthException',
      () async {
        await expectLater(
          guardFirebase<void>(
            () async => throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            ),
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.error,
              'error',
              AuthError.permissionDenied,
            ),
          ),
        );
        await expectLater(
          guardFirebase<void>(() async => throw StateError('lạ')),
          throwsA(
            isA<AuthException>().having(
              (e) => e.error,
              'error',
              AuthError.unknown,
            ),
          ),
        );
      },
    );

    test('AuthException và kết quả bình thường đi qua nguyên vẹn', () async {
      await expectLater(
        guardFirebase<void>(
          () async => throw const AuthException(AuthError.wrongPassword),
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.error,
            'error',
            AuthError.wrongPassword,
          ),
        ),
      );
      expect(await guardFirebase(() async => 42), 42);
    });

    test(
      'guardData: lỗi Firebase thành DataException, TableException đi qua',
      () async {
        await expectLater(
          guardData<void>(
            () async => throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'unavailable',
            ),
          ),
          throwsA(
            isA<DataException>().having((e) => e.code, 'code', 'unavailable'),
          ),
        );
        await expectLater(
          guardData<void>(
            () async => throw const TableException(TableError.full),
          ),
          throwsA(isA<TableException>()),
        );
        expect(await guardData(() async => 'ok'), 'ok');
      },
    );
  });

  group('thông báo lỗi tài khoản trên giao diện', () {
    phoneTest('đăng ký gặp lỗi mạng: hiện câu tiếng Việt, không sập', (
      tester,
    ) async {
      final app = makeAppStateWithTables(
        const [],
        authRepository: ThrowingAuth(AuthError.network),
      );
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tôi').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Họ tên'),
        'Trần Văn A',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'a@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mật khẩu'),
        'matkhau1',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Nhập lại mật khẩu'),
        'matkhau1',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Đăng ký'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng ký'));
      await tester.pumpAndSettle();
      expect(
        find.text('Không có kết nối mạng. Kiểm tra mạng rồi thử lại nhé.'),
        findsOneWidget,
      );
      // Nút dùng lại được để thử lần nữa
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    }, size: const Size(412, 3500));

    phoneTest(
      'đăng ký với mật khẩu yếu (Firebase từ chối): hiện câu mật khẩu quá yếu',
      (tester) async {
        final app = makeAppStateWithTables(
          const [],
          authRepository: ThrowingAuth(AuthError.weakPassword),
        );
        await tester.pumpWidget(MyApp(appState: app));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tôi').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Chưa có tài khoản? Đăng ký'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Họ tên'),
          'Trần Văn A',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Email'),
          'a@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Mật khẩu'),
          'matkhau1',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Nhập lại mật khẩu'),
          'matkhau1',
        );
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Đăng ký'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Đăng ký'));
        await tester.pumpAndSettle();
        expect(
          find.text('Mật khẩu quá yếu, hãy dùng ít nhất 6 ký tự.'),
          findsOneWidget,
        );
      },
      size: const Size(412, 3500),
    );

    phoneTest(
      'đăng nhập: email/mật khẩu sai hiện lỗi chung; Google chưa hỗ trợ hiện câu riêng',
      (tester) async {
        final app = makeAppStateWithTables(
          const [],
          authRepository: ThrowingAuth(AuthError.invalidCredential),
        );
        await tester.pumpWidget(MyApp(appState: app));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tôi').last);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Email'),
          'a@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Mật khẩu'),
          'matkhau1',
        );
        await tester.tap(find.text('Đăng nhập bằng email'));
        await tester.pumpAndSettle();
        expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
        expect(app.isLoggedIn, isFalse);
      },
      size: const Size(412, 3500),
    );

    phoneTest(
      'đăng nhập Google bị từ chối: hiện "Cách đăng nhập này chưa được bật."',
      (tester) async {
        final app = makeAppStateWithTables(
          const [],
          authRepository: ThrowingAuth(AuthError.notAllowed),
        );
        await tester.pumpWidget(MyApp(appState: app));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tôi').last);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tiếp tục với Google'));
        await tester.pumpAndSettle();
        expect(find.text('Cách đăng nhập này chưa được bật.'), findsOneWidget);
      },
      size: const Size(412, 3500),
    );
  });
}
