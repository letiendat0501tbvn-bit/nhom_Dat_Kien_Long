import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giua_ki_app/main.dart';
import 'package:giua_ki_app/ui/screens/profile_screen.dart';

void main() {
  testWidgets('Bottom bar switches tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Bàn ăn'));
    await tester.pump();
    expect(find.text('Bàn còn chỗ'), findsOneWidget);
    expect(find.text('Chọn khu vực'), findsNWidgets(2)); // tiêu đề + nút
    expect(find.text('Phở'), findsOneWidget); // dùng lại khối chọn món

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Tạo bàn mới'), findsWidgets);
  });

  testWidgets('Lịch hẹn and Tôi open the right profile tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Lịch hẹn'));
    await tester.pump();
    expect(find.text('Hồ sơ của bạn'), findsOneWidget);
    expect(find.text('Đăng nhập để xem những bàn ăn của bạn.'), findsOneWidget);

    await tester.tap(find.text('Tôi'));
    await tester.pump();
    expect(find.text('Khách ghé chơi'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);

    // Chuyển tab trong màn Hồ sơ
    await tester.tap(find.text('Bàn của tôi'));
    await tester.pump();
    expect(find.text('Bàn ăn của bạn'), findsOneWidget);
    expect(find.text('Khách ghé chơi'), findsNothing);
  });

  testWidgets('Lịch hẹn and Tôi share one profile screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Lịch hẹn'));
    await tester.pump();
    final first = tester.state(find.byType(ProfileScreen));

    await tester.tap(find.text('Tôi'));
    await tester.pump();
    // Cùng một State: không dựng lại màn hình khi đổi giữa hai tab
    expect(tester.state(find.byType(ProfileScreen)), same(first));
  });

  testWidgets('Explore shows dishes and filters by search',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Chọn món để lên kèo'), findsOneWidget);
    expect(find.text('Phở'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();
    expect(find.text('Phở'), findsNothing);
    expect(find.text('Không tìm thấy món phù hợp.'), findsOneWidget);
  });
}
