import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/core/firestore_repo.dart';
import 'package:giua_ki_app/data/firebase_seed.dart';
import 'package:giua_ki_app/data/models/area.dart';
import 'package:giua_ki_app/data/models/dining_table.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/models/restaurant.dart';
import 'package:giua_ki_app/data/models/user.dart';
import 'package:giua_ki_app/data/repositories/firestore_location_repository.dart';
import 'package:giua_ki_app/data/repositories/firestore_table_repository.dart';
import 'package:giua_ki_app/data/repositories/table_repository.dart';

// Giờ cố định: thứ Hai 05/10/2026 10:00.
final now = DateTime(2026, 10, 5, 10);

Matcher tableError(TableError e) =>
    throwsA(isA<TableException>().having((x) => x.error, 'error', e));

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreTableRepository repo;
  late Set<String> blocked; // người mà u1 đã chặn

  setUp(() async {
    db = FakeFirebaseFirestore();
    blocked = {};
    await seedFirestore(db, now: now);
    repo = FirestoreTableRepository(
      tables: FirestoreRepo(
        firestore: db,
        collection: 'tables',
        fromMap: DiningTable.fromMap,
      ),
      restaurants: FirestoreRepo(
        firestore: db,
        collection: 'restaurants',
        fromMap: Restaurant.fromMap,
      ),
      areas: FirestoreRepo(
        firestore: db,
        collection: 'areas',
        fromMap: Area.fromMap,
      ),
      now: () => now,
      blockedIdsOf: (id) async => id == 'u1' ? blocked : <String>{},
    );
  });

  Future<DiningTable> createAt(
    int h,
    int m, {
    String host = 'u1',
    int cap = 4,
  }) => repo.createTable(
    hostId: host,
    restaurantId: 'q1-1',
    startAt: DateTime(2026, 10, 5, h, m),
    durationMin: 60,
    capacity: cap,
  );

  group('dữ liệu mẫu trên Firestore (seed)', () {
    test('đủ 4 collection: areas, restaurants, users, tables', () async {
      Future<int> count(String c) async => (await db.collection(c).get()).size;
      expect(await count('areas'), 8);
      expect(await count('restaurants'), greaterThanOrEqualTo(30));
      expect(await count('users'), 8);
      expect(await count('tables'), inInclusiveRange(15, 25));
    });

    test('chạy seed lần hai không nhân đôi dữ liệu', () async {
      final before = (await db.collection('tables').get()).size;
      await seedFirestore(db, now: now);
      expect((await db.collection('tables').get()).size, before);
    });

    test('document bàn lưu ngày giờ là Timestamp và enum là chuỗi', () async {
      final doc = (await db.collection('tables').get()).docs.first.data();
      expect(doc['startAt'], isA<Timestamp>());
      expect(doc['status'], isA<String>());
    });
  });

  group('FirestoreLocationRepository', () {
    test('đọc khu vực và quán theo khu vực', () async {
      final loc = FirestoreLocationRepository(
        areas: FirestoreRepo(
          firestore: db,
          collection: 'areas',
          fromMap: Area.fromMap,
        ),
        restaurants: FirestoreRepo(
          firestore: db,
          collection: 'restaurants',
          fromMap: Restaurant.fromMap,
        ),
      );
      expect((await loc.getAreas()).length, 8);
      final q1 = await loc.getRestaurants(areaId: 'hcm-q1');
      expect(q1.length, 10);
      expect(q1.every((r) => r.areaId == 'hcm-q1'), isTrue);
      expect((await loc.getRestaurants()).length, greaterThan(q1.length));
    });
  });

  group('đọc bàn', () {
    test('getMyTables: đúng bàn của người đó, sắp theo giờ', () async {
      final mine = await repo.getMyTables('u1');
      expect(mine.length, 2); // 1 sắp tới + 1 đã kết thúc (dữ liệu mẫu)
      expect(mine.every((t) => t.memberIds.contains('u1')), isTrue);
      expect(mine.first.startAt.isBefore(mine.last.startAt), isTrue);
    });

    test(
      'getTables lọc theo khu vực, bỏ bàn đã bắt đầu/huỷ/kết thúc',
      () async {
        final list = await repo.getTables(
          const TableQuery(areaId: 'hcm-q1', radiusM: 10000, viewerId: 'u1'),
        );
        expect(list, isNotEmpty);
        expect(list.every((t) => t.startAt.isAfter(now)), isTrue);
        expect(list.every((t) => t.status != TableStatus.ended), isTrue);
      },
    );

    test('getTables ẩn bàn của người đã chặn; bỏ chặn thì hiện lại', () async {
      const q = TableQuery(areaId: 'hcm-q1', radiusM: 10000, viewerId: 'u1');
      final all = await repo.getTables(q);
      final someHost = all.firstWhere((t) => t.hostId != 'u1').hostId;
      blocked.add(someHost);
      final hidden = await repo.getTables(q);
      expect(
        hidden.where(
          (t) => t.hostId == someHost && !t.memberIds.contains('u1'),
        ),
        isEmpty,
      );
      blocked.clear();
      expect((await repo.getTables(q)).length, all.length);
    });

    test('getTable: có và không có', () async {
      expect(await repo.getTable('khong-co'), isNull);
      final any = (await repo.getMyTables('u1')).first;
      expect((await repo.getTable(any.id))!.id, any.id);
    });
  });

  group('mở bàn (kiểm tra quy tắc trước khi ghi)', () {
    test(
      'thành công: id mới, chủ bàn là thành viên đầu tiên, ghi lên Firestore',
      () async {
        final t = await createAt(20, 0, host: 'u2');
        expect(t.id, isNotEmpty);
        expect(t.hostId, 'u2');
        expect(t.memberIds, ['u2']);
        expect((await repo.getTable(t.id))!.startAt, DateTime(2026, 10, 5, 20));
      },
    );

    test(
      'giờ quá khứ hoặc sai bước 15 phút: invalidTime, không ghi gì',
      () async {
        final before = (await db.collection('tables').get()).size;
        await expectLater(createAt(9, 0), tableError(TableError.invalidTime));
        await expectLater(createAt(20, 7), tableError(TableError.invalidTime));
        expect((await db.collection('tables').get()).size, before);
      },
    );

    test('thời lượng ngoài 30–120 và số chỗ ngoài 2–8', () async {
      await expectLater(
        repo.createTable(
          hostId: 'u2',
          restaurantId: 'q1-1',
          startAt: DateTime(2026, 10, 5, 20),
          durationMin: 20,
          capacity: 4,
        ),
        tableError(TableError.invalidTime),
      );
      await expectLater(
        createAt(20, 0, host: 'u2', cap: 9),
        tableError(TableError.invalidCapacity),
      );
      await expectLater(
        createAt(20, 0, host: 'u2', cap: 1),
        tableError(TableError.invalidCapacity),
      );
    });

    test('trùng giờ với bàn mình đang ở: overlap', () async {
      final up = (await repo.getMyTables('u1'))
          .firstWhere((t) => t.hostId == 'u1');
      await expectLater(
        repo.createTable(
          hostId: 'u1',
          restaurantId: 'q1-2',
          startAt: up.startAt.add(const Duration(minutes: 15)),
          durationMin: 60,
          capacity: 4,
        ),
        tableError(TableError.overlap),
      );
    });
  });

  group('tham gia / rời / huỷ', () {
    test('tham gia: thêm thành viên, đủ chỗ thì thành "đầy"', () async {
      final t = await createAt(20, 0, host: 'u2', cap: 2);
      final joined = await repo.joinTable(t.id, 'u3');
      expect(joined.memberIds, ['u2', 'u3']);
      expect(joined.status, TableStatus.full);
      expect((await repo.getTable(t.id))!.status, TableStatus.full);
    });

    test('bàn đầy thì full; đã là thành viên thì alreadyMember', () async {
      final t = await createAt(20, 0, host: 'u2', cap: 2);
      await repo.joinTable(t.id, 'u3');
      await expectLater(
        repo.joinTable(t.id, 'u4'),
        tableError(TableError.full),
      );
      await expectLater(
        repo.joinTable(t.id, 'u3'),
        tableError(TableError.alreadyMember),
      );
    });

    test('bàn không tồn tại: notFound', () async {
      await expectLater(
        repo.joinTable('khong-co', 'u3'),
        tableError(TableError.notFound),
      );
      await expectLater(
        repo.leaveTable('khong-co', 'u3'),
        tableError(TableError.notFound),
      );
      await expectLater(
        repo.cancelTable('khong-co', 'u3'),
        tableError(TableError.notFound),
      );
    });

    test('trùng giờ với bàn mình đã ở: overlap, không vào bàn', () async {
      final up = (await repo.getMyTables('u1'))
          .firstWhere((t) => t.hostId == 'u1');
      final clash = await repo.createTable(
        hostId: 'u2',
        restaurantId: 'q1-2',
        startAt: up.startAt,
        durationMin: 60,
        capacity: 4,
      );
      await expectLater(
        repo.joinTable(clash.id, 'u1'),
        tableError(TableError.overlap),
      );
      expect((await repo.getTable(clash.id))!.memberIds, ['u2']);
    });

    test('chủ bàn của bàn mình đã chặn: blockedHost', () async {
      final t = await createAt(20, 0, host: 'u2');
      blocked.add('u2');
      await expectLater(
        repo.joinTable(t.id, 'u1'),
        tableError(TableError.blockedHost),
      );
    });

    test('bàn đã bắt đầu, đã huỷ: không tham gia/rời/huỷ được', () async {
      final past = (await repo.getMyTables('u1'))
          .firstWhere((t) => t.status == TableStatus.ended);
      await expectLater(
        repo.joinTable(past.id, 'u3'),
        tableError(TableError.ended),
      );
      await expectLater(
        repo.leaveTable(past.id, 'u1'),
        tableError(TableError.ended),
      );
      final t = await createAt(20, 0, host: 'u2');
      await repo.cancelTable(t.id, 'u2');
      await expectLater(
        repo.joinTable(t.id, 'u3'),
        tableError(TableError.cancelled),
      );
    });

    test('thành viên thường rời: trả chỗ, bàn mở lại', () async {
      final t = await createAt(20, 0, host: 'u2', cap: 2);
      await repo.joinTable(t.id, 'u3');
      final left = await repo.leaveTable(t.id, 'u3');
      expect(left.memberIds, ['u2']);
      expect(left.status, TableStatus.open);
      expect(left.hostId, 'u2');
    });

    test('chủ bàn rời: chuyển quyền cho người vào sớm nhất', () async {
      final t = await createAt(20, 0, host: 'u2');
      await repo.joinTable(t.id, 'u3');
      await repo.joinTable(t.id, 'u4');
      final left = await repo.leaveTable(t.id, 'u2');
      expect(left.hostId, 'u3');
      expect(left.memberIds, ['u3', 'u4']);
      expect(left.status, TableStatus.open);
    });

    test('chủ bàn rời khi chỉ còn một mình: bàn tự huỷ', () async {
      final t = await createAt(20, 0, host: 'u2');
      final left = await repo.leaveTable(t.id, 'u2');
      expect(left.status, TableStatus.cancelled);
      expect(left.memberIds, isEmpty);
    });

    test('người ngoài bàn rời: notMember', () async {
      final t = await createAt(20, 0, host: 'u2');
      await expectLater(
        repo.leaveTable(t.id, 'u9'),
        tableError(TableError.notMember),
      );
    });

    test('chỉ chủ bàn mới huỷ được', () async {
      final t = await createAt(20, 0, host: 'u2');
      await repo.joinTable(t.id, 'u3');
      await expectLater(
        repo.cancelTable(t.id, 'u3'),
        tableError(TableError.notHost),
      );
      final c = await repo.cancelTable(t.id, 'u2');
      expect(c.status, TableStatus.cancelled);
    });
  });

  test(
    'người dùng mẫu được seed có thể đọc lại qua FirestoreRepo<User>',
    () async {
      final users = FirestoreRepo<User>(
        firestore: db,
        collection: 'users',
        fromMap: User.fromMap,
      );
      expect((await users.find('u1'))!.displayName, 'Minh Anh');
    },
  );
}
