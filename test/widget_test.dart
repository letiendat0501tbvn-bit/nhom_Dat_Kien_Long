import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_module_1/main.dart';

void main() {
  testWidgets('Food app shows menu and updates cart', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Đặt đồ ăn'), findsOneWidget);
    expect(find.text('Bún bò Huế'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add-food-bun-bo')));
    await tester.pump();

    expect(find.text('1 món'), findsOneWidget);
    expect(find.text('59000₫'), findsNWidgets(2));
  });
}
