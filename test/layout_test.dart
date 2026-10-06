import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/main.dart';

import 'test_helpers.dart';

// Cỡ chữ tiêu đề theo ảnh thiết kế: "Hồ sơ của bạn" (lich-hen.jpg, toi.jpg) lớn hơn
// các tiêu đề màn khác (kham-pha.jpg, ban-an.jpg).
void main() {
  double titleSize(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.fontSize!;

  phoneTest('tiêu đề "Hồ sơ của bạn" 35, to hơn "Chọn món để lên kèo" 28', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(appState: makeAppState()));
    await tester.pumpAndSettle();
    expect(titleSize(tester, 'Chọn món để lên kèo'), 28);
    await tester.tap(find.text('Lịch hẹn').last);
    await tester.pumpAndSettle();
    expect(titleSize(tester, 'Hồ sơ của bạn'), 35);
    expect(
      titleSize(tester, 'Hồ sơ của bạn'),
      greaterThan(titleSize(tester, 'Bàn ăn của bạn')),
    );
  });

  for (final width in [360.0, 412.0]) {
    phoneTest('Hồ sơ không tràn ở chữ phóng 1,3, rộng ${width.toInt()}', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.pumpWidget(MyApp(appState: makeAppState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tôi').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }, size: Size(width, 915));
  }
}
