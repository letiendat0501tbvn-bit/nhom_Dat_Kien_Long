import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/logic/dice_rules.dart';
import 'package:giua_ki_app/data/mock_dishes.dart';
import 'package:giua_ki_app/data/models/dish.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/l10n/strings.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/ui/components/dice_sheet.dart';
import 'package:giua_ki_app/ui/screens/dish_detail_screen.dart';

import 'test_helpers.dart';

const tall = Size(412, 915);

// Random cho kết quả xác định: nextInt(max) lấy lần lượt các giá trị đã cho (lấy dư theo max).
class SeqRandom implements Random {
  SeqRandom(this.values);

  final List<int> values;
  int calls = 0;

  @override
  int nextInt(int max) => values[calls++ % values.length] % max;

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}

Dish dish(String id, {List<MealTime> meals = const [], String name = ''}) =>
    Dish(
      id: id,
      name: name.isEmpty ? id : name,
      category: 'Bún & mì',
      description: 'Mô tả $id',
      emoji: '🍜',
      tint: 0xFFEEEEEE,
      mealTimes: meals,
    );

// Chữ nằm trong hộp thoại Lắc món (tránh nhầm với các chữ cùng tên ở màn bên dưới).
Finder inSheet(String text) =>
    find.descendant(of: find.byType(DiceSheet), matching: find.text(text));

Future<void> openDice(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Lắc món').first);
  await tester.pumpAndSettle();
}

// Bấm quay và chờ quay xong.
Future<void> spinAndWait(WidgetTester tester, String label) async {
  await tester.tap(inSheet(label));
  await tester.pumpAndSettle();
}

