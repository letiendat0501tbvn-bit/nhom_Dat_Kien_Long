import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/logic/table_rules.dart';
import 'package:giua_ki_app/data/mock/mock_data.dart';
import 'package:giua_ki_app/data/mock/mock_support.dart';
import 'package:giua_ki_app/data/mock_dishes.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/repositories/mock_table_repository.dart';
import 'package:giua_ki_app/data/repositories/table_repository.dart';

void main() {
  group('món mẫu', () {
    test('đủ 56 món, id không trùng', () {
      expect(kMockDishes.length, 56);
      expect(kMockDishes.map((d) => d.id).toSet().length, 56);
    });

    test('9 món đã biết giữ nguyên mô tả của web', () {
      String desc(String id) =>
          kMockDishes.firstWhere((d) => d.id == id).description;
      expect(desc('pho'), 'Nước dùng thơm, bánh phở mềm, một tô thật ấm bụng.');
      expect(desc('banh-mi-chao'), 'Bánh mì nóng, trứng ốp la và sốt đậm đà.');
      expect(
        desc('bun-bo-hue'),
        'Sả thơm, vị cay nồng, nước dùng đậm chất Huế.',
      );
      expect(desc('banh-xeo'), 'Vỏ bánh giòn rụm, cuốn rau xanh chấm mắm.');
      expect(desc('com-tam'), 'Cơm tấm, sườn nướng và chút mỡ hành thơm.');
      expect(
        desc('mi-quang'),
        'Sợi mì nghệ, nước nhưn đậm, bánh tráng mè giòn.',
      );
      expect(desc('lau'), 'Nồi lẩu nóng, cùng nhúng món và kể chuyện.');
      expect(desc('oc'), 'Một đĩa ốc, ly trà đá, chuyện trò cả buổi.');
      expect(
        desc('bun-cha'),
        'Thịt nướng thơm lừng, bún tươi và bát nước chấm — một nét quen của Hà Nội.',
      );
    });

    test('mỗi món có danh mục hợp lệ, nhóm và ít nhất một buổi ăn', () {
      const categories = {
        'Bún & mì',
        'Bánh mặn',
        'Cuốn & bánh',
        'Cơm & xôi',
        'Món lẩu',
        'Ăn vặt',
        'Đồ uống',
      };
      for (final d in kMockDishes) {
        expect(categories, contains(d.category), reason: d.id);
        expect(d.group, isNotEmpty, reason: d.id);
        expect(d.mealTimes, isNotEmpty, reason: d.id);
        expect(d.description, isNotEmpty, reason: d.id);
      }
    });

    test('4 món "ba miền" có vùng và hashtag', () {
      final regional = kMockDishes.where((d) => d.region != null).toList();
      expect(regional.map((d) => d.id).toSet(), {
        'bun-cha',
        'mi-quang',
        'oc',
        'banh-xeo',
      });
      expect(regional.every((d) => d.hashtag != null), isTrue);
    });

    test('MockDishRepository lọc theo tên, danh mục, buổi ăn', () async {
      final repo = MockDishRepository(latency: noLatency);
      expect(
        (await repo.getDishes(query: 'LẨU')).map((d) => d.id),
        containsAll(['lau', 'lau-thai']),
      );
      expect((await repo.getDishes(category: 'Món lẩu')).length, 5);
      final morning = await repo.getDishes(mealTime: MealTime.morning);
      expect(
        morning.every((d) => d.mealTimes.contains(MealTime.morning)),
        isTrue,
      );
      expect(await repo.getDishes(query: 'không có món này'), isEmpty);
      expect((await repo.getDish('pho'))?.name, 'Phở');
      expect(await repo.getDish('xyz'), isNull);
      expect((await repo.getCategories()).length, 7);
    });
  });

  group('dữ liệu mẫu theo giờ hiện tại', () {
    // Thử với nhiều "bây giờ" khác nhau để chắc dữ liệu luôn nằm ở tương lai.
    final nows = [
      DateTime(2026, 10, 5, 10, 0),
      DateTime(2026, 10, 5, 10, 7, 33),
      DateTime(2026, 12, 31, 14, 45),
    ];

    test('khu vực và quán đủ số lượng', () {
      expect(mockAreas.length, 8);
      int count(String prefix) =>
          mockRestaurants.where((r) => r.id.startsWith('$prefix-')).length;
      expect(count('q1'), greaterThanOrEqualTo(10));
      expect(count('hk'), greaterThanOrEqualTo(10));
      for (final p in ['bt', 'td', 'hc', 'ph', 'ma', 'nk']) {
        expect(count(p), greaterThanOrEqualTo(2), reason: p);
      }
      expect(
        mockRestaurants.map((r) => r.id).toSet().length,
        mockRestaurants.length,
      );
      final areaIds = mockAreas.map((a) => a.id).toSet();
      expect(mockRestaurants.every((r) => areaIds.contains(r.areaId)), isTrue);
      expect(mockUsers.length, 8);
    });

    for (final now in nows) {
      test('bàn mẫu hợp lệ khi bây giờ là $now', () {
        final data = MockData.build(now);
        final dishIds = kMockDishes.map((d) => d.id).toSet();
        final restaurantIds = mockRestaurants.map((r) => r.id).toSet();
        final userIds = mockUsers.map((u) => u.id).toSet();

        expect(data.tables.length, inInclusiveRange(15, 25));
        for (final t in data.tables) {
          // Mọi bàn ở tương lai, trừ bàn "Đã qua" đã kết thúc của Minh Anh
          if (t.status != TableStatus.ended) {
            expect(
              t.startAt.isAfter(now),
              isTrue,
              reason: '${t.id} phải ở tương lai',
            );
          }
          expect(t.startAt.minute % 15, 0, reason: t.id);
          expect(dishIds, contains(t.dishId), reason: t.id);
          expect(restaurantIds, contains(t.restaurantId), reason: t.id);
          expect(
            t.capacity,
            inInclusiveRange(minCapacity, maxCapacity),
            reason: t.id,
          );
          expect(
            t.memberIds.length,
            lessThanOrEqualTo(t.capacity),
            reason: t.id,
          );
          expect(t.memberIds.first, t.hostId, reason: t.id);
          expect(userIds.containsAll(t.memberIds), isTrue, reason: t.id);
          expect(t.memberIds.toSet().length, t.memberIds.length, reason: t.id);
          expect(t.status == TableStatus.full, t.isFull, reason: t.id);
        }
        expect(data.tables.map((t) => t.id).toSet().length, data.tables.length);
      });
    }

    test(
      'có bàn đầy, bàn còn 1 chỗ, bàn sắp đến giờ, bàn hôm nay và ngày mai',
      () {
        final now = DateTime(2026, 10, 5, 10, 0);
        final tables = MockData.build(now).tables;

        expect(tables.any((t) => t.isFull), isTrue);
        expect(tables.any((t) => t.seatsLeft == 1), isTrue);
        expect(
          tables.any(
            (t) => t.startAt.difference(now) <= const Duration(minutes: 30),
          ),
          isTrue,
        );
        final tomorrow = DateTime(2026, 10, 6);
        bool sameDay(DateTime a, DateTime b) =>
            a.year == b.year && a.month == b.month && a.day == b.day;
        expect(tables.any((t) => sameDay(t.startAt, now)), isTrue);
        expect(tables.any((t) => sameDay(t.startAt, tomorrow)), isTrue);
      },
    );

    // Nhiều mốc "bây giờ" trong ngày: sáng sớm, trưa, tối, 23:30, nửa đêm...
    final dayNows = [
      for (var h = 0; h < 24; h++)
        for (final m in [0, 7, 30, 52]) DateTime(2026, 10, 5, h, m),
      DateTime(2026, 10, 5, 23, 30),
      DateTime(2026, 12, 31, 23, 59),
      DateTime(2027, 1, 1, 0, 1),
    ];

    group('Minh Anh (u1) và người dùng mẫu khác', () {
      test(
        'u1 luôn ở đúng 2 bàn: 1 sắp tới (chủ bàn, còn chỗ) và 1 đã kết thúc',
        () {
          for (final now in dayNows) {
            final tables = MockData.build(now).tables;
            final mine = tables
                .where((t) => t.memberIds.contains('u1'))
                .toList();
            expect(mine.length, 2, reason: '$now');
            final split = splitMyTables(mine, now);
            expect(split.upcoming.length, 1, reason: '$now');
            expect(split.past.length, 1, reason: '$now');

            final up = split.upcoming.single;
            expect(up.hostId, 'u1', reason: '$now');
            expect(up.seatsLeft, greaterThanOrEqualTo(1), reason: '$now');
            expect(
              up.memberIds.length,
              greaterThanOrEqualTo(3),
              reason: '$now',
            );
            // Bắt đầu trong khoảng 1–3 giờ tới
            final inMin = up.startAt.difference(now).inMinutes;
            expect(inMin, inInclusiveRange(60, 180), reason: '$now');

            final past = split.past.single;
            expect(past.status, TableStatus.ended, reason: '$now');
            expect(
              displayStatusOf(past, now),
              TableDisplayStatus.ended,
              reason: '$now',
            );
            expect(past.hostId, isNot('u1'), reason: '$now');
            expect(past.durationMin, 60, reason: '$now');
            // Bắt đầu cách đây khoảng 3 giờ và đã kết thúc
            final agoMin = now.difference(past.startAt).inMinutes;
            expect(agoMin, inInclusiveRange(165, 195), reason: '$now');
            expect(past.endAt.isBefore(now), isTrue, reason: '$now');

            // Hai bàn không trùng giờ nhau
            expect(tablesOverlap(up, past), isFalse, reason: '$now');
          }
        },
      );

      test('chỉ MỘT bàn mở, còn chỗ ở Quận 1 trùng giờ với bàn sắp tới của u1 (bàn demo)', () {
        for (final now in dayNows) {
          final tables = MockData.build(now).tables;
          final up = tables.firstWhere((t) => t.hostId == 'u1' && isActive(t));
          final clashing = [
            for (final t in tables)
              if (!t.memberIds.contains('u1') &&
                  isActive(t) &&
                  tablesOverlap(t, up))
                t,
          ];
          expect(clashing.length, 1, reason: '$now');
          final demo = clashing.single;
          expect(demo.restaurantId, startsWith('q1-'), reason: '$now');
          expect(demo.isFull, isFalse, reason: '$now');
          expect(demo.status, TableStatus.open, reason: '$now');
        }
      });

      test('mọi bàn khác không trùng giờ với bàn nào của u1 (tham gia sẽ thành công)', () {
        for (final now in dayNows) {
          final tables = MockData.build(now).tables;
          final mine = tables.where((t) => t.memberIds.contains('u1')).toList();
          final up = splitMyTables(mine, now).upcoming.single;
          final demoIds = {
            for (final t in tables)
              if (!t.memberIds.contains('u1') && tablesOverlap(t, up)) t.id,
          };
          for (final t in tables) {
            if (t.memberIds.contains('u1') || demoIds.contains(t.id)) continue;
            for (final m in mine) {
              expect(
                tablesOverlap(t, m),
                isFalse,
                reason: '$now ${t.id} / ${m.id}',
              );
            }
          }
          // Có bàn mở còn chỗ ở Quận 1 để tham gia ngoài bàn demo
          final joinable = tables.where(
            (t) =>
                t.restaurantId.startsWith('q1-') &&
                isActive(t) &&
                !t.isFull &&
                !t.memberIds.contains('u1') &&
                !demoIds.contains(t.id),
          );
          expect(joinable, isNotEmpty, reason: '$now');
        }
      });

      test('u2–u8: mỗi người ở 3–5 bàn, không ai bị trùng giờ giữa các bàn của mình', () {
        for (final now in dayNows) {
          final tables = MockData.build(now).tables;
          for (final u in mockUsers.where((u) => u.id != 'u1')) {
            final mine = tables
                .where((t) => t.memberIds.contains(u.id))
                .toList();
            expect(
              mine.length,
              inInclusiveRange(3, 5),
              reason: '$now ${u.id} ở ${mine.length} bàn',
            );
            for (var i = 0; i < mine.length; i++) {
              for (var j = i + 1; j < mine.length; j++) {
                expect(
                  tablesOverlap(mine[i], mine[j]),
                  isFalse,
                  reason: '$now ${u.id}: ${mine[i].id} / ${mine[j].id}',
                );
              }
            }
          }
        }
      });

      test('ràng buộc chung ở mọi mốc giờ: 15–25 bàn, số chỗ 2–8, chủ bàn là thành viên, không trùng lặp', () {
        for (final now in dayNows) {
          final tables = MockData.build(now).tables;
          expect(tables.length, inInclusiveRange(15, 25), reason: '$now');
          for (final t in tables) {
            expect(t.capacity, inInclusiveRange(minCapacity, maxCapacity));
            expect(t.memberIds.length, lessThanOrEqualTo(t.capacity));
            expect(t.memberIds.first, t.hostId);
            expect(t.memberIds.toSet().length, t.memberIds.length);
            // Chủ bàn của bàn thường là người từ nhóm u2–u8
            if (!t.memberIds.contains('u1')) expect(t.hostId, isNot('u1'));
          }
          expect(tables.map((t) => t.id).toSet().length, tables.length);
        }
      });

      test('vẫn đa dạng: bàn đầy, còn 1 chỗ, sắp đến giờ, hôm nay, ngày mai, nhiều bàn Quận 1 và Hoàn Kiếm', () {
        final now = DateTime(2026, 10, 5, 10, 0);
        final tables = MockData.build(now).tables
            .where((t) => t.status != TableStatus.ended)
            .toList();
        expect(tables.any((t) => t.isFull), isTrue);
        expect(tables.any((t) => t.seatsLeft == 1), isTrue);
        expect(
          tables.any(
            (t) => t.startAt.difference(now) <= const Duration(minutes: 30),
          ),
          isTrue,
        );
        expect(tables.any((t) => t.startAt.day == 5), isTrue);
        expect(tables.any((t) => t.startAt.day == 6), isTrue);
        expect(
          tables.where((t) => t.restaurantId.startsWith('q1-')).length,
          greaterThanOrEqualTo(7),
        );
        expect(
          tables.where((t) => t.restaurantId.startsWith('hk-')).length,
          greaterThanOrEqualTo(4),
        );
      });

      test('qua repository: getMyTables ra đúng 2 bàn; bàn demo báo trùng giờ, bàn khác tham gia được', () async {
        final now = DateTime(2026, 10, 5, 10, 0);
        final data = MockData.build(now);
        final repo = MockTableRepository(
          tables: data.tables,
          restaurants: data.restaurants,
          areas: data.areas,
          now: () => now,
          latency: noLatency,
        );
        final mine = await repo.getMyTables('u1');
        expect(mine.length, 2);
        final up = mine.firstWhere((t) => t.hostId == 'u1');
        final clash = data.tables.firstWhere(
          (t) =>
              !t.memberIds.contains('u1') &&
              isActive(t) &&
              tablesOverlap(t, up),
        );
        await expectLater(
          repo.joinTable(clash.id, 'u1'),
          throwsA(
            isA<TableException>().having(
              (e) => e.error,
              'error',
              TableError.overlap,
            ),
          ),
        );
        final ok = data.tables.firstWhere(
          (t) =>
              t.restaurantId.startsWith('q1-') &&
              isActive(t) &&
              !t.isFull &&
              !t.memberIds.contains('u1') &&
              !tablesOverlap(t, up) &&
              t.id != clash.id,
        );
        final joined = await repo.joinTable(ok.id, 'u1');
        expect(joined.memberIds, contains('u1'));
      });
    });

    test('tin nhắn mẫu thuộc về bàn có thật và do thành viên bàn gửi', () {
      final data = MockData.build(DateTime(2026, 10, 5, 10, 0));
      expect(data.messages, isNotEmpty);
      for (final m in data.messages) {
        final t = data.tables.firstWhere((t) => t.id == m.tableId);
        expect(t.memberIds, contains(m.senderId), reason: m.id);
      }
    });

    test('lọc bàn trên dữ liệu mẫu theo khu vực Quận 1', () async {
      final now = DateTime(2026, 10, 5, 10, 0);
      final data = MockData.build(now);
      final repo = MockTableRepository(
        tables: data.tables,
        restaurants: data.restaurants,
        areas: data.areas,
        now: () => now,
        latency: noLatency,
      );
      final list = await repo.getTables(
        const TableQuery(areaId: 'hcm-q1', radiusM: 10000),
      );
      expect(list, isNotEmpty);
      final byId = {for (final r in data.restaurants) r.id: r};
      expect(
        list.every((t) => byId[t.restaurantId]!.areaId == 'hcm-q1'),
        isTrue,
      );

      // Bán kính nhỏ cho ít bàn hơn hoặc bằng bán kính lớn
      final near = await repo.getTables(
        const TableQuery(areaId: 'hcm-q1', radiusM: 500),
      );
      expect(near.length, lessThan(list.length));
    });
  });
}
