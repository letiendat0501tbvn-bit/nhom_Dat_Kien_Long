import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/mock/mock_support.dart';
import 'package:giua_ki_app/data/mock_dishes.dart';
import 'package:giua_ki_app/data/models/dish.dart';
import 'package:giua_ki_app/data/models/enums.dart';

Dish dish(
  String id, {
  String? region,
  String? hashtag,
}) => Dish(
  id: id,
  name: id,
  category: 'Ăn vặt',
  description: 'mô tả',
  emoji: '🍲',
  tint: 0xFFEEEEEE,
  region: region,
  hashtag: hashtag,
);

void main() {
  final repo = MockDishRepository(latency: noLatency);

  Future<List<String>> ids({
    String query = '',
    MealTime? mealTime,
    Taste? taste,
    Mood? mood,
    bool onlyTrending = false,
    String? category,
  }) async => (await repo.getDishes(
    query: query,
    mealTime: mealTime,
    taste: taste,
    mood: mood,
    onlyTrending: onlyTrending,
    category: category,
  )).map((d) => d.id).toList();

  group('thứ tự món (khớp ảnh thiết kế)', () {
    test('4 món đầu là Phở, Bánh mì chảo, Bún bò Huế, Bánh xèo', () async {
      final result = await ids();
      expect(result.take(4), ['pho', 'banh-mi-chao', 'bun-bo-hue', 'banh-xeo']);
    });

    test('8 món đầu (phần hiện ở Khám phá) theo thứ tự trong SPEC', () async {
      final result = await ids();
      expect(result.take(8), [
        'pho',
        'banh-mi-chao',
        'bun-bo-hue',
        'banh-xeo',
        'com-tam',
        'mi-quang',
        'lau',
        'oc',
      ]);
    });

    test('vẫn đủ 56 món, không trùng, không sót', () async {
      final result = await ids();
      expect(result.length, 56);
      expect(result.toSet().length, 56);
    });
  });

  group('lọc theo khẩu vị', () {
    test('mỗi trong 8 khẩu vị đều có ít nhất một món', () async {
      expect(Taste.values.length, 8);
      for (final taste in Taste.values) {
        expect(await ids(taste: taste), isNotEmpty, reason: taste.name);
      }
    });

    test('"Cay tê" ra Bún bò Huế và Lẩu', () async {
      final result = await ids(taste: Taste.spicy);
      expect(result, containsAll(['bun-bo-hue', 'lau']));
      expect(result, isNot(contains('pho'))); // Phở không cay
    });

    test('mọi món trả về đều thật sự có khẩu vị đó', () async {
      for (final taste in Taste.values) {
        final dishes = await repo.getDishes(taste: taste);
        expect(
          dishes.every((d) => d.tastes.contains(taste)),
          isTrue,
          reason: taste.name,
        );
      }
    });

    test('đủ mọi món có khẩu vị đó, không sót', () async {
      for (final taste in Taste.values) {
        final expected = kMockDishes
            .where((d) => d.tastes.contains(taste))
            .map((d) => d.id)
            .toList();
        expect(await ids(taste: taste), expected, reason: taste.name);
      }
    });

    test('Chay thanh đạm ra các món chay, Cà phê đậm ra Cà phê', () async {
      expect(
        await ids(taste: Taste.vegetarian),
        containsAll(['pho-chay', 'bun-hue-chay', 'lau-nam']),
      );
      expect(await ids(taste: Taste.coffee), ['ca-phe']);
    });
  });

  group('lọc theo tâm trạng', () {
    test('mỗi trong 6 tâm trạng đều có ít nhất một món', () async {
      expect(Mood.values.length, 6);
      for (final mood in Mood.values) {
        expect(await ids(mood: mood), isNotEmpty, reason: mood.name);
      }
    });

    test('"Thèm ngọt" ra chè và trà sữa', () async {
      expect(
        await ids(mood: Mood.sweetTooth),
        containsAll(['che-buoi', 'che-ba-mau', 'tra-sua']),
      );
    });

    test('mọi món trả về đều có tâm trạng đó', () async {
      for (final mood in Mood.values) {
        final dishes = await repo.getDishes(mood: mood);
        expect(
          dishes.every((d) => d.moods.contains(mood)),
          isTrue,
          reason: mood.name,
        );
      }
    });
  });

  group('lọc món đang hot', () {
    test('chỉ trả về món isTrending, và đủ mọi món hot', () async {
      final expected = kMockDishes.where((d) => d.isTrending).map((d) => d.id);
      expect(await ids(onlyTrending: true), expected.toList());
      expect(expected, isNotEmpty);
    });

    test('mặc định (onlyTrending = false) không lọc theo hot', () async {
      expect((await ids()).length, 56);
    });

    test('món hot gồm Phở và Bún bò Huế', () async {
      expect(await ids(onlyTrending: true), containsAll(['pho', 'bun-bo-hue']));
    });
  });

  group('kết hợp nhiều điều kiện (và)', () {
    test('khẩu vị + buổi ăn: chỉ giữ món vừa cay vừa hợp buổi sáng', () async {
      final spicy = await ids(taste: Taste.spicy);
      final spicyMorning = await ids(
        taste: Taste.spicy,
        mealTime: MealTime.morning,
      );
      expect(spicyMorning.length, lessThan(spicy.length));
      expect(spicyMorning, contains('bun-bo-hue')); // cay và có buổi sáng
      expect(spicyMorning, isNot(contains('lau'))); // lẩu không có buổi sáng
    });

    test('khẩu vị + tâm trạng', () async {
      final result = await repo.getDishes(
        taste: Taste.spicy,
        mood: Mood.social,
      );
      expect(result, isNotEmpty);
      expect(
        result.every(
          (d) =>
              d.tastes.contains(Taste.spicy) && d.moods.contains(Mood.social),
        ),
        isTrue,
      );
    });

    test('hot + khẩu vị', () async {
      final result = await repo.getDishes(
        onlyTrending: true,
        taste: Taste.spicy,
      );
      expect(result, isNotEmpty);
      expect(
        result.every((d) => d.isTrending && d.tastes.contains(Taste.spicy)),
        isTrue,
      );
    });

    test('khẩu vị + tìm kiếm không dấu', () async {
      expect(await ids(taste: Taste.spicy, query: 'lau thai'), ['lau-thai']);
      expect(await ids(taste: Taste.spicy, query: 'pho'), isEmpty);
    });

    test('khẩu vị + danh mục', () async {
      final result = await ids(taste: Taste.spicy, category: 'Món lẩu');
      expect(result, containsAll(['lau', 'lau-thai']));
      expect(await ids(taste: Taste.coffee, category: 'Món lẩu'), isEmpty);
    });

    test('tổ hợp không món nào thoả thì trả về rỗng', () async {
      expect(
        await ids(taste: Taste.coffee, mealTime: MealTime.evening),
        isEmpty,
      );
    });
  });

  group('getRegionalDishes (ba miền)', () {
    test('đúng 4 món theo thứ tự Bún chả, Mì Quảng, Ốc, Bánh xèo', () async {
      final dishes = await repo.getRegionalDishes();
      expect(dishes.map((d) => d.id), [
        'bun-cha',
        'mi-quang',
        'oc',
        'banh-xeo',
      ]);
    });

    test('mỗi món có vùng và hashtag đúng theo SPEC', () async {
      final dishes = await repo.getRegionalDishes();
      expect(dishes.map((d) => (d.region, d.hashtag)), [
        ('Hà Nội', '#HanoiClassic'),
        ('Miền Trung', '#CentralVietnam'),
        ('Sài Gòn đêm', '#StreetFoodCulture'),
        ('Hương vị ba miền', '#CrispyPancakes'),
      ]);
    });

    test('bỏ qua món trong danh sách không có vùng', () async {
      final custom = MockDishRepository(
        latency: noLatency,
        dishes: [
          dish('bun-cha'), // thiếu vùng nên bị bỏ
          dish('oc', region: 'Sài Gòn đêm', hashtag: '#x'),
        ],
      );
      expect((await custom.getRegionalDishes()).map((d) => d.id), ['oc']);
    });
  });
}