void main() {
  group('Quy tắc thuần', () {
    final morning = dish('a', meals: [MealTime.morning, MealTime.noon]);
    final evening = dish('b', meals: [MealTime.evening]);
    final none = dish('c');

    test('không chọn buổi: quay trong tất cả món', () {
      final r = dicePool([morning, evening, none], null);
      expect(r.pool.length, 3);
      expect(r.fallback, isFalse);
    });

    test('có chọn buổi: chỉ lấy món hợp buổi đó', () {
      final r = dicePool([morning, evening, none], MealTime.morning);
      expect(r.pool.map((d) => d.id), ['a']);
      expect(r.fallback, isFalse);
      expect(
        dicePool([morning, evening, none], MealTime.evening).pool.single.id,
        'b',
      );
    });

    test('không món nào hợp buổi: quay cả danh sách và báo fallback', () {
      final r = dicePool([morning, evening], MealTime.lateNight);
      expect(r.pool.length, 2);
      expect(r.fallback, isTrue);
    });

    test('pickDish theo Random cố định; dải món kết thúc ở kết quả', () {
      final pool = [morning, evening, none];
      expect(pickDish(pool, SeqRandom([0])).id, 'a');
      expect(pickDish(pool, SeqRandom([1])).id, 'b');
      expect(pickDish(pool, SeqRandom([5])).id, 'c');
      final reel = diceReel(pool, evening, SeqRandom([0, 1, 2]), steps: 5);
      expect(reel.length, 6);
      expect(reel.last, evening);
    });

    test(
      'với Random thật: 200 lần quay buổi sáng luôn ra món hợp buổi sáng',
      () {
        final pool = dicePool(kMockDishes, MealTime.morning).pool;
        expect(pool, isNotEmpty);
        final r = Random(7);
        for (var i = 0; i < 200; i++) {
          expect(pickDish(pool, r).mealTimes, contains(MealTime.morning));
        }
      },
    );

    test(
      'mỗi buổi ăn đều có món trong dữ liệu mẫu (không phải rơi vào fallback)',
      () {
        for (final m in MealTime.values) {
          expect(dicePool(kMockDishes, m).fallback, isFalse, reason: m.name);
        }
      },
    );
  });

  group('Hộp thoại Lắc món', () {
    phoneTest('mở bằng nút xúc xắc, có đủ câu gốc và nút; đóng được', (
      tester,
    ) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();
      await openDice(tester);
      expect(find.byType(DiceSheet), findsOneWidget);
      expect(
        find.text('Không biết ăn gì? Bấm quay là có kèo!'),
        findsOneWidget,
      );
      expect(
        find.text('Một vòng quay, một món ngon, một cuộc hẹn mới.'),
        findsOneWidget,
      );
      expect(find.text('Hôm nay để món chọn bạn!'), findsOneWidget);
      expect(find.text('Quay món liền!'), findsOneWidget);
      expect(inSheet('Tìm bàn ăn'), findsNothing); // chưa có kết quả

      await tester.tapAt(const Offset(200, 40)); // chạm ngoài bảng
      await tester.pumpAndSettle();
      expect(find.byType(DiceSheet), findsNothing);
    }, size: tall);

    phoneTest('mở được từ mọi tab có thanh trên (Hồ sơ cũng có)', (
      tester,
    ) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tôi').last);
      await tester.pumpAndSettle();
      await openDice(tester);
      expect(find.byType(DiceSheet), findsOneWidget);
    }, size: tall);

    phoneTest('quay ra đúng món theo Random cố định, có hiệu ứng rồi dừng', (
      tester,
    ) async {
      final random = SeqRandom([5]);
      final app = makeAppState(random: random);
      final all = (await tester.runAsync(
        () => app.dishRepository.getDishes(),
      ))!;
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await openDice(tester);

      await tester.tap(find.text('Quay món liền!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400)); // đang quay
      expect(find.text('Đang quay…'), findsOneWidget);
      expect(inSheet('Tìm bàn ăn'), findsNothing);

      await tester.pumpAndSettle();
      final expected = all[5 % all.length];
      expect(find.text(expected.name), findsWidgets);
      expect(inSheet(expected.description), findsOneWidget);
      expect(inSheet('Tìm bàn ăn'), findsOneWidget);
      expect(find.text('Quay lại'), findsOneWidget);
      expect(find.text('Đang quay…'), findsNothing);
    }, size: tall);

    phoneTest('không bấm đúp khi đang quay: chỉ một lần quay', (tester) async {
      final random = SeqRandom([3]);
      final app = makeAppState(random: random);
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await openDice(tester);
      await tester.tap(find.text('Quay món liền!'));
      await tester.pump(const Duration(milliseconds: 300));
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      // 1 lần chọn kết quả + 16 bước của dải món = 17 lần gọi; hai lần quay sẽ là 34
      expect(random.calls, 17);
    }, size: tall);

    phoneTest('"Quay lại" quay lần nữa ra món khác theo Random', (
      tester,
    ) async {
      final random = SeqRandom([
        2,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        9,
      ]);
      final app = makeAppState(random: random);
      final all = (await tester.runAsync(
        () => app.dishRepository.getDishes(),
      ))!;
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await openDice(tester);
      await spinAndWait(tester, 'Quay món liền!');
      expect(find.text(all[2].name), findsWidgets);

      await spinAndWait(tester, 'Quay lại');
      expect(random.calls, 34);
      expect(find.text(all[9 % all.length].name), findsWidgets);
      expect(find.text('Quay lại'), findsOneWidget);
    }, size: tall);

    phoneTest('"Tìm bàn ăn" mở đúng Chi tiết món, cuộn tới bàn ăn; Back về', (
      tester,
    ) async {
      final app = makeAppState(random: SeqRandom([4]));
      final all = (await tester.runAsync(
        () => app.dishRepository.getDishes(),
      ))!;
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await openDice(tester);
      await spinAndWait(tester, 'Quay món liền!');
      await tester.tap(inSheet('Tìm bàn ăn'));
      await tester.pumpAndSettle();

      expect(find.byType(DiceSheet), findsNothing);
      final screen = tester.widget<DishDetailScreen>(
        find.byType(DishDetailScreen),
      );
      expect(screen.dish.id, all[4].id);
      expect(screen.scrollToTables, isTrue);
      expect(find.text('Bàn ăn cho món này'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DishDetailScreen), findsNothing);
    }, size: tall);
  });

  group('Buổi ăn trong bộ lọc', () {
    phoneTest('đã chọn buổi: chỉ quay món hợp buổi, có ghi chú', (
      tester,
    ) async {
      for (final meal in [MealTime.morning, MealTime.evening]) {
        final app = makeAppState(random: Random(3))..setMealTime(meal);
        await tester.pumpWidget(MyApp(appState: app));
        await tester.pumpAndSettle();
        await openDice(tester);
        expect(
          find.text('Đang quay theo buổi ${app.strings.mealTimeLabel(meal)}.'),
          findsOneWidget,
        );
        // Quay vài lần, mỗi lần món ra phải có buổi đó
        for (var i = 0; i < 4; i++) {
          await spinAndWait(tester, i == 0 ? 'Quay món liền!' : 'Quay lại');
          final name = tester
              .widget<Semantics>(
                find.byWidgetPredicate(
                  (w) => w is Semantics && w.properties.liveRegion == true,
                ),
              )
              .properties
              .label!
              .replaceFirst('Món vừa ra: ', '');
          final shown = kMockDishes.firstWhere((d) => d.name == name);
          expect(
            shown.mealTimes,
            contains(meal),
            reason: '$name / ${meal.name}',
          );
        }
        await tester.pumpWidget(const SizedBox());
      }
    }, size: tall);

    phoneTest('không món nào hợp buổi: quay trong tất cả món và nói rõ', (
      tester,
    ) async {
      final repo = FakeDishRepository(
        dishes: [
          dish('x', name: 'Món X'),
          dish('y', name: 'Món Y'),
        ],
      );
      final app = makeAppStateWithTables(
        const [],
        dishRepository: repo,
        random: SeqRandom([1]),
      )..setMealTime(MealTime.lateNight);
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await openDice(tester);
      await spinAndWait(tester, 'Quay món liền!');
      expect(
        find.text('Chưa có món hợp buổi Khuya, nên quay trong tất cả món.'),
        findsOneWidget,
      );
      expect(find.text('Món Y'), findsWidgets);
    }, size: tall);

    phoneTest('lỗi tải món: báo lỗi và quay lại được', (tester) async {
      final repo = FakeDishRepository(dishes: [dish('x', name: 'Món X')])
        ..fail = true;
      final app = makeAppStateWithTables(
        const [],
        dishRepository: repo,
        random: SeqRandom([0]),
      );
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      // FakeDishRepository.fail cũng làm hỏng trang chủ; vẫn mở được hộp thoại
      await openDice(tester);
      await tester.tap(find.text('Quay món liền!'));
      await tester.pumpAndSettle();
      expect(find.text('Quay món liền!'), findsOneWidget); // nút dùng lại được
      expect(find.byType(DiceSheet), findsOneWidget);
      repo.fail = false;
      await spinAndWait(tester, 'Quay món liền!');
      expect(find.text('Món X'), findsWidgets);
    }, size: tall);
  });

  group('Giảm hoạt ảnh', () {
    phoneTest(
      'khi hệ thống bật giảm hoạt ảnh: hiện kết quả ngay, không chạy dải món',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final app = makeAppState(random: SeqRandom([6]));
        final all = (await tester.runAsync(
          () => app.dishRepository.getDishes(),
        ))!;
        await tester.pumpWidget(MyApp(appState: app));
        await tester.pumpAndSettle();
        await openDice(tester);
        await tester.tap(find.text('Quay món liền!'));
        await tester.pump(); // chỉ chờ lần tải món, không chờ 1,8 giây
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('Đang quay…'), findsNothing);
        expect(inSheet('Tìm bàn ăn'), findsOneWidget);
        expect(find.text(all[6].name), findsWidgets);
      },
      size: tall,
    );
  });

  group('Tiếng Anh và nhãn ngữ nghĩa', () {
    phoneTest('EN: câu gốc, nút và kết quả bằng tiếng Anh', (tester) async {
      final app = makeAppState(random: SeqRandom([0]))
        ..setLanguage(AppLanguage.en);
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Spin for a dish').first);
      await tester.pumpAndSettle();
      expect(
        find.text("Can't decide what to eat? Spin and get a plan!"),
        findsOneWidget,
      );
      expect(
        find.text('One spin, one tasty dish, one new meetup.'),
        findsOneWidget,
      );
      expect(find.text('Today, let the dish choose you!'), findsOneWidget);
      await spinAndWait(tester, 'Spin now!');
      expect(inSheet('Find a table'), findsOneWidget);
      expect(find.text('Spin again'), findsOneWidget);
    }, size: tall);

    phoneTest(
      'nút xúc xắc có nhãn "Lắc món"; kết quả là live region đọc món vừa ra',
      (tester) async {
        final handle = tester.ensureSemantics();
        final app = makeAppState(random: SeqRandom([1]));
        final all = (await tester.runAsync(
          () => app.dishRepository.getDishes(),
        ))!;
        await tester.pumpWidget(MyApp(appState: app));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Lắc món'), findsOneWidget);
        await openDice(tester);
        await spinAndWait(tester, 'Quay món liền!');

        final label = 'Món vừa ra: ${all[1].name}';
        expect(find.bySemanticsLabel(label), findsOneWidget);
        final data = tester
            .getSemantics(find.bySemanticsLabel(label))
            .getSemanticsData();
        expect(data.flagsCollection.isLiveRegion, isTrue);
        handle.dispose();
      },
      size: tall,
    );
  });

  group('Không tràn dòng', () {
    for (final language in AppLanguage.values) {
      for (final scale in [1.0, 1.3]) {
        for (final width in [360.0, 412.0]) {
          phoneTest('${language.name}, chữ x$scale, rộng ${width.toInt()}', (
            tester,
          ) async {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.platformDispatcher.clearAllTestValues);
            final app = makeAppState(random: SeqRandom([11, 20, 30]))
              ..setLanguage(language)
              ..setMealTime(MealTime.noon);
            final t = app.strings;
            await tester.pumpWidget(MyApp(appState: app));
            await tester.pumpAndSettle();
            await tester.tap(find.bySemanticsLabel(t(StrKey.semDice)).first);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.tap(find.text(t(StrKey.diceSpin)));
            await tester.pump(
              const Duration(milliseconds: 500),
            ); // giữa lúc quay
            expect(tester.takeException(), isNull);
            await tester.pumpAndSettle();
            await spinAndWait(tester, t(StrKey.diceAgain));
            expect(tester.takeException(), isNull);
          }, size: Size(width, 915));
        }
      }
    }
  });

  group('Chuỗi l10n không mồ côi', () {
    test(
      'mọi khoá StrKey đều được dùng ở đâu đó trong lib/ (ngoài bảng chuỗi)',
      () {
        // Một khoá được coi là dùng khi xuất hiện dạng StrKey.tên không phải là mục của bảng
        // (mục của bảng có dạng "StrKey.tên:" liền sau tên).
        final src = StringBuffer();
        for (final f in Directory('lib').listSync(recursive: true)) {
          if (f is File && f.path.endsWith('.dart')) {
            src.writeln(f.readAsStringSync());
          }
        }
        final text = src.toString();
        final orphans = [
          for (final k in StrKey.values)
            if (!RegExp('StrKey\\.${k.name}\\b(?!:)').hasMatch(text)) k.name,
        ];
        expect(orphans, isEmpty, reason: 'Khoá không còn dùng: $orphans');
      },
    );
  });
}
