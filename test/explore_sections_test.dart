import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/logic/text_search.dart';
import 'package:giua_ki_app/data/mock_dishes.dart';
import 'package:giua_ki_app/data/models/dish.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/l10n/strings.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/ui/components/dish_card.dart';
import 'package:giua_ki_app/ui/components/dish_picker.dart';
import 'package:giua_ki_app/ui/components/recommend_section.dart';
import 'package:giua_ki_app/ui/components/region_section.dart';

import 'test_helpers.dart';

Dish makeDish(String name) => Dish(
  id: name,
  name: name,
  category: 'Ăn vặt',
  description: 'mô tả $name',
  emoji: '🍲',
  tint: 0xFFEEEEEE,
);

// Cuộn dải ngang (ListView) tới khi thấy chữ cần tìm.
Future<void> scrollStripTo(WidgetTester tester, String text) {
  return tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    ),
  );
}

const _tastes = [
  'Cay tê',
  'Thịt nướng',
  'Chay thanh đạm',
  'Sợi / Nước dùng',
  'Cơm dẻo',
  'Hải sản',
  'Chè ngọt',
  'Cà phê đậm',
];

void main() {
  group('Gợi ý cho bạn', () {
    phoneTest('có tiêu đề, 3 tab, 8 chip khẩu vị và lời nhắc, chưa có món', (
      tester,
    ) async {
      await tester.pumpWidget(wrapWithApp(const RecommendSection()));
      await tester.pumpAndSettle();

      expect(find.text('Gợi ý cho bạn'), findsOneWidget);
      expect(
        find.text('Chọn theo khẩu vị, tâm trạng hoặc xem món đang được thèm.'),
        findsOneWidget,
      );
      for (final tab in ['Hợp vị', 'Tâm trạng', 'Đang hot']) {
        expect(find.text(tab), findsOneWidget, reason: tab);
      }
      for (final chip in _tastes) {
        expect(find.text(chip), findsOneWidget, reason: chip);
      }
      expect(find.byType(ChoiceChip), findsNWidgets(8));
      expect(find.text('Chọn một khẩu vị để xem món gợi ý.'), findsOneWidget);
      expect(find.byType(DishCard), findsNothing);
    });

    phoneTest('chọn "Cay tê" thì lọc ra Bún bò Huế và Lẩu', (tester) async {
      await tester.pumpWidget(wrapWithApp(const RecommendSection()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cay tê'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn một khẩu vị để xem món gợi ý.'), findsNothing);
      expect(find.text('Bún bò Huế'), findsOneWidget);
      expect(find.text('Phở'), findsNothing); // Phở không cay
      await scrollStripTo(tester, 'Lẩu');
      expect(find.text('Lẩu'), findsOneWidget);
    });

    phoneTest('bấm lại chip đang chọn thì bỏ chọn và hiện lại lời nhắc', (
      tester,
    ) async {
      await tester.pumpWidget(wrapWithApp(const RecommendSection()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hải sản'));
      await tester.pumpAndSettle();
      expect(find.byType(DishCard), findsWidgets);

      await tester.tap(find.text('Hải sản'));
      await tester.pumpAndSettle();
      expect(find.byType(DishCard), findsNothing);
      expect(find.text('Chọn một khẩu vị để xem món gợi ý.'), findsOneWidget);
    });

    phoneTest('chip chỉ chọn một: chọn chip khác thì đổi kết quả', (
      tester,
    ) async {
      final repo = FakeDishRepository(dishes: [makeDish('Món A')]);
      await tester.pumpWidget(wrapWithApp(RecommendSection(repository: repo)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cay tê'));
      await tester.pumpAndSettle();
      expect(repo.lastTaste, Taste.spicy);

      await tester.tap(find.text('Cà phê đậm'));
      await tester.pumpAndSettle();
      expect(repo.lastTaste, Taste.coffee);
      expect(
        tester
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .where((c) => c.selected)
            .length,
        1,
      );
    });

    phoneTest('tab Tâm trạng có chip tâm trạng và lọc theo tâm trạng', (
      tester,
    ) async {
      await tester.pumpWidget(wrapWithApp(const RecommendSection()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tâm trạng'));
      await tester.pumpAndSettle();

      for (final chip in [
        'Ấm bụng',
        'Nhẹ nhàng',
        'Tụ tập',
        'Cần năng lượng',
        'Thèm ngọt',
        'Giải nhiệt',
      ]) {
        expect(find.text(chip), findsOneWidget, reason: chip);
      }
      expect(find.text('Cay tê'), findsNothing); // chip khẩu vị đã ẩn
      expect(find.text('Chọn một tâm trạng để xem món gợi ý.'), findsOneWidget);

      await tester.tap(find.text('Thèm ngọt'));
      await tester.pumpAndSettle();
      expect(find.text('Chè bưởi'), findsOneWidget);
    });

    phoneTest('tab Đang hot hiện món hot ngay, không có chip', (tester) async {
      await tester.pumpWidget(wrapWithApp(const RecommendSection()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đang hot'));
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.textContaining('Chọn một'), findsNothing);
      expect(find.text('Phở'), findsOneWidget); // Phở đang hot
      expect(find.text('Bún bò Huế'), findsOneWidget);
    });

    phoneTest('đổi tab giữ lựa chọn của từng tab', (tester) async {
      await tester.pumpWidget(wrapWithApp(const RecommendSection()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chè ngọt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tâm trạng'));
      await tester.pumpAndSettle();
      // Tab Tâm trạng chưa chọn gì nên hiện lời nhắc
      expect(find.text('Chọn một tâm trạng để xem món gợi ý.'), findsOneWidget);

      await tester.tap(find.text('Hợp vị'));
      await tester.pumpAndSettle();
      // Quay lại: chip "Chè ngọt" vẫn đang chọn, kết quả hiện lại
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Chè ngọt'))
            .selected,
        isTrue,
      );
      expect(find.text('Chè bưởi'), findsOneWidget);
    });

    phoneTest('tham số gửi cho repository đúng theo tab và chip', (
      tester,
    ) async {
      final repo = FakeDishRepository(dishes: [makeDish('Món A')]);
      await tester.pumpWidget(wrapWithApp(RecommendSection(repository: repo)));
      await tester.pumpAndSettle();
      expect(repo.calls, 0); // chưa chọn gì thì chưa gọi

      await tester.tap(find.text('Hải sản'));
      await tester.pumpAndSettle();
      expect(repo.lastTaste, Taste.seafood);
      expect(repo.lastMood, isNull);
      expect(repo.lastOnlyTrending, isFalse);

      await tester.tap(find.text('Tâm trạng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giải nhiệt'));
      await tester.pumpAndSettle();
      expect(repo.lastMood, Mood.refreshing);
      expect(repo.lastTaste, isNull);

      await tester.tap(find.text('Đang hot'));
      await tester.pumpAndSettle();
      expect(repo.lastOnlyTrending, isTrue);
      expect(repo.lastTaste, isNull);
      expect(repo.lastMood, isNull);
    });

    phoneTest('tôn trọng buổi ăn trong bộ lọc chung', (tester) async {
      final app = makeAppState()..setMealTime(MealTime.evening);
      await tester.pumpWidget(wrapWithApp(const RecommendSection(), app: app));
      await tester.pumpAndSettle();

      // Cà phê chỉ hợp buổi sáng và xế nên buổi tối thì không có món nào
      await tester.tap(find.text('Cà phê đậm'));
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy món phù hợp.'), findsOneWidget);

      // Đổi buổi ăn trong bộ lọc: danh sách tự tải lại
      app.setMealTime(MealTime.morning);
      await tester.pumpAndSettle();
      expect(find.text('Cà phê'), findsOneWidget);
    });

    phoneTest('đang tải: có vòng xoay', (tester) async {
      final repo = MockDishRepository(
        latency: () => const Duration(milliseconds: 500),
      );
      await tester.pumpWidget(wrapWithApp(RecommendSection(repository: repo)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cay tê'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(DishCard), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(DishCard), findsWidgets);
    });

    phoneTest('rỗng: có câu thông báo', (tester) async {
      final repo = FakeDishRepository(); // luôn trả về rỗng
      await tester.pumpWidget(wrapWithApp(RecommendSection(repository: repo)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hải sản'));
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy món phù hợp.'), findsOneWidget);
    });

    phoneTest('lỗi: có thông báo và nút Thử lại chạy được', (tester) async {
      final repo = FakeDishRepository(fail: true);
      await tester.pumpWidget(wrapWithApp(RecommendSection(repository: repo)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hải sản'));
      await tester.pumpAndSettle();
      expect(
        find.text('Không tải được danh sách món. Kiểm tra mạng rồi thử lại nhé.'),
        findsOneWidget,
      );
      expect(repo.calls, 1);

      repo
        ..fail = false
        ..dishes = [makeDish('Món Thử Lại')];
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(repo.calls, 2);
      expect(find.text('Món Thử Lại'), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
    });

    phoneTest('bấm thẻ món gợi ý mở chi tiết món', (tester) async {
      await tester.pumpWidget(wrapWithApp(const RecommendSection()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cay tê'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bún bò Huế'));
      await tester.pumpAndSettle();
      expect(find.text('Bàn ăn cho món này'), findsOneWidget);
    });

    phoneTest('hiện bằng tiếng Anh khi chọn EN', (tester) async {
      final app = makeAppState()..setLanguage(AppLanguage.en);
      await tester.pumpWidget(wrapWithApp(const RecommendSection(), app: app));
      await tester.pumpAndSettle();

      expect(find.text('Picks for you'), findsOneWidget);
      for (final tab in ['By taste', 'By mood', 'Trending']) {
        expect(find.text(tab), findsOneWidget, reason: tab);
      }
      for (final chip in [
        'Spicy & numbing',
        'Grilled meat',
        'Light & vegetarian',
        'Noodles & broth',
        'Fluffy rice',
        'Seafood',
        'Sweet desserts',
        'Strong coffee',
      ]) {
        expect(find.text(chip), findsOneWidget, reason: chip);
      }
      expect(find.text('Pick a taste to see suggested dishes.'), findsOneWidget);
    });
  });

  group('Gói trọn hương vị ba miền', () {
    phoneTest('có tiêu đề, thẻ Bún chả với vùng và hashtag, nút Khám phá thêm', (
      tester,
    ) async {
      await tester.pumpWidget(wrapWithApp(RegionSection(onMore: () {})));
      await tester.pumpAndSettle();

      expect(find.text('Gói trọn hương vị ba miền'), findsOneWidget);
      expect(
        find.text('Không chỉ là ăn ngon, mà còn là câu chuyện văn hoá.'),
        findsOneWidget,
      );
      expect(find.text('Bún chả'), findsOneWidget);
      expect(find.text('Hà Nội'), findsOneWidget);
      expect(find.text('#HanoiClassic'), findsOneWidget);
      expect(find.text('Khám phá thêm món Việt'), findsOneWidget);
    });

    phoneTest('đủ 4 thẻ theo thứ tự, mỗi thẻ có vùng và hashtag', (tester) async {
      await tester.pumpWidget(wrapWithApp(RegionSection(onMore: () {})));
      await tester.pumpAndSettle();

      final expected = [
        ('Bún chả', 'Hà Nội', '#HanoiClassic'),
        ('Mì Quảng', 'Miền Trung', '#CentralVietnam'),
        ('Ốc', 'Sài Gòn đêm', '#StreetFoodCulture'),
        ('Bánh xèo', 'Hương vị ba miền', '#CrispyPancakes'),
      ];
      final xs = <double>[];
      for (final (name, region, hashtag) in expected) {
        expect(find.text(name), findsOneWidget, reason: name);
        expect(find.text(region), findsOneWidget, reason: region);
        expect(find.text(hashtag), findsOneWidget, reason: hashtag);
        xs.add(tester.getTopLeft(find.text(name)).dx);
      }
      // Từ trái sang phải đúng thứ tự Bắc, Trung, Sài Gòn, ba miền
      expect(xs, [...xs]..sort());
      expect(xs.toSet().length, 4);
    }, size: const Size(1200, 915)); // đủ rộng để thấy cả 4 thẻ cùng lúc

    phoneTest('thẻ vùng bấm được, mở chi tiết món', (tester) async {
      await tester.pumpWidget(wrapWithApp(RegionSection(onMore: () {})));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bún chả'));
      await tester.pumpAndSettle();
      expect(find.text('Bàn ăn cho món này'), findsOneWidget);
      expect(
        find.text(
          'Thịt nướng thơm lừng, bún tươi và bát nước chấm — một nét quen của Hà Nội.',
        ),
        findsOneWidget,
      );
    });

    phoneTest('nút "Khám phá thêm món Việt" gọi onMore', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrapWithApp(RegionSection(onMore: () => taps++)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Khám phá thêm món Việt'));
      expect(taps, 1);
    });

    phoneTest('không có onMore thì không hiện nút', (tester) async {
      await tester.pumpWidget(wrapWithApp(const RegionSection()));
      await tester.pumpAndSettle();
      expect(find.text('Khám phá thêm món Việt'), findsNothing);
    });

    phoneTest('đang tải: có vòng xoay', (tester) async {
      final repo = MockDishRepository(
        latency: () => const Duration(milliseconds: 500),
      );
      await tester.pumpWidget(wrapWithApp(RegionSection(repository: repo)));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    phoneTest('rỗng: có câu thông báo', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(RegionSection(repository: FakeDishRepository())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy món phù hợp.'), findsOneWidget);
    });

    phoneTest('lỗi: có thông báo và nút Thử lại chạy được', (tester) async {
      final repo = FakeDishRepository(fail: true);
      await tester.pumpWidget(wrapWithApp(RegionSection(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Thử lại'), findsOneWidget);
      expect(repo.regionalCalls, 1);

      repo
        ..fail = false
        ..regional = [
          Dish(
            id: 'x',
            name: 'Món Vùng',
            category: 'Ăn vặt',
            description: 'd',
            emoji: '🍲',
            tint: 0xFFEEEEEE,
            region: 'Hà Nội',
            hashtag: '#Test',
          ),
        ];
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(repo.regionalCalls, 2);
      expect(find.text('Món Vùng'), findsOneWidget);
      expect(find.text('#Test'), findsOneWidget);
    });

    phoneTest('hiện bằng tiếng Anh khi chọn EN', (tester) async {
      final app = makeAppState()..setLanguage(AppLanguage.en);
      await tester.pumpWidget(
        wrapWithApp(RegionSection(onMore: () {}), app: app),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flavors of three regions'), findsOneWidget);
      expect(find.text('Hanoi'), findsOneWidget);
      expect(find.text('Discover more Vietnamese dishes'), findsOneWidget);
      expect(find.text('Hà Nội'), findsNothing);
      expect(find.text('#HanoiClassic'), findsOneWidget); // hashtag giữ nguyên
    });
  });

  group('Khám phá: chỉ hiện 8 món đầu và "Xem tất cả"', () {
    // Khung rất cao để dựng hết mọi thứ cùng lúc (cuộn lười sẽ không đếm đủ).
    const tall = Size(412, 4000);

    int dishCards() => find.byType(DishCard).evaluate().length;

    phoneTest('hiện đúng 8 món và nút "Xem tất cả 56 món ngon"', (tester) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();

      expect(dishCards(), dishPreviewCount);
      expect(dishPreviewCount, 8);
      expect(find.text('Xem tất cả 56 món ngon'), findsOneWidget);
    }, size: tall);

    phoneTest('đủ các mục theo thứ tự: chọn món, Xem tất cả, Gợi ý, ba miền', (
      tester,
    ) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();

      double y(String text) => tester.getTopLeft(find.text(text).first).dy;
      final order = [
        y('Chọn món để lên kèo'),
        y('Xem tất cả 56 món ngon'),
        y('Gợi ý cho bạn'),
        y('Gói trọn hương vị ba miền'),
        y('Khám phá thêm món Việt'),
      ];
      expect(order, [...order]..sort());
      expect(order.toSet().length, order.length);
    }, size: tall);

    phoneTest('đổi buổi ăn thì số trong nút đổi theo', (tester) async {
      final app = makeAppState();
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();

      app.setMealTime(MealTime.morning);
      await tester.pumpAndSettle();
      final morning = kMockDishes
          .where((d) => d.mealTimes.contains(MealTime.morning))
          .length;
      expect(morning, greaterThan(dishPreviewCount));
      expect(find.text('Xem tất cả $morning món ngon'), findsOneWidget);
      expect(dishCards(), dishPreviewCount);
    }, size: tall);

    phoneTest('lọc còn ít hơn 8 món thì không có nút', (tester) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'banh xeo');
      await tester.pumpAndSettle();
      expect(find.textContaining('Xem tất cả'), findsNothing);
      expect(find.text('Bánh xèo'), findsWidgets);
    }, size: tall);

    phoneTest('gõ tìm kiếm thì hiện mọi kết quả, không giới hạn 8, không nút', (
      tester,
    ) async {
      final expected = kMockDishes.where((d) => matchesQuery(d.name, 'ch')).length;
      expect(expected, greaterThan(dishPreviewCount)); // đảm bảo bài kiểm tra có ý nghĩa

      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ch');
      await tester.pumpAndSettle();

      expect(dishCards(), expected);
      expect(find.textContaining('Xem tất cả'), findsNothing);

      // Xoá chữ tìm kiếm thì quay lại 8 món và nút
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(dishCards(), dishPreviewCount);
      expect(find.text('Xem tất cả 56 món ngon'), findsOneWidget);
    }, size: tall);

    phoneTest('"Xem tất cả" mở màn Tất cả món ngon có đủ 56 món', (tester) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xem tất cả 56 món ngon'));
      await tester.pumpAndSettle();

      expect(find.text('Tất cả món ngon'), findsOneWidget); // tiêu đề màn
      expect(find.byType(TextField), findsOneWidget); // có ô tìm kiếm
      expect(find.byIcon(Icons.tune), findsOneWidget); // có nút lọc
      expect(find.textContaining('Xem tất cả'), findsNothing); // không còn nút
      expect(dishCards(), 56);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Tất cả món ngon'), findsNothing);
      expect(find.text('Chọn món để lên kèo'), findsOneWidget);
    }, size: const Size(412, 12000));

    phoneTest('màn Tất cả món ngon tìm không dấu và lọc theo buổi ăn', (
      tester,
    ) async {
      final app = makeAppState();
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem tất cả 56 món ngon'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'banh xeo');
      await tester.pumpAndSettle();
      expect(dishCards(), 1);
      expect(find.text('Bánh xèo'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      app.setMealTime(MealTime.lateNight);
      await tester.pumpAndSettle();
      final lateNight = kMockDishes
          .where((d) => d.mealTimes.contains(MealTime.lateNight))
          .length;
      expect(dishCards(), lateNight);
      expect(lateNight, lessThan(56));
    }, size: const Size(412, 12000));

    phoneTest('"Khám phá thêm món Việt" cũng mở màn Tất cả món ngon', (
      tester,
    ) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Khám phá thêm món Việt'));
      await tester.pumpAndSettle();
      expect(find.text('Tất cả món ngon'), findsOneWidget);
    }, size: tall);

    phoneTest('màn Bàn ăn cũng giới hạn 8 món và có nút Xem tất cả', (
      tester,
    ) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bàn ăn'));
      await tester.pumpAndSettle();

      expect(dishCards(), dishPreviewCount);
      expect(find.text('Xem tất cả 56 món ngon'), findsOneWidget);
    }, size: tall);

    phoneTest('nút Xem tất cả bằng tiếng Anh', (tester) async {
      final app = makeAppState()..setLanguage(AppLanguage.en);
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      expect(find.text('See all 56 dishes'), findsOneWidget);
      await tester.tap(find.text('See all 56 dishes'));
      await tester.pumpAndSettle();
      expect(find.text('All dishes'), findsOneWidget);
    }, size: tall);

    phoneTest('bấm thẻ vùng trên trang Khám phá mở chi tiết món', (tester) async {
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('#HanoiClassic'));
      await tester.pumpAndSettle();
      expect(find.text('Bàn ăn cho món này'), findsOneWidget);
    }, size: tall);
  });

  // Kiểm tra không tràn dòng (flutter test báo lỗi nếu có RenderFlex overflow)
  // ở cả hai ngôn ngữ, khổ máy nhỏ và cỡ chữ hệ thống lớn.
  group('không tràn dòng', () {
    for (final lang in AppLanguage.values) {
      for (final scale in [1.0, 1.3]) {
        for (final width in [360.0, 412.0]) {
          phoneTest(
            'Khám phá ${lang.name}, chữ x$scale, rộng ${width.toInt()}',
            (tester) async {
              tester.platformDispatcher.textScaleFactorTestValue = scale;
              addTearDown(tester.platformDispatcher.clearAllTestValues);

              final app = makeAppState()..setLanguage(lang);
              await tester.pumpWidget(MyApp(appState: app));
              await tester.pumpAndSettle();

              // Mở từng tab và chip để bố cục các trạng thái đều được dựng
              final t = app.strings;
              for (final key in [StrKey.tabMood, StrKey.tabHot, StrKey.tabTaste]) {
                await tester.tap(find.text(t(key)));
                await tester.pumpAndSettle();
              }
              await tester.tap(find.text(t.tasteLabel(Taste.noodleSoup)));
              await tester.pumpAndSettle();

              // Mở bảng lọc rồi đóng lại
              await tester.tap(find.byIcon(Icons.tune));
              await tester.pumpAndSettle();
              await tester.tap(find.text(t.mealTimeLabel(MealTime.lateNight)));
              await tester.pumpAndSettle();
            },
            size: Size(width, 3600),
          );
        }
      }
    }
  });
}
