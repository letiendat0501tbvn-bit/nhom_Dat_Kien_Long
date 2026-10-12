import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/logic/account_rules.dart';

void main() {
  group('validateName', () {
    test('bắt buộc; rỗng hoặc toàn khoảng trắng là thiếu', () {
      expect(validateName(''), AccountIssue.nameRequired);
      expect(validateName('    '), AccountIssue.nameRequired);
    });

    test('2–40 ký tự sau khi cắt khoảng trắng hai đầu', () {
      expect(validateName('A'), AccountIssue.nameLength);
      expect(validateName('  A  '), AccountIssue.nameLength); // chỉ còn 1 ký tự
      expect(validateName('An'), isNull);
      expect(validateName('  An  '), isNull);
      expect(validateName('a' * 40), isNull);
      expect(validateName('a' * 41), AccountIssue.nameLength);
      expect(
        validateName('  ${'a' * 40}  '),
        isNull,
      ); // khoảng trắng hai đầu không tính
    });

    test('có dấu tiếng Việt vẫn tính theo ký tự', () {
      expect(validateName('Nguyễn Thị Ánh Tuyết'), isNull);
    });

    test('normalizeName cắt hai đầu và gộp khoảng trắng bên trong', () {
      expect(normalizeName('  Minh   Anh  '), 'Minh Anh');
    });
  });

  group('email', () {
    test('bắt buộc', () {
      expect(validateEmail(''), AccountIssue.emailRequired);
      expect(validateEmail('   '), AccountIssue.emailRequired);
    });

    test('định dạng hợp lệ', () {
      for (final e in [
        'a@b.co',
        'minh.anh@example.com',
        'x_y+z@mail.example.vn',
        '  a@b.co  ', // khoảng trắng hai đầu được cắt
        'A@B.CO',
      ]) {
        expect(validateEmail(e), isNull, reason: e);
      }
    });

    test('định dạng sai', () {
      for (final e in [
        'abc',
        'abc@',
        '@b.co',
        'a@b',
        'a@b.',
        'a@.co',
        'a b@c.co',
        'a@@b.co',
        'a@b..co',
      ]) {
        expect(validateEmail(e), AccountIssue.emailInvalid, reason: e);
      }
    });

    test(
      'trùng email đã có, không phân biệt hoa thường và khoảng trắng hai đầu',
      () {
        const existing = ['minhanh@example.com', 'Quocbao@Example.com'];
        expect(
          validateEmail('minhanh@example.com', existingEmails: existing),
          AccountIssue.emailTaken,
        );
        expect(
          validateEmail('  MINHANH@Example.COM ', existingEmails: existing),
          AccountIssue.emailTaken,
        );
        expect(
          validateEmail('quocbao@example.com', existingEmails: existing),
          AccountIssue.emailTaken,
        );
        expect(
          validateEmail('moi@example.com', existingEmails: existing),
          isNull,
        );
      },
    );

    test('định dạng sai được báo trước khi xét trùng', () {
      expect(
        validateEmail('abc', existingEmails: const ['abc']),
        AccountIssue.emailInvalid,
      );
    });

    test('normalizeEmail chữ thường, cắt hai đầu; isEmailTaken', () {
      expect(normalizeEmail('  A.B@Mail.COM '), 'a.b@mail.com');
      expect(isEmailTaken('A@B.co', const ['a@b.CO']), isTrue);
      expect(isEmailTaken('a@b.co', const []), isFalse);
    });
  });

  group('mật khẩu', () {
    test('bắt buộc và tối thiểu 6 ký tự', () {
      expect(validatePassword(''), AccountIssue.passwordRequired);
      expect(validatePassword('12345'), AccountIssue.passwordShort);
      expect(validatePassword('123456'), isNull);
      expect(validatePassword('a' * 100), isNull);
    });

    test('khoảng trắng tính là ký tự (mật khẩu không bị cắt)', () {
      expect(validatePassword('      '), isNull); // 6 dấu cách
      expect(validatePassword('  ab  '), isNull);
    });

    test('nhập lại phải khớp', () {
      expect(validateConfirm('abcdef', ''), AccountIssue.confirmRequired);
      expect(
        validateConfirm('abcdef', 'abcdeF'),
        AccountIssue.passwordMismatch,
      );
      expect(validateConfirm('abcdef', 'abcdef'), isNull);
    });
  });

  group('validateRegistration', () {
    Map<AccountField, AccountIssue> run({
      String name = 'Minh Anh',
      String email = 'moi@example.com',
      String password = 'matkhau1',
      String confirm = 'matkhau1',
      List<String> existing = const [],
    }) => validateRegistration(
      name: name,
      email: email,
      password: password,
      confirm: confirm,
      existingEmails: existing,
    );

    test('form hợp lệ không có lỗi', () {
      expect(run(), isEmpty);
    });

    test('form trống: lỗi ở cả bốn ô', () {
      expect(run(name: '', email: '', password: '', confirm: ''), {
        AccountField.name: AccountIssue.nameRequired,
        AccountField.email: AccountIssue.emailRequired,
        AccountField.password: AccountIssue.passwordRequired,
        AccountField.confirm: AccountIssue.confirmRequired,
      });
    });

    test('lỗi đúng ô: chỉ báo ô sai', () {
      expect(run(name: 'A'), {AccountField.name: AccountIssue.nameLength});
      expect(run(email: 'abc'), {
        AccountField.email: AccountIssue.emailInvalid,
      });
      expect(run(password: '123', confirm: '123'), {
        AccountField.password: AccountIssue.passwordShort,
      });
      expect(run(confirm: 'khac'), {
        AccountField.confirm: AccountIssue.passwordMismatch,
      });
      expect(run(email: 'MoI@Example.com', existing: ['moi@example.com']), {
        AccountField.email: AccountIssue.emailTaken,
      });
    });

    test('mật khẩu quá ngắn và nhập lại khác nhau: báo cả hai ô', () {
      expect(run(password: '123', confirm: '456').keys.toSet(), {
        AccountField.password,
        AccountField.confirm,
      });
    });
  });
}
