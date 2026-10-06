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
          expect(
            t.startAt.isAfter(now),
            isTrue,
            reason: '${t.id} phải ở tương lai',
          );
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
