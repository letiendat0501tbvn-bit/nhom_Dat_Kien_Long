import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/core/entity.dart';
import 'package:giua_ki_app/core/firestore_repo.dart';
import 'package:giua_ki_app/data/mock/mock_data.dart';
import 'package:giua_ki_app/data/mock_dishes.dart';
import 'package:giua_ki_app/data/models/area.dart';
import 'package:giua_ki_app/data/models/chat_message.dart';
import 'package:giua_ki_app/data/models/dining_table.dart';
import 'package:giua_ki_app/data/models/dish.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/data/models/report.dart';
import 'package:giua_ki_app/data/models/restaurant.dart';
import 'package:giua_ki_app/data/models/user.dart';
import 'package:giua_ki_app/data/models/user_feedback.dart';

final _now = DateTime(2026, 10, 5, 10, 30);

// Khứ hồi: x.toMap() -> fromMap -> toMap phải cho đúng Map ban đầu; thêm một vòng qua
// bộ đổi kiểu Firestore (DateTime <-> Timestamp) để chắc dữ liệu thật cũng đi về nguyên vẹn.
void expectRoundTrip<E extends Entity<String>>(
  E original,
  E Function(String, Map<String, dynamic>) fromMap,
) {
  final map = original.toMap();
  expect(
    map.containsKey('id'),
    isFalse,
    reason: 'id là id document, không nằm trong map',
  );

  final back = fromMap(original.id, map);
  expect(back, original); // cùng lớp, cùng id
  expect(back.runtimeType, original.runtimeType);
  expect(back.toMap(), map);

  final viaFirestore =
      fromFirestoreValue(toFirestoreValue(map)) as Map<String, dynamic>;
  expect(fromMap(original.id, viaFirestore).toMap(), map);
}

void main() {
  group('toMap / fromMap khứ hồi', () {
    test('Area', () {
      expectRoundTrip(mockAreas.first, Area.fromMap);
      expect(mockAreas.first.toMap().keys.toSet(), {
        'city',
        'district',
        'lat',
        'lng',
      });
    });

    test(
      'Restaurant',
      () => expectRoundTrip(mockRestaurants.first, Restaurant.fromMap),
    );

    test('User (có và không có ngày tạo)', () {
      expectRoundTrip(mockUsers.first, User.fromMap);
      expectRoundTrip(
        User(
          id: 'r1',
          displayName: 'Mới',
          email: 'moi@example.com',
          createdAt: _now,
        ),
        User.fromMap,
      );
      expect(
        User.fromMap('x', {'displayName': 'A', 'email': 'a@b.co'}).createdAt,
        isNull,
      );
    });

    test('DiningTable: ngày giờ, enum status và danh sách thành viên', () {
      final t = DiningTable(
        id: 't9',
        dishId: 'pho',
        restaurantId: 'q1-1',
        hostId: 'u2',
        startAt: _now,
        durationMin: 90,
        capacity: 6,
        note: 'Ghi chú',
        status: TableStatus.full,
        memberIds: ['u2', 'u3', 'u4'],
      );
      expectRoundTrip(t, DiningTable.fromMap);
      final back = DiningTable.fromMap('t9', t.toMap());
      expect(back.status, TableStatus.full);
      expect(back.startAt, _now);
      expect(back.memberIds, ['u2', 'u3', 'u4']);
    });

    test('DiningTable không có món và bộ dữ liệu thiếu trường tuỳ chọn', () {
      final t = DiningTable(
        id: 't1',
        restaurantId: 'q1-1',
        hostId: 'u1',
        startAt: _now,
        durationMin: 60,
        capacity: 4,
        memberIds: const ['u1'],
      );
      expectRoundTrip(t, DiningTable.fromMap);
      final minimal = DiningTable.fromMap('t2', {
        'restaurantId': 'q1-1',
        'hostId': 'u1',
        'startAt': _now,
        'durationMin': 60,
        'capacity': 4,
        'memberIds': ['u1'],
      });
      expect(minimal.dishId, isNull);
      expect(minimal.note, '');
      expect(minimal.status, TableStatus.open);
    });

    test('ChatMessage, Report, UserFeedback', () {
      expectRoundTrip(
        ChatMessage(
          id: 'm1',
          tableId: 't1',
          senderId: 'u1',
          text: 'Chào',
          sentAt: _now,
        ),
        ChatMessage.fromMap,
      );
      expectRoundTrip(
        Report(
          id: 'r1',
          reporterId: 'u1',
          targetType: ReportTargetType.message,
          targetId: 'm1',
          reason: 'spam',
          createdAt: _now,
          note: 'ghi chú',
        ),
        Report.fromMap,
      );
      expectRoundTrip(
        UserFeedback(id: 'f1', userId: 'u1', text: 'Hay', createdAt: _now),
        UserFeedback.fromMap,
      );
    });

    test(
      'Dish: mọi món mẫu đi về nguyên vẹn (enum, danh sách, trường tuỳ chọn)',
      () {
        for (final d in kMockDishes) {
          expectRoundTrip(d, Dish.fromMap);
          final back = Dish.fromMap(d.id, d.toMap());
          expect(back.tastes, d.tastes, reason: d.id);
          expect(back.moods, d.moods, reason: d.id);
          expect(back.mealTimes, d.mealTimes, reason: d.id);
          expect(back.descriptionEn, d.descriptionEn, reason: d.id);
          expect(back.imageAsset, d.imageAsset, reason: d.id);
        }
      },
    );

    test('enum lạ không làm hỏng: dùng giá trị dự phòng hoặc bị bỏ qua', () {
      final r = Report.fromMap('r', {
        'reporterId': 'u1',
        'targetType': 'khong-co',
        'targetId': 'x',
        'reason': 'spam',
        'createdAt': _now,
      });
      expect(r.targetType, ReportTargetType.table);
      final d = Dish.fromMap('d', {
        'name': 'A',
        'category': 'c',
        'description': 'm',
        'emoji': 'e',
        'tint': 1,
        'tastes': ['spicy', 'khong-co'],
      });
      expect(d.tastes, [Taste.spicy]);
    });
  });

  group('đổi kiểu Dart <-> Firestore', () {
    test('DateTime thành Timestamp và ngược lại, đệ quy trong Map/List', () {
      final map = {
        'at': _now,
        'nested': {'when': _now},
        'list': [_now, 'x', 3],
      };
      final encoded = toFirestoreValue(map) as Map<String, dynamic>;
      expect(encoded['at'], isA<Timestamp>());
      expect((encoded['nested'] as Map)['when'], isA<Timestamp>());
      expect((encoded['list'] as List)[0], isA<Timestamp>());
      expect((encoded['list'] as List)[1], 'x');
      final decoded = fromFirestoreValue(encoded) as Map<String, dynamic>;
      expect(decoded['at'], _now);
      expect((decoded['nested'] as Map)['when'], _now);
      expect(decoded['list'], [_now, 'x', 3]);
    });

    test('giá trị thường và null giữ nguyên', () {
      expect(toFirestoreValue(null), isNull);
      expect(toFirestoreValue(5), 5);
      expect(fromFirestoreValue('a'), 'a');
    });
  });
}
