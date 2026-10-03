import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/data/models/dish.dart';
import 'package:giua_ki_app/ui/components/dish_image.dart';

const pho = Dish(
  id: 'pho',
  name: 'Phở',
  category: 'Bún & mì',
  description: 'mô tả',
  emoji: '🍜',
  tint: 0xFFEADFCB,
);

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('ảnh đứng một mình có nhãn ngữ nghĩa là tên món, không đọc emoji', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const DishImage(dish: pho)));

    expect(find.bySemanticsLabel('Phở'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('🍜')), findsNothing);
    handle.dispose();
  });

  testWidgets('excludeFromSemantics: ảnh không có nhãn nào (tránh đọc lặp tên)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const DishImage(dish: pho, excludeFromSemantics: true)),
    );

    expect(find.bySemanticsLabel('Phở'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('🍜')), findsNothing);
    handle.dispose();
  });

  testWidgets('vẫn hiện emoji và nền màu của món', (tester) async {
    await tester.pumpWidget(host(const DishImage(dish: pho)));
    expect(find.text('🍜'), findsOneWidget);
    final box = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(DishImage),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(box.color, const Color(0xFFEADFCB));
  });

  testWidgets('overlay được vẽ chồng lên ảnh', (tester) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 200,
          child: DishImage(
            dish: pho,
            overlay: Positioned(top: 8, left: 8, child: ImageLabel('Nhãn')),
          ),
        ),
      ),
    );
    expect(find.text('Nhãn'), findsOneWidget);
  });

  testWidgets('giữ đúng tỉ lệ khung ảnh', (tester) async {
    await tester.pumpWidget(
      host(
        const Center(
          child: SizedBox(
            width: 200,
            child: DishImage(dish: pho, aspectRatio: 2),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(DishImage)), const Size(200, 100));
  });
}
