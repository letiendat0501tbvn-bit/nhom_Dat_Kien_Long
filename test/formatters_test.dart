import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/logic/table_rules.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/l10n/formatters.dart';
import 'package:giua_ki_app/l10n/strings.dart';

void main() {
  group('định dạng', () {
    test('formatMinuteOfDay', () {
      expect(formatMinuteOfDay(0), '00:00');
      expect(formatMinuteOfDay(615), '10:15');
      expect(formatMinuteOfDay(1439), '23:59');
    });

    test('formatDayMonth thêm số 0 phía trước', () {
      expect(formatDayMonth(DateTime(2026, 10, 5)), '05/10');
      expect(formatDayMonth(DateTime(2026, 12, 31)), '31/12');
    });

    test('formatRadius', () {
      expect(formatRadius(100), '100 m');
      expect(formatRadius(500), '500 m');
      expect(formatRadius(1000), '1 km');
      expect(formatRadius(10000), '10 km');
    });

    test('isSameDay bỏ qua giờ', () {
      expect(isSameDay(DateTime(2026, 10, 5, 1), DateTime(2026, 10, 5, 23)), isTrue);
      expect(isSameDay(DateTime(2026, 10, 5), DateTime(2026, 10, 6)), isFalse);
      expect(isSameDay(DateTime(2026, 10, 5), DateTime(2025, 10, 5)), isFalse);
    });
  });

  group('timeSlots (bước 15 phút)', () {
    test('cả ngày có 96 mốc từ 00:00 đến 23:45', () {
      final all = timeSlots();
      expect(all.length, 96);
      expect(all.first, 0);
      expect(all.last, 23 * 60 + 45);
      expect(all.every((m) => m % 15 == 0), isTrue);
    });

    test('giới hạn dưới và trên đều được tính gồm cả đầu mút', () {
      final slots = timeSlots(min: 600, max: 660);
      expect(slots, [600, 615, 630, 645, 660]);
    });

    test('min không phải bội của 15 thì bắt đầu từ mốc kế tiếp', () {
      expect(timeSlots(min: 601, max: 640), [615, 630]);
    });

    test('khoảng rỗng', () {
      expect(timeSlots(min: 700, max: 600), isEmpty);
    });
  });

  group('nhãn buổi ăn và nhãn ngày', () {
    const vi = Strings(AppLanguage.vi);
    const en = Strings(AppLanguage.en);
    final today = DateTime(2026, 10, 5); // thứ Hai

    test('mealTimeLabel đủ 5 buổi ở cả hai ngôn ngữ', () {
      expect(MealTime.values.map(vi.mealTimeLabel),
          ['Sáng', 'Trưa', 'Xế', 'Tối', 'Khuya']);
      expect(MealTime.values.map(en.mealTimeLabel),
          ['Morning', 'Noon', 'Afternoon', 'Evening', 'Late night']);
    });

    test('dayLabel: hôm nay, ngày mai và thứ trong tuần kèm ngày thực tế', () {
      expect(vi.dayLabel(today, today), 'Hôm nay · 05/10');
      expect(vi.dayLabel(DateTime(2026, 10, 6), today), 'Ngày mai · 06/10');
      expect(vi.dayLabel(DateTime(2026, 10, 7), today), 'T4 · 07/10');
      expect(vi.dayLabel(DateTime(2026, 10, 11), today), 'CN · 11/10');
      expect(en.dayLabel(today, today), 'Today · 05/10');
      expect(en.dayLabel(DateTime(2026, 10, 7), today), 'Wed · 07/10');
    });

    test('dayLabel đúng khi sang tháng', () {
      final endOfMonth = DateTime(2026, 10, 31);
      expect(vi.dayLabel(DateTime(2026, 11, 1), endOfMonth), 'Ngày mai · 01/11');
    });
  });
}
