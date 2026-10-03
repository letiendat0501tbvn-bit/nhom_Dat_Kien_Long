import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/mock/mock_support.dart';
import 'package:giua_ki_app/data/models/dining_table.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/repositories/mock_table_repository.dart';
import 'package:giua_ki_app/data/repositories/table_repository.dart';

// Giờ cố định: thứ Hai 05/10/2026, 10:00.
final now = DateTime(2026, 10, 5, 10, 0);

DiningTable table(
  String id,
  DateTime start, {
  int duration = 60,
  int capacity = 4,
  List<String> members = const ['host'],
  TableStatus? status,
}) {
  return DiningTable(
    id: id,
    restaurantId: 'r1',
    hostId: members.first,
    startAt: start,
    durationMin: duration,
    capacity: capacity,
    status: status ??
        (members.length >= capacity ? TableStatus.full : TableStatus.open),
    memberIds: members,
  );
}

MockTableRepository repoWith(List<DiningTable> tables) => MockTableRepository(
      tables: tables,
      restaurants: const [],
      areas: const [],
      now: () => now,
      latency: noLatency,
    );

// Mong đợi một TableException với mã lỗi cho trước.
Matcher failsWith(TableError error) => throwsA(
      isA<TableException>().having((e) => e.error, 'error', error),
    );

final at11 = DateTime(2026, 10, 5, 11, 0);
final at12 = DateTime(2026, 10, 5, 12, 0);

