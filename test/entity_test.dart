import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/core/entity.dart';

class _A extends Entity<String> {
  const _A(super.id, this.name);

  final String name;

  @override
  String get label => name;
}

class _B extends Entity<String> {
  const _B(super.id);

  @override
  String get label => 'b';
}

class _N extends Entity<int> {
  const _N(super.id);

  @override
  String get label => 'n$id';
}

void main() {
  group('Entity', () {
    test('cùng lớp và cùng id thì bằng nhau, dù trường khác nhau', () {
      expect(const _A('1', 'x'), const _A('1', 'y'));
      expect(const _A('1', 'x') == const _A('2', 'x'), isFalse);
    });

    test('khác lớp thì không bằng nhau dù cùng id', () {
      expect(const _A('1', 'x') == const _B('1'), isFalse);
      expect(const _B('1') == const _A('1', 'x'), isFalse);
    });

    test('hashCode nhất quán với ==', () {
      expect(const _A('1', 'x').hashCode, const _A('1', 'y').hashCode);
      expect(const _A('1', 'x').hashCode, isNot(const _B('1').hashCode));
      expect({const _A('1', 'x'), const _A('1', 'z'), const _B('1')}.length, 2);
    });

    test('dùng được làm khoá Map và với ID kiểu khác', () {
      final m = {const _N(7): 'a'};
      expect(m[const _N(7)], 'a');
      expect(m[const _N(8)], isNull);
    });

    test('so sánh với đối tượng không phải Entity', () {
      expect(const _A('1', 'x') == Object(), isFalse);
      // ignore: unrelated_type_equality_checks
      expect(const _A('1', 'x') == '1', isFalse);
    });

    test('toString ghi runtimeType, id và label', () {
      expect(const _A('1', 'Phở').toString(), '_A(id: 1, label: Phở)');
      expect(const _N(5).toString(), '_N(id: 5, label: n5)');
    });
  });
}
