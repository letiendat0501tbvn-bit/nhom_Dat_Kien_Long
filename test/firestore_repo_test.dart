import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/core/firestore_repo.dart';
import 'package:giua_ki_app/data/models/dining_table.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/models/user.dart';

final _at = DateTime(2026, 10, 5, 11);

DiningTable table(String id, {List<String>? members, String host = 'u1'}) =>
    DiningTable(
      id: id,
      restaurantId: 'q1-1',
      hostId: host,
      startAt: _at,
      durationMin: 60,
      capacity: 4,
      memberIds: members ?? [host],
    );

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreRepo<DiningTable> tables;
  late FirestoreRepo<User> users;

  setUp(() {
    db = FakeFirebaseFirestore();
    tables = FirestoreRepo(
      firestore: db,
      collection: 'tables',
      fromMap: DiningTable.fromMap,
    );
    users = FirestoreRepo(
      firestore: db,
      collection: 'users',
      fromMap: User.fromMap,
    );
  });

  group('FirestoreRepo<E>', () {
    test(
      'set rồi find: ghi đúng collection, ngày giờ lưu là Timestamp',
      () async {
        await tables.set(table('t1', members: ['u1', 'u2']));
        final raw = (await db.collection('tables').doc('t1').get()).data()!;
        expect(
          raw['startAt'],
          isA<Timestamp>(),
        ); // trong Firestore là Timestamp
        expect(raw['status'], 'open'); // enum lưu bằng tên
        expect(raw.containsKey('id'), isFalse); // id là id của document

        final back = await tables.find('t1');
        expect(back, isNotNull);
        expect(back!.startAt, _at); // đọc lại là DateTime
        expect(back.memberIds, ['u1', 'u2']);
        expect(back.status, TableStatus.open);
      },
    );

    test('find id không có thì trả về null', () async {
      expect(await tables.find('khong-co'), isNull);
    });

    test('kind trả về Type của phần tử và tên collection được lưu', () {
      expect(tables.kind, DiningTable);
      expect(users.kind, User);
      expect(tables.collection, 'tables');
    });

    test('set ghi đè document cùng id', () async {
      await tables.set(table('t1'));
      await tables.set(table('t1', members: ['u1', 'u2', 'u3']));
      expect((await tables.find('t1'))!.memberIds.length, 3);
      expect((await tables.all()).length, 1);
    });

    test('add: tạo mới; trùng id thì ném StateError và không ghi đè', () async {
      await tables.add(table('t1'));
      await expectLater(
        tables.add(table('t1', members: ['u1', 'u9'])),
        throwsStateError,
      );
      expect((await tables.find('t1'))!.memberIds, ['u1']);
    });

    test('all liệt kê hết; các collection độc lập nhau', () async {
      await tables.set(table('t1'));
      await tables.set(table('t2'));
      await users.set(
        const User(id: 'u1', displayName: 'Minh Anh', email: 'a@b.co'),
      );
      expect((await tables.all()).map((t) => t.id).toSet(), {'t1', 't2'});
      expect((await users.all()).length, 1);
    });

    test('where: theo giá trị và theo mảng chứa giá trị', () async {
      await tables.set(table('t1', host: 'u1'));
      await tables.set(table('t2', host: 'u2', members: ['u2', 'u1']));
      await tables.set(table('t3', host: 'u3'));
      expect((await tables.where('hostId', isEqualTo: 'u2')).map((t) => t.id), [
        't2',
      ]);
      final mine = await tables.where('memberIds', arrayContains: 'u1');
      expect(mine.map((t) => t.id).toSet(), {'t1', 't2'});
      expect((await tables.where('hostId', isEqualTo: 'khong-co')), isEmpty);
    });

    test('where theo DateTime: tự đổi sang Timestamp', () async {
      await tables.set(table('t1'));
      expect((await tables.where('startAt', isEqualTo: _at)).length, 1);
      expect(
        (await tables.where(
          'startAt',
          isEqualTo: _at.add(const Duration(hours: 1)),
        )),
        isEmpty,
      );
    });

    test('delete xoá document; xoá id không có thì không lỗi', () async {
      await tables.set(table('t1'));
      await tables.delete('t1');
      expect(await tables.find('t1'), isNull);
      await tables.delete('khong-co');
    });

    test(
      'update: đọc-sửa-ghi và trả về bản mới; id không có thì StateError',
      () async {
        await tables.set(table('t1'));
        final updated = await tables.update(
          't1',
          (t) => t.copyWith(memberIds: [...t.memberIds, 'u2']),
        );
        expect(updated.memberIds, ['u1', 'u2']);
        expect((await tables.find('t1'))!.memberIds, ['u1', 'u2']);
        await expectLater(
          tables.update('khong-co', (t) => t),
          throwsStateError,
        );
      },
    );

    test('watch: phát lại danh sách mỗi khi dữ liệu đổi', () async {
      final seen = <int>[];
      final sub = tables.watch().listen((l) => seen.add(l.length));
      await Future<void>.delayed(Duration.zero);
      await tables.set(table('t1'));
      await Future<void>.delayed(Duration.zero);
      await tables.set(table('t2'));
      await Future<void>.delayed(Duration.zero);
      await tables.delete('t1');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(seen.last, 1);
      expect(seen, containsAllInOrder([0, 1, 2, 1]));
    });

    test('watch có lọc chỉ thấy phần khớp', () async {
      await tables.set(table('t1', host: 'u1'));
      await tables.set(table('t2', host: 'u2'));
      final first = await tables.watch(field: 'hostId', isEqualTo: 'u2').first;
      expect(first.map((t) => t.id), ['t2']);
    });
  });
}