void main() {
  group('joinTable', () {
    test('tham gia thành công thì thêm vào cuối danh sách thành viên', () async {
      final repo = repoWith([table('t', at11, members: ['host', 'a'])]);
      final t = await repo.joinTable('t', 'b');
      expect(t.memberIds, ['host', 'a', 'b']);
      expect(t.status, TableStatus.open);
      expect(t.seatsLeft, 1);
    });

    test('chiếm chỗ cuối cùng thì bàn chuyển sang đầy', () async {
      final repo = repoWith([table('t', at11, capacity: 2)]);
      final t = await repo.joinTable('t', 'a');
      expect(t.isFull, isTrue);
      expect(t.status, TableStatus.full);
    });

    test('bàn đã đầy thì báo lỗi full', () async {
      final repo = repoWith([table('t', at11, capacity: 2, members: ['host', 'a'])]);
      await expectLater(repo.joinTable('t', 'b'), failsWith(TableError.full));
    });

    test('bàn đã bắt đầu thì báo lỗi alreadyStarted', () async {
      final repo = repoWith([table('t', DateTime(2026, 10, 5, 9, 30))]);
      await expectLater(
          repo.joinTable('t', 'a'), failsWith(TableError.alreadyStarted));
    });

    test('bàn bắt đầu đúng bằng giờ hiện tại cũng coi là đã bắt đầu', () async {
      final repo = repoWith([table('t', now)]);
      await expectLater(
          repo.joinTable('t', 'a'), failsWith(TableError.alreadyStarted));
    });

    test('bàn đã huỷ thì báo lỗi cancelled', () async {
      final repo = repoWith([table('t', at11, status: TableStatus.cancelled)]);
      await expectLater(repo.joinTable('t', 'a'), failsWith(TableError.cancelled));
    });

    test('bàn đã kết thúc thì báo lỗi ended', () async {
      final repo = repoWith([table('t', at11, status: TableStatus.ended)]);
      await expectLater(repo.joinTable('t', 'a'), failsWith(TableError.ended));
    });

    test('bàn đã huỷ và đã quá giờ: ưu tiên báo đã huỷ', () async {
      final repo = repoWith([
        table('t', DateTime(2026, 10, 5, 9, 0), status: TableStatus.cancelled),
      ]);
      await expectLater(repo.joinTable('t', 'a'), failsWith(TableError.cancelled));
    });

    test('đã là thành viên thì báo lỗi alreadyMember', () async {
      final repo = repoWith([table('t', at11, members: ['host', 'a'])]);
      await expectLater(
          repo.joinTable('t', 'a'), failsWith(TableError.alreadyMember));
    });

    test('bàn không tồn tại thì báo notFound', () async {
      final repo = repoWith([]);
      await expectLater(repo.joinTable('x', 'a'), failsWith(TableError.notFound));
    });

    test('không tham gia hai bàn trùng khung giờ', () async {
      final repo = repoWith([
        table('a', at11, members: ['host1', 'u']), // 11:00–12:00
        table('b', DateTime(2026, 10, 5, 11, 30), members: ['host2']),
      ]);
      await expectLater(repo.joinTable('b', 'u'), failsWith(TableError.overlap));
    });

    test('bàn liền kề (kết thúc 12:00, bắt đầu 12:00) không bị coi là trùng', () async {
      final repo = repoWith([
        table('a', at11, members: ['host1', 'u']),
        table('b', at12, members: ['host2']),
      ]);
      final t = await repo.joinTable('b', 'u');
      expect(t.memberIds, contains('u'));
    });

    test('bàn đã huỷ không tính vào việc trùng giờ', () async {
      final repo = repoWith([
        table('a', at11, members: ['host1', 'u'], status: TableStatus.cancelled),
        table('b', at11, members: ['host2']),
      ]);
      final t = await repo.joinTable('b', 'u');
      expect(t.memberIds, contains('u'));
    });
  });

  group('createTable', () {
    Future<DiningTable> create(
      MockTableRepository repo, {
      DateTime? start,
      int duration = 60,
      int capacity = 4,
    }) {
      return repo.createTable(
        hostId: 'me',
        restaurantId: 'r1',
        startAt: start ?? at12,
        durationMin: duration,
        capacity: capacity,
      );
    }

    test('người mở bàn là chủ bàn và thành viên đầu tiên', () async {
      final repo = repoWith([]);
      final t = await create(repo);
      expect(t.hostId, 'me');
      expect(t.memberIds, ['me']);
      expect(t.status, TableStatus.open);
      expect((await repo.getTable(t.id))?.id, t.id);
    });

    test('số chỗ chỉ từ 2 đến 8', () async {
      final repo = repoWith([]);
      await expectLater(create(repo, capacity: 1), failsWith(TableError.invalidCapacity));
      await expectLater(create(repo, capacity: 9), failsWith(TableError.invalidCapacity));
      expect((await create(repo, capacity: 2)).capacity, 2);
      expect((await create(repo, capacity: 8, start: DateTime(2026, 10, 5, 15, 0))).capacity, 8);
    });

    test('giờ ở quá khứ hoặc sai bước 15 phút bị từ chối', () async {
      final repo = repoWith([]);
      await expectLater(
          create(repo, start: DateTime(2026, 10, 5, 9, 0)), failsWith(TableError.invalidTime));
      await expectLater(
          create(repo, start: DateTime(2026, 10, 5, 12, 5)), failsWith(TableError.invalidTime));
      await expectLater(create(repo, duration: 20), failsWith(TableError.invalidTime));
    });

    test('không mở bàn trùng giờ với bàn mình đang tham gia', () async {
      final repo = repoWith([table('a', at12, members: ['x', 'me'])]);
      await expectLater(
          create(repo, start: DateTime(2026, 10, 5, 12, 30)), failsWith(TableError.overlap));
    });
  });

  group('leaveTable', () {
    test('thành viên thường rời bàn: trả lại chỗ, bàn đầy chuyển thành mở', () async {
      final repo = repoWith([table('t', at11, capacity: 3, members: ['host', 'a', 'b'])]);
      final t = await repo.leaveTable('t', 'a');
      expect(t.memberIds, ['host', 'b']);
      expect(t.hostId, 'host');
      expect(t.status, TableStatus.open);
    });

    test('chủ bàn rời: chuyển quyền cho người vào bàn sớm nhất còn lại', () async {
      final repo = repoWith([table('t', at11, members: ['host', 'a', 'b'])]);
      final t = await repo.leaveTable('t', 'host');
      expect(t.hostId, 'a');
      expect(t.memberIds, ['a', 'b']);
      expect(t.status, TableStatus.open);
    });

    test('chủ bàn rời mà chỉ còn một mình: bàn tự huỷ', () async {
      final repo = repoWith([table('t', at11)]);
      final t = await repo.leaveTable('t', 'host');
      expect(t.status, TableStatus.cancelled);
      expect(t.memberIds, isEmpty);
    });

    test('người ngoài bàn không rời được', () async {
      final repo = repoWith([table('t', at11)]);
      await expectLater(repo.leaveTable('t', 'x'), failsWith(TableError.notMember));
    });

    test('bàn đã bắt đầu thì không rời được', () async {
      final repo = repoWith([table('t', DateTime(2026, 10, 5, 9, 30), members: ['host', 'a'])]);
      await expectLater(
          repo.leaveTable('t', 'a'), failsWith(TableError.alreadyStarted));
    });

    test('bàn đã huỷ hoặc đã kết thúc thì không rời được, báo đúng lý do', () async {
      final repo = repoWith([
        table('c', at11, members: ['host', 'a'], status: TableStatus.cancelled),
        table('e', at11, members: ['host', 'a'], status: TableStatus.ended),
      ]);
      await expectLater(repo.leaveTable('c', 'a'), failsWith(TableError.cancelled));
      await expectLater(repo.leaveTable('e', 'a'), failsWith(TableError.ended));
    });

    test('sau khi người rời, người khác có thể tham gia lại chỗ đó', () async {
      final repo = repoWith([table('t', at11, capacity: 2, members: ['host', 'a'])]);
      await repo.leaveTable('t', 'a');
      final t = await repo.joinTable('t', 'b');
      expect(t.memberIds, ['host', 'b']);
      expect(t.isFull, isTrue);
    });
  });

  group('cancelTable', () {
    test('chỉ chủ bàn được huỷ', () async {
      final repo = repoWith([table('t', at11, members: ['host', 'a'])]);
      await expectLater(repo.cancelTable('t', 'a'), failsWith(TableError.notHost));
      final t = await repo.cancelTable('t', 'host');
      expect(t.status, TableStatus.cancelled);
    });
  });

  group('getMyTables', () {
    test('trả về bàn đã mở hoặc đã tham gia, xếp theo giờ', () async {
      final repo = repoWith([
        table('late', at12, members: ['host', 'me']),
        table('other', at11, members: ['host']),
        table('early', at11, members: ['me']),
      ]);
      final mine = await repo.getMyTables('me');
      expect(mine.map((t) => t.id), ['early', 'late']);
    });
  });

  group('getTables', () {
    test('trả về bàn theo bộ lọc và dùng đồng hồ truyền vào', () async {
      final repo = repoWith([
        table('past', DateTime(2026, 10, 5, 9, 30)),
        table('future', at11),
      ]);
      final list = await repo.getTables(const TableQuery());
      expect(list.map((t) => t.id), ['future']);
    });
  });
}
