import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/logic/table_rules.dart';
import 'package:giua_ki_app/data/models/area.dart';
import 'package:giua_ki_app/data/models/dining_table.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/models/restaurant.dart';
import 'package:giua_ki_app/data/repositories/table_repository.dart';

// Giờ cố định để test không phụ thuộc đồng hồ máy: thứ Hai 05/10/2026, 10:00.
final now = DateTime(2026, 10, 5, 10, 0);

DiningTable table(
  String id,
  DateTime start, {
  String restaurantId = 'r-near',
  String? dishId,
  int duration = 60,
  int capacity = 4,
  List<String> members = const ['host'],
  TableStatus status = TableStatus.open,
}) {
  return DiningTable(
    id: id,
    dishId: dishId,
    restaurantId: restaurantId,
    hostId: members.first,
    startAt: start,
    durationMin: duration,
    capacity: capacity,
    status: status,
    memberIds: members,
  );
}

void main() {
  group('mealTimeOfHour', () {
    test('biên các buổi ăn theo mục 7 SPEC', () {
      expect(mealTimeOfHour(4), MealTime.lateNight);
      expect(mealTimeOfHour(5), MealTime.morning);
      expect(mealTimeOfHour(10), MealTime.morning);
      expect(mealTimeOfHour(11), MealTime.noon);
      expect(mealTimeOfHour(13), MealTime.noon);
      expect(mealTimeOfHour(14), MealTime.afternoon);
      expect(mealTimeOfHour(16), MealTime.afternoon);
      expect(mealTimeOfHour(17), MealTime.evening);
      expect(mealTimeOfHour(21), MealTime.evening);
      expect(mealTimeOfHour(22), MealTime.lateNight);
      expect(mealTimeOfHour(0), MealTime.lateNight);
    });
  });

  group('distanceMeters', () {
    test('0.001 độ vĩ tuyến xấp xỉ 111 m', () {
      final d = distanceMeters(10.0, 106.0, 10.001, 106.0);
      expect(d, inInclusiveRange(105, 118));
    });

    test('cùng một điểm thì bằng 0', () {
      expect(distanceMeters(21.0, 105.8, 21.0, 105.8), 0);
    });
  });

  group('tablesOverlap', () {
    final a = table('a', DateTime(2026, 10, 5, 11, 0)); // 11:00–12:00

    test('chồng giờ một phần thì trùng', () {
      expect(
        tablesOverlap(a, table('b', DateTime(2026, 10, 5, 11, 30))),
        isTrue,
      );
    });

    test('chạm đầu mút (12:00) thì không trùng', () {
      expect(
        tablesOverlap(a, table('b', DateTime(2026, 10, 5, 12, 0))),
        isFalse,
      );
    });

    test('khác ngày thì không trùng', () {
      expect(
        tablesOverlap(a, table('b', DateTime(2026, 10, 6, 11, 0))),
        isFalse,
      );
    });
  });

  group('validateNewTable', () {
    TableError? check({DateTime? start, int duration = 60, int capacity = 4}) {
      return validateNewTable(
        now: now,
        startAt: start ?? DateTime(2026, 10, 5, 12, 0),
        durationMin: duration,
        capacity: capacity,
      );
    }

    test('thông tin hợp lệ', () {
      expect(check(), isNull);
    });

    test('giờ bắt đầu phải ở tương lai', () {
      expect(
        check(start: DateTime(2026, 10, 5, 9, 45)),
        TableError.invalidTime,
      );
      expect(check(start: now), TableError.invalidTime); // đúng bằng bây giờ
    });

    test('phải theo bước 15 phút', () {
      expect(
        check(start: DateTime(2026, 10, 5, 12, 10)),
        TableError.invalidTime,
      );
      expect(check(start: DateTime(2026, 10, 5, 12, 45)), isNull);
    });

    test('thời lượng 30–120 phút, bội của 15', () {
      expect(check(duration: 15), TableError.invalidTime);
      expect(check(duration: 135), TableError.invalidTime);
      expect(check(duration: 40), TableError.invalidTime);
      expect(check(duration: 30), isNull);
      expect(check(duration: 120), isNull);
    });

    test('số chỗ từ 2 đến 8', () {
      expect(check(capacity: 1), TableError.invalidCapacity);
      expect(check(capacity: 9), TableError.invalidCapacity);
      expect(check(capacity: 2), isNull);
      expect(check(capacity: 8), isNull);
    });
  });

  group('hasOverlap', () {
    test('chỉ tính bàn còn hiệu lực mà người đó đang tham gia', () {
      final mine = table(
        'mine',
        DateTime(2026, 10, 5, 11, 0),
        members: ['host', 'u'],
      );
      final cancelled = table(
        'c',
        DateTime(2026, 10, 5, 11, 0),
        members: ['host', 'u'],
        status: TableStatus.cancelled,
      );
      final target = table('target', DateTime(2026, 10, 5, 11, 30));

      expect(hasOverlap([mine], 'u', target), isTrue);
      expect(hasOverlap([cancelled], 'u', target), isFalse);
      expect(
        hasOverlap([mine], 'other', target),
        isFalse,
      ); // người khác không bị tính
      expect(
        hasOverlap([target], 'host', target),
        isFalse,
      ); // không tự trùng chính nó
    });
  });

  group('filterTables', () {
    // Tâm khu vực A, ba quán cách tâm khoảng 50 m, 450 m, 5 km; một quán ở khu vực B.
    const areas = {
      'A': Area(id: 'A', city: 'X', district: 'A', lat: 10.0, lng: 106.0),
      'B': Area(id: 'B', city: 'X', district: 'B', lat: 11.0, lng: 107.0),
    };
    const restaurants = {
      'r-near': Restaurant(
        id: 'r-near',
        name: 'n',
        address: '',
        areaId: 'A',
        lat: 10.00045,
        lng: 106.0,
      ),
      'r-mid': Restaurant(
        id: 'r-mid',
        name: 'm',
        address: '',
        areaId: 'A',
        lat: 10.004,
        lng: 106.0,
      ),
      'r-far': Restaurant(
        id: 'r-far',
        name: 'f',
        address: '',
        areaId: 'A',
        lat: 10.045,
        lng: 106.0,
      ),
      'r-b': Restaurant(
        id: 'r-b',
        name: 'b',
        address: '',
        areaId: 'B',
        lat: 11.0,
        lng: 107.0,
      ),
    };

    final near = table(
      'near',
      DateTime(2026, 10, 5, 11, 30),
      dishId: 'pho',
    ); // trưa
    final mid = table(
      'mid',
      DateTime(2026, 10, 5, 18, 0),
      restaurantId: 'r-mid',
      dishId: 'lau',
    ); // tối
    final far = table(
      'far',
      DateTime(2026, 10, 6, 8, 0),
      restaurantId: 'r-far',
      dishId: 'pho',
    ); // sáng mai
    final other = table(
      'other',
      DateTime(2026, 10, 5, 12, 0),
      restaurantId: 'r-b',
    );
    final started = table(
      'started',
      DateTime(2026, 10, 5, 9, 30),
    ); // đã bắt đầu
    final cancelled = table(
      'cancelled',
      DateTime(2026, 10, 5, 13, 0),
      status: TableStatus.cancelled,
    );
    final full = table(
      'full',
      DateTime(2026, 10, 5, 12, 30),
      capacity: 2,
      members: ['a', 'b'],
      status: TableStatus.full,
    );
    final all = [far, mid, near, other, started, cancelled, full];

    List<String> ids(TableQuery q) => filterTables(
      tables: all,
      query: q,
      restaurants: restaurants,
      areas: areas,
      now: now,
    ).map((t) => t.id).toList();

    test(
      'không lọc: bỏ bàn đã bắt đầu và đã huỷ, giữ bàn đầy, xếp theo giờ',
      () {
        expect(ids(const TableQuery()), [
          'near',
          'other',
          'full',
          'mid',
          'far',
        ]);
      },
    );

    test('lọc theo khu vực', () {
      expect(ids(const TableQuery(areaId: 'B', radiusM: 10000)), ['other']);
    });

    test('lọc theo bán kính tới tâm khu vực', () {
      expect(ids(const TableQuery(areaId: 'A', radiusM: 100)), [
        'near',
        'full',
      ]);
      expect(ids(const TableQuery(areaId: 'A', radiusM: 500)), [
        'near',
        'full',
        'mid',
      ]);
      // mặc định 1 km: quán 5 km chưa vào
      expect(ids(const TableQuery(areaId: 'A')), ['near', 'full', 'mid']);
      expect(ids(const TableQuery(areaId: 'A', radiusM: 10000)), [
        'near',
        'full',
        'mid',
        'far',
      ]);
    });

    test('lọc theo buổi ăn', () {
      const base = TableQuery(areaId: 'A', radiusM: 10000);
      expect(
        ids(
          const TableQuery(
            areaId: 'A',
            radiusM: 10000,
            mealTime: MealTime.evening,
          ),
        ),
        ['mid'],
      );
      expect(
        ids(
          const TableQuery(
            areaId: 'A',
            radiusM: 10000,
            mealTime: MealTime.morning,
          ),
        ),
        ['far'],
      );
      expect(base.mealTime, isNull);
    });

    test('lọc theo ngày', () {
      expect(ids(TableQuery(date: DateTime(2026, 10, 6))), ['far']);
      expect(ids(TableQuery(date: DateTime(2026, 10, 5))), [
        'near',
        'other',
        'full',
        'mid',
      ]);
    });

    test('lọc theo khung giờ trong ngày (gồm cả hai đầu)', () {
      // 11:30 đến 12:30
      expect(
        ids(const TableQuery(fromMinute: 11 * 60 + 30, toMinute: 12 * 60 + 30)),
        ['near', 'other', 'full'],
      );
      expect(ids(const TableQuery(fromMinute: 13 * 60)), ['mid']);
    });

    test('lọc theo món', () {
      expect(ids(const TableQuery(dishId: 'pho')), ['near', 'far']);
      expect(ids(const TableQuery(dishId: 'khong-co')), isEmpty);
    });

    test('kết hợp nhiều điều kiện', () {
      expect(
        ids(
          TableQuery(
            areaId: 'A',
            radiusM: 10000,
            dishId: 'pho',
            date: DateTime(2026, 10, 5),
          ),
        ),
        ['near'],
      );
    });

    test('khu vực không tồn tại thì không có bàn nào', () {
      expect(ids(const TableQuery(areaId: 'Z')), isEmpty);
    });
  });
}
