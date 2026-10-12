import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/dish_descriptions_en.dart';
import 'package:giua_ki_app/data/mock_dishes.dart';
import 'package:giua_ki_app/data/models/dish.dart';
import 'package:giua_ki_app/data/models/enums.dart';
import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/ui/screens/dish_detail_screen.dart';

import 'test_helpers.dart';

// Các từ/cụm tiếng Việt được GIỮ NGUYÊN CÓ CHỦ Ý trong mô tả tiếng Anh (tên riêng của món,
// nguyên liệu hoặc nước chấm đặc trưng, thường kèm giải thích ngắn). Cụm khác có dấu tiếng
// Việt xuất hiện trong mô tả EN thì test báo lỗi.
const allowedVietnamese = <String>[
  'Huế',
  'Hội An',
  'bún bò Huế',
  'bún lá',
  'bún',
  'hủ tiếu',
  'bánh mì',
  'bánh tráng',
  'bánh bèo',
  'chả cơm',
  'chả',
  'mắm tôm',
  'thịt xíu',
  'đồ chua',
  'tương ớt',
  'tương xí muội',
  'tôm chấy',
  'mỡ hành',
  'nước mắm',
  'nước cốt dừa',
  'lạp xưởng',
  'chà bông',
  'quẩy',
  'lá é',
  'trà đá',
  'rau răm',
  'nem chua',
  'nếp cẩm',
  'tép khô',
  'quất',
  'pâté', // từ mượn tiếng Pháp
];

// Chữ cái chỉ có trong tiếng Việt (hoặc có dấu), dùng để phát hiện chữ Việt còn sót.
final _accented = RegExp(
  r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]',
  caseSensitive: false,
);

// Bỏ các từ ngoại lệ (cụm dài trước) rồi trả về phần còn lại.
String stripAllowed(String text) {
  var out = text;
  final sorted = [...allowedVietnamese]
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final w in sorted) {
    out = out.replaceAll(RegExp(RegExp.escape(w), caseSensitive: false), ' ');
  }
  return out;
}

