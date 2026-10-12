import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/mock/mock_data.dart';
import 'package:giua_ki_app/data/mock/mock_support.dart';
import 'package:giua_ki_app/data/repositories/auth_repository.dart';
import 'package:giua_ki_app/data/repositories/mock_auth_repository.dart';

import 'test_helpers.dart';

MockAuthRepository make() => MockAuthRepository(
  users: mockUsers,
  latency: noLatency,
  now: () => testNow,
);

Matcher authError(AuthError e) =>
    throwsA(isA<AuthException>().having((x) => x.error, 'error', e));

void main() {
  group('đăng ký', () {
    test('thành công: tạo tài khoản mới, KHÔNG tự đăng nhập', () async {
      final repo = make();
      final user = await repo.register(
        displayName: '  Trần   Văn A ',
        email: ' New.User@Example.COM ',
        password: 'matkhau1',
      );
      expect(user.id, isNotEmpty);
      expect(user.displayName, 'Trần Văn A');
      expect(user.email, 'new.user@example.com'); // chữ thường
      expect(user.createdAt, testNow);
      expect(user.isGuest, isFalse);
      // Chưa đăng nhập
      expect(await repo.getCurrentUser(), isNull);
      // Tra được qua getUser (để hiện tên trong bàn, chat)
      expect((await repo.getUser(user.id))?.email, 'new.user@example.com');
    });

    test('id duy nhất và không trùng id mẫu', () async {
      final repo = make();
      final a = await repo.register(
        displayName: 'An',
        email: 'a@example.com',
        password: 'abcdef',
      );
      final b = await repo.register(
        displayName: 'Bình',
        email: 'b@example.com',
        password: 'abcdef',
      );
      expect(a.id, isNot(b.id));
      final sampleIds = mockUsers.map((u) => u.id).toSet();
      expect(sampleIds, isNot(contains(a.id)));
      expect(sampleIds, isNot(contains(b.id)));
    });

    test(
      'trùng email tài khoản mẫu bị từ chối, không phân biệt hoa thường',
      () async {
        final repo = make();
        await expectLater(
          repo.register(
            displayName: 'Ai Đó',
            email: 'MinhAnh@Example.com',
            password: 'abcdef',
          ),
          authError(AuthError.emailTaken),
        );
      },
    );

    test('trùng email tài khoản vừa đăng ký bị từ chối', () async {
      final repo = make();
      await repo.register(
        displayName: 'An',
        email: 'an@example.com',
        password: 'abcdef',
      );
      await expectLater(
        repo.register(
          displayName: 'Khác',
          email: '  AN@example.com ',
          password: 'ghijkl',
        ),
        authError(AuthError.emailTaken),
      );
    });

    test('không đổi các tài khoản mẫu và không làm mất tài khoản cũ', () async {
      final repo = make();
      await repo.register(
        displayName: 'An',
        email: 'an@example.com',
        password: 'abcdef',
      );
      for (final u in mockUsers) {
        expect((await repo.getUser(u.id))?.email, u.email);
      }
      expect(mockUsers.length, 8); // danh sách mẫu gốc không bị thêm
    });
  });

  group('đăng nhập bằng email + mật khẩu', () {
    Future<MockAuthRepository> withAccount() async {
      final repo = make();
      await repo.register(
        displayName: 'Trần Văn A',
        email: 'an@example.com',
        password: 'matkhau1',
      );
      return repo;
    }

    test(
      'đúng email (không phân biệt hoa thường) và mật khẩu: vào được',
      () async {
        final repo = await withAccount();
        final user = await repo.signInWithPassword(
          email: ' AN@Example.com ',
          password: 'matkhau1',
        );
        expect(user.displayName, 'Trần Văn A');
        expect((await repo.getCurrentUser())?.id, user.id);
      },
    );

    test('sai mật khẩu: lỗi wrongPassword và vẫn là khách', () async {
      final repo = await withAccount();
      await expectLater(
        repo.signInWithPassword(email: 'an@example.com', password: 'sai-roi'),
        authError(AuthError.wrongPassword),
      );
      // Mật khẩu phân biệt hoa thường
      await expectLater(
        repo.signInWithPassword(email: 'an@example.com', password: 'MATKHAU1'),
        authError(AuthError.wrongPassword),
      );
      expect(await repo.getCurrentUser(), isNull);
    });

    test('email không tồn tại: lỗi emailNotFound', () async {
      final repo = await withAccount();
      await expectLater(
        repo.signInWithPassword(
          email: 'khong-co@example.com',
          password: 'matkhau1',
        ),
        authError(AuthError.emailNotFound),
      );
    });

    test(
      'tài khoản mẫu không có mật khẩu: không vào được bằng mật khẩu',
      () async {
        final repo = make();
        await expectLater(
          repo.signInWithPassword(email: 'minhanh@example.com', password: ''),
          authError(AuthError.wrongPassword),
        );
        await expectLater(
          repo.signInWithPassword(
            email: 'minhanh@example.com',
            password: 'abcdef',
          ),
          authError(AuthError.wrongPassword),
        );
      },
    );

    test('đăng xuất rồi đăng nhập lại vẫn thấy tài khoản mới', () async {
      final repo = await withAccount();
      await repo.signInWithPassword(
        email: 'an@example.com',
        password: 'matkhau1',
      );
      await repo.signOut();
      expect(await repo.getCurrentUser(), isNull);
      final again = await repo.signInWithPassword(
        email: 'an@example.com',
        password: 'matkhau1',
      );
      expect(again.email, 'an@example.com');
    });

    test('đăng nhập Google giả lập vẫn vào tài khoản mẫu như cũ', () async {
      final repo = await withAccount();
      final user = await repo.signIn();
      expect(user.id, 'u1');
    });
  });
}
