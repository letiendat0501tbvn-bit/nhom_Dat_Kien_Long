import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/logic/table_rules.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/l10n/formatters.dart';
import 'package:giua_ki_app/l10n/strings.dart';

import 'test_helpers.dart';

void main() {
  group('joinStateOf (trạng thái nút ở thẻ bàn)', () {
    final open = makeTable('o', start: testNow, members: ['a', 'b']); // 2/4
    final full = makeTable(
      'f',
      start: testNow,
      capacity: 2,
      members: ['a', 'b'],
    );

    test('khách (chưa đăng nhập): còn chỗ thì Tham gia, đầy thì Đã đầy', () {
      expect(joinStateOf(open, null), TableJoinState.canJoin);
      expect(joinStateOf(full, null), TableJoinState.full);
    });

    test('thành viên chưa vào bàn: còn chỗ thì Tham gia, đầy thì Đã đầy', () {
      expect(joinStateOf(open, 'x'), TableJoinState.canJoin);
      expect(joinStateOf(full, 'x'), TableJoinState.full);
    });

    test('đã ở trong bàn thì luôn là Đã tham gia, kể cả bàn đã đầy', () {
      expect(joinStateOf(open, 'a'), TableJoinState.joined);
      expect(joinStateOf(full, 'b'), TableJoinState.joined);
    });
  });

  group('formatClockTime', () {
    final vi = AppLanguage.vi;
    final en = AppLanguage.en;
    DateTime at(int h, int m) => DateTime(2026, 10, 5, h, m);

    test('tiếng Việt dùng 24 giờ có số 0 đầu', () {
      expect(formatClockTime(at(0, 0), vi), '00:00');
      expect(formatClockTime(at(9, 5), vi), '09:05');
      expect(formatClockTime(at(12, 0), vi), '12:00');
      expect(formatClockTime(at(13, 30), vi), '13:30');
      expect(formatClockTime(at(23, 59), vi), '23:59');
    });

    test('tiếng Anh dùng 12 giờ AM/PM', () {
      expect(formatClockTime(at(0, 0), en), '12:00 AM');
      expect(formatClockTime(at(9, 5), en), '9:05 AM');
      expect(formatClockTime(at(11, 59), en), '11:59 AM');
      expect(formatClockTime(at(12, 0), en), '12:00 PM');
      expect(formatClockTime(at(12, 5), en), '12:05 PM');
      expect(formatClockTime(at(13, 30), en), '1:30 PM');
      expect(formatClockTime(at(23, 59), en), '11:59 PM');
    });
  });

  group('nhãn của thẻ bàn', () {
    const vi = Strings(AppLanguage.vi);
    const en = Strings(AppLanguage.en);

    test('timeRange theo ngôn ngữ', () {
      final start = DateTime(2026, 10, 5, 11, 30);
      expect(vi.timeRange(start, 60), '11:30–12:30');
      expect(en.timeRange(start, 60), '11:30 AM–12:30 PM');
      expect(en.timeRange(DateTime(2026, 10, 5, 14, 0), 90), '2:00 PM–3:30 PM');
    });

    test('timeRange qua nửa đêm', () {
      final start = DateTime(2026, 10, 5, 23, 30);
      expect(vi.timeRange(start, 60), '23:30–00:30');
      expect(en.timeRange(start, 60), '11:30 PM–12:30 AM');
    });

    test('seatsLabel: còn chỗ và đã đầy', () {
      expect(vi.seatsLabel(2, 4), 'Còn 2/4 chỗ');
      expect(en.seatsLabel(2, 4), '2/4 seats left');
      expect(vi.seatsLabel(0, 4), 'Đủ 4/4 chỗ');
      expect(en.seatsLabel(0, 4), '4/4 seats taken');
    });

    test('widenRadiusLabel', () {
      expect(vi.widenRadiusLabel(500), 'Nới bán kính lên 500 m');
      expect(vi.widenRadiusLabel(10000), 'Nới bán kính lên 10 km');
      expect(en.widenRadiusLabel(1000), 'Widen radius to 1 km');
    });

    test('fill điền nhiều chỗ trống', () {
      expect(vi.fill(StrKey.seatsLeft, {'left': 1, 'total': 8}), 'Còn 1/8 chỗ');
    });

    test('mọi khoá có chỗ trống đều có đủ chỗ trống ở cả hai ngôn ngữ', () {
      const placeholders = {
        StrKey.seatsLeft: ['{left}', '{total}'],
        StrKey.seatsFull: ['{total}'],
        StrKey.widenRadius: ['{radius}'],
        StrKey.seeAllDishes: ['{n}'],
      };
      placeholders.forEach((key, names) {
        for (final name in names) {
          expect(viStrings[key], contains(name), reason: 'VI ${key.name}');
          expect(enStrings[key], contains(name), reason: 'EN ${key.name}');
        }
      });
    });

    test('filterSummary: mặc định chỉ có bán kính và ngày', () {
      final today = DateTime(2026, 10, 5);
      expect(
        vi.filterSummary(radiusM: 1000, date: today, today: today),
        '1 km · Hôm nay · 05/10',
      );
      expect(
        en.filterSummary(
          radiusM: 500,
          date: DateTime(2026, 10, 6),
          today: today,
        ),
        '500 m · Tomorrow · 06/10',
      );
    });

    test('filterSummary: thêm buổi ăn và khung giờ', () {
      final today = DateTime(2026, 10, 5);
      expect(
        vi.filterSummary(
          radiusM: 1000,
          date: today,
          today: today,
          mealTime: MealTime.noon,
          fromMinute: 12 * 60,
          toMinute: 15 * 60,
        ),
        '1 km · Hôm nay · 05/10 · Trưa · 12:00–15:00',
      );
      // Chỉ có một đầu: đầu còn lại để trống
      expect(
        vi.filterSummary(
          radiusM: 100,
          date: today,
          today: today,
          fromMinute: 600,
        ),
        '100 m · Hôm nay · 05/10 · 10:00–',
      );
      expect(
        vi.filterSummary(
          radiusM: 100,
          date: today,
          today: today,
          toMinute: 600,
        ),
        '100 m · Hôm nay · 05/10 · –10:00',
      );
    });
  });

  group('AppState: khu vực', () {
    test('trước khi load() danh sách khu vực rỗng và selectedArea là null', () {
      final app = makeAppState();
      addTearDown(app.dispose);
      app.selectArea('hcm-q1');
      expect(app.areas, isEmpty);
      expect(app.selectedAreaId, 'hcm-q1');
      expect(app.selectedArea, isNull);
    });

    test('sau load() có đủ 8 khu vực và selectedArea đúng', () async {
      final app = makeAppState();
      addTearDown(app.dispose);
      app.selectArea('hn-hoan-kiem');
      await app.load();

      expect(app.areas.length, 8);
      expect(app.selectedArea?.district, 'Hoàn Kiếm');
      expect(app.selectedArea?.label, 'Hà Nội · Hoàn Kiếm');

      app.selectArea(null);
      expect(app.selectedArea, isNull);
    });

    test('load() báo cho giao diện biết khi nạp xong', () async {
      final app = makeAppState();
      addTearDown(app.dispose);
      var n = 0;
      app.addListener(() => n++);
      await app.load();
      expect(n, 1);
    });

    test('today là hôm nay theo đồng hồ, bỏ phần giờ', () {
      final app = makeAppState();
      addTearDown(app.dispose);
      expect(app.today, DateTime(2026, 10, 5));
    });
  });
}