void main() {
  group('dữ liệu mô tả tiếng Anh', () {
    test('có đủ 56 món, mỗi món đều có mô tả EN', () {
      expect(kMockDishes.length, 56);
      for (final d in kMockDishes) {
        final en = d.descriptionEn;
        expect(en, isNotNull, reason: '${d.id} thiếu mô tả EN');
        expect(en!.trim(), isNotEmpty, reason: d.id);
      }
    });

    test('bảng EN không có id thừa (mỗi khoá là một món có thật)', () {
      final ids = kMockDishes.map((d) => d.id).toSet();
      final extra = kDishDescriptionsEn.keys.where((k) => !ids.contains(k));
      expect(extra, isEmpty);
    });

    test('mô tả EN khác nguyên văn bản tiếng Việt', () {
      for (final d in kMockDishes) {
        expect(d.descriptionEn, isNot(d.description), reason: d.id);
      }
    });

    test('không còn chữ tiếng Việt có dấu trong mô tả EN (trừ các từ giữ nguyên có chủ đích)', () {
      final leftovers = <String>[];
      for (final d in kMockDishes) {
        final rest = stripAllowed(d.descriptionEn!);
        final m = _accented.allMatches(rest).map((x) => x.group(0)).toSet();
        if (m.isNotEmpty) leftovers.add('${d.id}: ${m.join()} trong "$rest"');
      }
      expect(leftovers, isEmpty, reason: leftovers.join('\n'));
    });

    test('các từ ngoại lệ đều thực sự được dùng (danh sách không thừa)', () {
      final all = kMockDishes
          .map((d) => d.descriptionEn!.toLowerCase())
          .join(' ');
      final unused = [
        for (final w in allowedVietnamese)
          if (!all.contains(w.toLowerCase())) w,
      ];
      expect(unused, isEmpty, reason: 'Từ ngoại lệ không dùng: $unused');
    });

    test('tên món giữ nguyên tiếng Việt (không bị dịch)', () {
      final byId = {for (final d in kMockDishes) d.id: d.name};
      expect(byId['pho'], 'Phở');
      expect(byId['bun-cha'], 'Bún chả');
      expect(byId['cao-lau'], 'Cao lầu');
      for (final d in kMockDishes) {
        expect(
          d.descriptionEn!.toLowerCase(),
          isNot(contains('noodle soup')),
          reason: d.id,
        ); // tránh thay tên món bằng từ dịch trong mô tả
      }
    });

    test('mô tả EN không có ký tự lạ hay khoảng trắng thừa hai đầu', () {
      for (final d in kMockDishes) {
        final en = d.descriptionEn!;
        expect(en, en.trim(), reason: d.id);
        expect(en.contains(r'$'), isFalse, reason: d.id);
        expect(en.contains('  '), isFalse, reason: d.id);
      }
    });
  });

  group('Dish.descriptionFor', () {
    const base = Dish(
      id: 'x',
      name: 'Món X',
      category: 'Bún & mì',
      description: 'Mô tả tiếng Việt',
      emoji: '🍜',
      tint: 0xFFEEEEEE,
    );

    test('VI luôn dùng mô tả tiếng Việt', () {
      expect(base.descriptionFor(AppLanguage.vi), 'Mô tả tiếng Việt');
    });

    test('EN dùng bản dịch nếu có', () {
      const d = Dish(
        id: 'x',
        name: 'Món X',
        category: 'Bún & mì',
        description: 'Mô tả tiếng Việt',
        emoji: '🍜',
        tint: 0xFFEEEEEE,
        descriptionEn: 'English text',
      );
      expect(d.descriptionFor(AppLanguage.en), 'English text');
      expect(d.descriptionFor(AppLanguage.vi), 'Mô tả tiếng Việt');
    });

    test('EN thiếu hoặc rỗng thì dự phòng về tiếng Việt', () {
      expect(base.descriptionFor(AppLanguage.en), 'Mô tả tiếng Việt');
      const empty = Dish(
        id: 'x',
        name: 'Món X',
        category: 'Bún & mì',
        description: 'Mô tả tiếng Việt',
        emoji: '🍜',
        tint: 0xFFEEEEEE,
        descriptionEn: '',
      );
      expect(empty.descriptionFor(AppLanguage.en), 'Mô tả tiếng Việt');
    });
  });

  group('giao diện theo ngôn ngữ', () {
    final pho = kMockDishes.firstWhere((d) => d.id == 'pho');

    phoneTest('Khám phá: thẻ món hiện mô tả EN khi chọn EN, VI khi chọn VI', (
      tester,
    ) async {
      final app = makeAppState();
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      expect(find.text(pho.description), findsOneWidget);
      expect(find.text(pho.descriptionEn!), findsNothing);

      app.setLanguage(AppLanguage.en);
      await tester.pumpAndSettle();
      expect(find.text(pho.descriptionEn!), findsOneWidget);
      expect(find.text(pho.description), findsNothing);
      expect(find.text('Phở'), findsOneWidget); // tên món giữ tiếng Việt
    }, size: const Size(412, 915));

    phoneTest(
      'Chi tiết món: mô tả EN, tên món vẫn tiếng Việt, đổi ngôn ngữ tại chỗ',
      (tester) async {
        final app = makeAppState();
        await tester.pumpWidget(MyApp(appState: app));
        await tester.pumpAndSettle();
        openDishDetail(tester.element(find.byType(Scaffold).first), pho);
        await tester.pumpAndSettle();
        expect(find.text(pho.description), findsOneWidget);

        app.setLanguage(AppLanguage.en);
        await tester.pumpAndSettle();
        expect(find.text(pho.descriptionEn!), findsOneWidget);
        expect(find.text('Phở'), findsWidgets);
      },
      size: const Size(412, 915),
    );

    phoneTest('Lắc món: kết quả hiện mô tả theo ngôn ngữ', (tester) async {
      // Random cố định để biết trước món ra
      final app = makeAppState(random: _FirstRandom())
        ..setLanguage(AppLanguage.en);
      final all = (await tester.runAsync(
        () => app.dishRepository.getDishes(),
      ))!;
      await tester.pumpWidget(MyApp(appState: app));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Spin for a dish').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spin now!'));
      await tester.pumpAndSettle();
      expect(find.text(all.first.descriptionEn!), findsWidgets);
    }, size: const Size(412, 915));

    for (final width in [360.0, 412.0]) {
      phoneTest(
        'Chi tiết món EN không tràn dòng, rộng ${width.toInt()}, chữ phóng 1,3',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          final app = makeAppState()..setLanguage(AppLanguage.en);
          await tester.pumpWidget(MyApp(appState: app));
          await tester.pumpAndSettle();
          // Mô tả dài nhất để thử tràn dòng
          final longest =
              ([...kMockDishes]..sort(
                    (a, b) => b.descriptionEn!.length.compareTo(
                      a.descriptionEn!.length,
                    ),
                  ))
                  .first;
          openDishDetail(tester.element(find.byType(Scaffold).first), longest);
          await tester.pumpAndSettle();
          expect(find.text(longest.descriptionEn!), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
        size: Size(width, 915),
      );
    }
  });
}

// Random luôn chọn phần tử đầu tiên.
class _FirstRandom implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}
